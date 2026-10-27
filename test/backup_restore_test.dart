import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/random_tools/roll_call.dart';

import 'support/semester_fixture.dart';
import 'support/backup_fixture.dart';
import 'support/recording_notifications.dart';

import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/random_tools/tool_library.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  test('恢复开始后旧点名与抽签完成请求即使与事务并发也不能写入新轮次', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(
      store,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    await seedBackupFixture(planner);
    final before = await planner.exportBackup();
    final preview = await planner.previewBackup(before);
    final roll = await planner.prepareRollCall(
      (await planner.loadRollCallLists()).single.id,
    );
    final lottery = await planner.prepareLottery(
      (await planner.loadLotteryPools()).single.id,
    );
    final restore = preview.restore(confirmOverwrite: true);
    final rollCheck = expectLater(
      Future.sync(roll.complete),
      throwsA(isA<StateError>()),
    );
    final lotteryCheck = expectLater(
      Future.sync(lottery.complete),
      throwsA(isA<StateError>()),
    );
    await restore;
    await Future.wait([rollCheck, lotteryCheck]);
    expect(await planner.exportBackup(), before);
  });

  test('全部领域数据、设置及工具状态精确往返，恢复替换旧数据并仅重建未来提醒', () async {
    final source = PlannerStore(NativeDatabase.memory());
    final target = PlannerStore(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);
    DateTime clock() => DateTime.utc(2026, 8, 30);
    final planner = SemesterPlanner(source, clock: clock);
    await seedBackupFixture(planner);
    final bytes = await planner.exportBackup();
    final notifications = RecordingNotifications();
    final restored = SemesterPlanner(
      target,
      notifications: notifications,
      clock: clock,
    );
    await restored.saveSemester(semesterDraft('将被替换'));
    final before = await restored.exportBackup();
    final preview = await restored.previewBackup(bytes);
    expect(await restored.exportBackup(), before);
    await preview.restore(confirmOverwrite: false);
    expect(await restored.exportBackup(), before);
    await preview.restore(confirmOverwrite: true);
    expect(await restored.exportBackup(), bytes);
    final state = await restored.load();
    expect(state.classExceptions, hasLength(2));
    expect(state.independentLessons.single.location, '补课教室');
    expect(state.tasks.first.courseId, state.courses.single.id);
    expect(state.tasks.last.isCompleted, isTrue);
    expect(
      (await restored.loadToolLibrary()).tools(filter: ToolFilter.favorites),
      [RandomTool.lottery],
    );
    expect(
      (await restored.loadToolLibrary()).tools(filter: ToolFilter.recent),
      [RandomTool.rollCall, RandomTool.wheel],
    );
    expect(notifications.pending, isNotEmpty);
    expect(notifications.pending.every((r) => r.at.isAfter(clock())), isTrue);
    expect(notifications.scopes['ddl']!.map((r) => r.title), ['关联数学作业']);
    expect(notifications.scopes['event']!.map((r) => r.title), ['未来考试']);
    expect(notifications.scopes['course'], hasLength(3));
    notifications.access = NotificationAccess.blocked;
    await preview.restore(confirmOverwrite: true);
    expect(restored.notificationAccess, NotificationAccess.blocked);
    expect(notifications.pending, isEmpty);
  });

  test('无效版本、缺字段、断开关系、非法日期或轮次均拒绝且不改变当前数据', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(
      store,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    await seedBackupFixture(planner);
    final original = await planner.exportBackup();
    final mutations = <void Function(Map<String, dynamic>)>[
      (a) => a['schema'] = 999,
      (a) => (a['tables'] as Map).remove('tool_usage_records'),
      (a) => a['tables']['settings_records'][0]['campus_time_zone'] =
          'Invalid/Zone',
      (a) => a['tables']['learning_task_records'][0]['course_id'] = 99999,
      (a) => a['tables']['learning_task_records'][0]['due_date'] =
          '2026-02-30T00:00:00.000Z',
      (a) => a['tables']['roll_call_list_records'][0]['drawn'] = '[999]',
      (a) => a['tables']['lottery_pool_records'][0]['drawn'] = '[0,0]',
      (a) => a['tables']['period_records'][0]['number'] = 99,
      (a) => a['tables']['learning_task_records'][0]['is_completed'] = 2,
      (a) => a['tables']['settings_records'] = [],
      (a) => a['tables']['course_records'][0]['name'] = '',
      (a) => a['tables']['group_list_records'][0]['members'] =
          '[{"id":1,"name":"A","detail":""},{"id":1,"name":"B","detail":""}]',
    ];
    for (final mutate in mutations) {
      final data = jsonDecode(utf8.decode(original)) as Map<String, dynamic>;
      mutate(data);
      await expectLater(
        planner.previewBackup(
          Uint8List.fromList(utf8.encode(jsonEncode(data))),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await planner.exportBackup(), original);
    }
    await expectLater(
      planner.previewBackup(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
    expect(await planner.exportBackup(), original);
  });

  test('确认后真实 SQLite 中途写入失败完整回滚，旧抽取句柄不能污染恢复后的轮次', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(
      store,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    await seedBackupFixture(planner);
    final bytes = await planner.exportBackup();
    final preview = await planner.previewBackup(bytes);
    final pending = await planner.prepareRollCall(
      (await planner.loadRollCallLists()).single.id,
    );
    await planner.saveSemester(semesterDraft('当前新学期'));
    final before = await planner.exportBackup();
    await store.customStatement(
      "CREATE TRIGGER fail_restore BEFORE INSERT ON learning_task_records BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    await expectLater(
      preview.restore(confirmOverwrite: true),
      throwsA(anything),
    );
    expect(await planner.exportBackup(), before);
    await store.customStatement('DROP TRIGGER fail_restore');
    await preview.restore(confirmOverwrite: true);
    await expectLater(
      Future.sync(pending.complete),
      throwsA(isA<StateError>()),
    );
    expect(await planner.exportBackup(), bytes);
    final next = await planner.prepareRollCall(
      (await planner.loadRollCallLists()).single.id,
    );
    await next.complete();
    expect((await planner.loadRollCallLists()).single.drawn, hasLength(2));
  });

  test('完整备份可在干净数据库覆盖恢复，未完成轮次重启后继续', () async {
    final source = PlannerStore(NativeDatabase.memory());
    addTearDown(source.close);
    final planner = SemesterPlanner(source);
    await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveSemester(semesterDraft('历史学期'));
    final list = await planner.saveRollCallList(
      name: '同名名单',
      members: [
        const RollCallMember(id: 1, name: '小林', detail: '001'),
        const RollCallMember(id: 2, name: '小林', detail: '002'),
      ],
    );
    await (await planner.prepareRollCall(list.id)).complete();
    final bytes = await planner.exportBackup();
    final dir = await Directory.systemTemp.createTemp('unipocket_backup_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/restored.sqlite');
    var target = PlannerStore(NativeDatabase(file));
    var restored = SemesterPlanner(target);
    final preview = await restored.previewBackup(bytes);
    expect((await restored.load()).semesters, isEmpty);
    await preview.restore(confirmOverwrite: true);
    await target.close();
    target = PlannerStore(NativeDatabase(file));
    addTearDown(target.close);
    restored = SemesterPlanner(target);
    expect((await restored.load()).semesters.map((s) => s.name), [
      '历史学期',
      '秋季',
    ]);
    final round = (await restored.loadRollCallLists()).single;
    expect(round.drawn, hasLength(1));
    expect(round.candidates, hasLength(1));
    final next = await restored.prepareRollCall(round.id);
    expect(next.member.id, isNot(round.drawn.single));
    expect((await next.complete()).candidates, isEmpty);
  });
}
