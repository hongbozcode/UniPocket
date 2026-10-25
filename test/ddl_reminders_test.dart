import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/semesters/model.dart';

import 'support/recording_notifications.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('编辑、完成、撤销、关闭和删除只保留当前未来提醒；到期不补发', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    var now = DateTime.utc(2026, 10, 25);
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => now,
    );
    final id = await planner.saveTask(
      LearningTaskDraft(
        title: '实验报告',
        dueDate: DateTime(2026, 10, 28),
        dueMinutes: 600,
      ),
    );
    await planner.saveTask(
      LearningTaskDraft(
        title: '实验报告终稿',
        dueDate: DateTime(2026, 10, 29),
        dueMinutes: 600,
        reminderMinutesBefore: 30,
      ),
      id: id,
    );
    expect(notifications.pending.single.at, DateTime.utc(2026, 10, 29, 1, 30));
    expect(notifications.pending.single.title, '实验报告终稿');
    await planner.setTaskCompleted(id, true);
    expect(notifications.pending, isEmpty);
    await planner.setTaskCompleted(id, false);
    expect(notifications.pending, hasLength(1));
    await planner.saveTask(
      LearningTaskDraft(
        title: '实验报告终稿',
        dueDate: DateTime(2026, 10, 29),
        reminderMinutesBefore: null,
      ),
      id: id,
    );
    expect(notifications.pending, isEmpty);
    expect((await planner.load()).tasks.single.reminderMinutesBefore, isNull);
    await planner.saveTask(
      LearningTaskDraft(
        title: '实验报告终稿',
        dueDate: DateTime(2026, 10, 29),
        dueMinutes: 600,
      ),
      id: id,
    );
    now = DateTime.utc(2026, 10, 28, 2);
    await planner.refreshReminders();
    expect(notifications.pending, isEmpty);
    expect(
      planner.taskReminderStatus(
        (await planner.load()).tasks.single,
        'Asia/Shanghai',
      ),
      '提醒时间已过，不会补发',
    );
    await planner.setTaskCompleted(id, true);
    await planner.setTaskCompleted(id, false);
    expect(notifications.pending, isEmpty);
    await planner.deleteTask(id);
    expect((await planner.load()).tasks, isEmpty);
    expect(notifications.pending, isEmpty);
  });

  test('通知禁用与调度失败不阻断数据保存，恢复权限后只重建未来提醒', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications()
      ..access = NotificationAccess.blocked;
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final id = await planner.saveTask(
      LearningTaskDraft(title: '未来任务', dueDate: DateTime(2026, 10, 28)),
    );
    expect((await planner.load()).tasks.single.id, id);
    expect(notifications.pending, isEmpty);
    expect(planner.notificationAccess, NotificationAccess.blocked);
    notifications.access = NotificationAccess.enabled;
    notifications.fail = true;
    await planner.saveTask(
      LearningTaskDraft(title: '仍然保存', dueDate: DateTime(2026, 10, 29)),
      id: id,
    );
    expect((await planner.load()).tasks.single.title, '仍然保存');
    expect(planner.reminderSyncFailed, isTrue);
    notifications.fail = false;
    await planner.refreshReminders();
    expect(notifications.pending.single.title, '仍然保存');
    await expectLater(
      planner.saveTask(
        LearningTaskDraft(
          title: '非法',
          dueDate: DateTime(2026, 10, 29),
          reminderMinutesBefore: -1,
        ),
        id: id,
      ),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).tasks.single.title, '仍然保存');
  });

  test('旧版数据库升级保留学习数据和完成状态，时区变更重算提醒时刻', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
        },
      ),
    );
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 1),
    );
    final state = await planner.load();
    expect(state.tasks, isNotEmpty);
    expect(state.tasks.every((t) => t.reminderMinutesBefore == 1440), isTrue);
    final id = await planner.saveTask(
      LearningTaskDraft(
        title: '跨区',
        dueDate: DateTime(2026, 11, 1),
        dueMinutes: 600,
      ),
    );
    await planner.setCampusTimeZone('America/New_York');
    expect(
      notifications.pending.singleWhere((r) => r.key == 'task:$id').at,
      DateTime.utc(2026, 10, 31, 15),
    );
    expect((await planner.load()).courses, isNotEmpty);
  });

  test('保存独立 DDL 默认提前一天安排一次提醒，数据库重开仍保留配置与任务身份', () async {
    final directory = await Directory.systemTemp.createTemp('ddl_reminders_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/planner.sqlite');
    final notifications = RecordingNotifications();
    var store = PlannerStore(NativeDatabase(file));
    var planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final id = await planner.saveTask(
      LearningTaskDraft(title: '论文终稿', dueDate: DateTime(2026, 10, 28)),
    );
    expect(notifications.pending.single.key, 'task:$id');
    expect(notifications.pending.single.at, DateTime.utc(2026, 10, 27, 15, 59));
    expect(notifications.pending.single.title, '论文终稿');
    expect(notifications.pending.single.body, '10月28日 23:59 截止，记得按时完成。');
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    addTearDown(store.close);
    planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final task = (await planner.load()).tasks.single;
    expect(task.id, id);
    expect(task.reminderMinutesBefore, 1440);
    await planner.refreshReminders();
    expect(notifications.pending, hasLength(1));
  });
}
