import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/events/model.dart';
import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/recording_notifications.dart';
import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('倒计时默认在当天校园时间上午九点提醒，重开数据库保留事件身份', () async {
    final directory = await Directory.systemTemp.createTemp('event_reminders_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/planner.sqlite');
    final notifications = RecordingNotifications();
    var store = PlannerStore(NativeDatabase(file));
    addTearDown(() => store.close());
    var planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final id = await planner.saveEvent(
      CountdownEventDraft(title: '期末考试', targetDate: DateTime(2026, 11, 6)),
    );
    expect(notifications.pending, hasLength(1));
    expect(notifications.pending.single.key, 'event:$id');
    expect(notifications.pending.single.at, DateTime.utc(2026, 11, 6, 1));
    expect(notifications.pending.single.body, '今天是11月6日，记得关注这项安排。');
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    expect((await planner.load()).events.single.id, id);
    await planner.refreshReminders();
    expect(notifications.pending, hasLength(1));
  });

  test('编辑日期时间标题替换原提醒，关闭删除及到点不补发', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    var now = DateTime.utc(2026, 10, 25);
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => now,
    );
    final id = await planner.saveEvent(
      CountdownEventDraft(title: '考试', targetDate: DateTime(2026, 11, 6)),
    );
    await planner.saveEvent(
      CountdownEventDraft(
        title: '考试改期',
        targetDate: DateTime(2026, 11, 7),
        reminderMinutes: 630,
      ),
      id: id,
    );
    expect(notifications.pending.single.key, 'event:$id');
    expect(notifications.pending.single.at, DateTime.utc(2026, 11, 7, 2, 30));
    expect(notifications.pending.single.title, '考试改期');
    await planner.setEventPinned(id, true);
    expect((await planner.load()).events.single.reminderMinutes, 630);
    await planner.saveEvent(
      CountdownEventDraft(
        title: '考试改期',
        targetDate: DateTime(2026, 11, 7),
        reminderMinutes: null,
      ),
      id: id,
    );
    expect(notifications.pending, isEmpty);
    expect((await planner.load()).events.single.reminderMinutes, isNull);
    for (final invalid in [-1, 1440]) {
      await expectLater(
        planner.saveEvent(
          CountdownEventDraft(
            title: '非法',
            targetDate: DateTime(2026, 11, 7),
            reminderMinutes: invalid,
          ),
          id: id,
        ),
        throwsA(isA<InputProblem>()),
      );
    }
    expect((await planner.load()).events.single.title, '考试改期');
    await planner.saveEvent(
      CountdownEventDraft(title: '考试', targetDate: DateTime(2026, 11, 7)),
      id: id,
    );
    now = DateTime.utc(2026, 11, 7, 1);
    await planner.refreshReminders();
    expect(notifications.pending, isEmpty);
    expect(
      planner.eventReminderStatus(
        (await planner.load()).events.single,
        'Asia/Shanghai',
      ),
      '提醒时间已过，不会补发',
    );
    await planner.saveEvent(
      CountdownEventDraft(title: '历史事件', targetDate: DateTime(2026, 10, 1)),
      id: id,
    );
    expect(notifications.pending, isEmpty);
    await planner.saveEvent(
      CountdownEventDraft(title: '新日期', targetDate: DateTime(2026, 11, 8)),
      id: id,
    );
    expect(notifications.pending, hasLength(1));
    await planner.deleteEvent(id);
    expect(notifications.pending, isEmpty);
    expect((await planner.load()).events, isEmpty);
  });

  test('切换或创建当前学期保留任务与事件提醒，只替换有效课程', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final first = await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveCourse(
      CourseDraft(
        semesterId: first,
        name: '高数',
        schedules: [
          ScheduleDraft(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 1,
            location: 'A101',
            weeks: {10},
          ),
        ],
      ),
    );
    await planner.saveTask(
      LearningTaskDraft(title: '独立报告', dueDate: DateTime(2026, 11, 6)),
    );
    final id = await planner.saveEvent(
      CountdownEventDraft(title: '跨学期考试', targetDate: DateTime(2026, 11, 7)),
    );
    expect(notifications.scopes['course'], hasLength(1));
    final retained = notifications.pending
        .where((r) => !r.key.startsWith('class:'))
        .map((r) => (r.key, r.at))
        .toSet();
    final next = await planner.saveSemester(
      semesterDraft('春季'),
      makeCurrent: true,
    );
    expect(notifications.scopes['course'], isEmpty);
    expect(notifications.pending.map((r) => (r.key, r.at)).toSet(), retained);
    await planner.setCurrentSemester(first);
    expect(notifications.scopes['course'], hasLength(1));
    await planner.setCurrentSemester(next);
    expect(notifications.pending.map((r) => (r.key, r.at)).toSet(), retained);
    notifications.failScope = 'ddl';
    await planner.deleteEvent(id);
    expect(notifications.scopes['event'], isEmpty);
    expect(planner.reminderSyncFailed, isTrue);
  });

  test('通知关闭及失败不阻断保存，重试按新数据重建，纽约夏令时结束日按校园时间', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications()
      ..access = NotificationAccess.blocked;
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final id = await planner.saveEvent(
      CountdownEventDraft(title: '考试', targetDate: DateTime(2026, 11, 1)),
    );
    expect((await planner.load()).events.single.reminderMinutes, 540);
    expect(notifications.pending, isEmpty);
    notifications.access = NotificationAccess.enabled;
    notifications.failScope = 'event';
    await planner.saveEvent(
      CountdownEventDraft(title: '新版考试', targetDate: DateTime(2026, 11, 1)),
      id: id,
    );
    expect((await planner.load()).events.single.title, '新版考试');
    expect(planner.reminderSyncFailed, isTrue);
    notifications.failScope = null;
    await planner.refreshReminders();
    expect(notifications.pending.single.title, '新版考试');
    await planner.setCampusTimeZone('America/New_York');
    expect(notifications.pending.single.at, DateTime.utc(2026, 11, 1, 14));
    expect(planner.reminderSyncFailed, isFalse);
    notifications.access = NotificationAccess.blocked;
    await planner.refreshReminders();
    expect(notifications.pending, isEmpty);
  });

  test('升级旧数据库保留事件标题日期类型和置顶，自动提供当天九点提醒', () async {
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
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final state = await planner.load();
    expect(state.events.single.title, '期中考试');
    expect(state.events.single.targetDate, DateTime.utc(2026, 11, 6));
    expect(state.events.single.isPinned, isTrue);
    expect(state.events.single.kind, EventKind.exam);
    expect(state.events.single.reminderMinutes, 540);
    expect(state.tasks.single.isCompleted, isTrue);
    expect(state.classExceptions, hasLength(2));
    await planner.refreshReminders();
    expect(notifications.scopes['event']!.single.at, DateTime.utc(2026, 11, 6));
  });
}
