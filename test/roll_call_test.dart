import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/roll_call.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/candidate_random.dart';

void main() {
  test('重复模式完整候选、修改和重置使旧抽取失效，非法名单不破坏数据', () async {
    final store = PlannerStore(NativeDatabase.memory());
    final planner = SemesterPlanner(store);
    try {
      final list = await planner.saveRollCallList(
        name: '名单',
        members: [
          const RollCallMember(id: 1, name: '甲'),
          const RollCallMember(id: 2, name: '乙'),
        ],
      );
      await planner.resetRollCall(list.id, repeat: true);
      for (var i = 0; i < 3; i++) {
        final draw = await planner.prepareRollCall(
          list.id,
          random: CandidateRandom([1], 2),
        );
        await draw.complete();
      }
      var saved = (await planner.loadRollCallLists()).single;
      expect(saved.drawn, [2, 2, 2]);
      expect(saved.candidates.map((m) => m.id), [1, 2]);
      final stale = await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([0], 2),
      );
      await planner.resetRollCall(list.id, repeat: false);
      await expectLater(stale.complete(), throwsStateError);
      final editing = await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([1], 2),
      );
      await planner.saveRollCallList(
        id: list.id,
        name: '修改后',
        members: [const RollCallMember(id: 1, name: '甲')],
      );
      await expectLater(editing.complete(), throwsStateError);
      expect(
        () => planner.saveRollCallList(
          id: list.id,
          name: '非法',
          members: [
            const RollCallMember(id: 1, name: '甲'),
            const RollCallMember(id: 1, name: '乙'),
          ],
        ),
        throwsFormatException,
      );
      saved = (await planner.loadRollCallLists()).single;
      expect(saved.name, '修改后');
      expect(saved.drawn, isEmpty);
      expect(saved.repeat, isFalse);
      expect(saved.members.single.name, '甲');
      final competing = await Future.wait([
        planner.prepareRollCall(list.id, random: CandidateRandom([0], 1)),
        planner.prepareRollCall(list.id, random: CandidateRandom([0], 1)),
      ]);
      await competing.first.complete();
      await expectLater(competing.last.complete(), throwsStateError);
      expect((await planner.loadRollCallLists()).single.drawn, [1]);
    } finally {
      await store.close();
    }
  });

  test('schema10 迁移保留学习数据和转盘，新增点名名单可完成抽取', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
          db.execute('''
CREATE TABLE independent_lesson_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
course_id INTEGER NOT NULL REFERENCES course_records(id) ON DELETE CASCADE,
date TEXT NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, location TEXT NOT NULL);
ALTER TABLE learning_task_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 1440;
ALTER TABLE course_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 10;
ALTER TABLE countdown_event_records ADD COLUMN reminder_minutes INTEGER NULL DEFAULT 540;
CREATE TABLE wheel_list_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, items TEXT NOT NULL);
INSERT INTO wheel_list_records (name, items) VALUES ('原转盘', '["甲","乙"]');
PRAGMA user_version = 10;
''');
        },
      ),
    );
    try {
      final planner = SemesterPlanner(store);
      final state = await planner.load();
      expect(state.semesters, isNotEmpty);
      expect(state.courses, isNotEmpty);
      expect(state.tasks, isNotEmpty);
      expect(state.classExceptions, hasLength(2));
      expect((await planner.loadWheelLists()).single.items, ['甲', '乙']);
      expect(await planner.loadRollCallLists(), isEmpty);
      final list = await planner.saveRollCallList(
        name: '点名',
        members: [const RollCallMember(id: 1, name: '甲')],
      );
      await (await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([0], 1),
      )).complete();
      expect((await planner.loadRollCallLists()).single.drawn, [1]);
      final after = await planner.load();
      expect(after.currentSemesterId, state.currentSemesterId);
      expect(after.campusTimeZone, state.campusTimeZone);
      expect(after.tasks.single.title, state.tasks.single.title);
    } finally {
      await store.close();
    }
  });

  test('按成员身份抽取：触发确定、取消不消耗、完成一次、耗尽和重启续轮', () async {
    final directory = Directory.systemTemp.createTempSync('roll-round-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final list = await planner.saveRollCallList(
        name: '同名成员',
        members: [
          const RollCallMember(id: 10, name: '林晓', detail: '0112'),
          const RollCallMember(id: 20, name: '林晓', detail: '组长'),
        ],
      );
      final cancelled = await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([1], 2),
      );
      expect(cancelled.member.id, 20);
      expect((await planner.loadRollCallLists()).single.drawn, isEmpty);
      cancelled.cancel();
      await expectLater(cancelled.complete(), throwsStateError);
      final first = await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([0], 2),
      );
      final completions = await Future.wait([
        first.complete(),
        first.complete(),
      ]);
      expect(completions.last.drawn, [10]);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      expect((await planner.loadRollCallLists()).single.drawn, [10]);
      final second = await planner.prepareRollCall(
        list.id,
        random: CandidateRandom([0], 1),
      );
      expect(second.member.id, 20);
      expect((await second.complete()).drawn, [10, 20]);
      await expectLater(planner.prepareRollCall(list.id), throwsStateError);
      final reset = await planner.resetRollCall(list.id);
      expect(reset.drawn, isEmpty);
      expect(reset.round, 2);
    } finally {
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });

  test('多份点名名单命名保存，同名成员独立，重开真实文件后仍可编辑', () async {
    final directory = Directory.systemTemp.createTempSync('roll-call-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final list = await planner.saveRollCallList(
        name: ' 高数学习小组 ',
        members: [
          const RollCallMember(id: 1, name: '林晓', detail: '20260112'),
          const RollCallMember(id: 2, name: '林晓', detail: '组长'),
        ],
      );
      await planner.saveRollCallList(name: '空名单', members: []);
      await planner.saveWheelList(name: '独立转盘', items: ['林晓']);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final lists = await planner.loadRollCallLists();
      expect(lists.map((l) => l.name), ['高数学习小组', '空名单']);
      expect(lists.first.members.map((m) => m.id), [1, 2]);
      expect(lists.first.members.map((m) => m.detail), ['20260112', '组长']);
      await planner.saveRollCallList(
        id: list.id,
        name: '新名单',
        members: [const RollCallMember(id: 2, name: '林晓', detail: '新备注')],
      );
      expect(
        (await planner.loadRollCallLists()).first.members.single.detail,
        '新备注',
      );
      expect((await planner.loadWheelLists()).single.items, ['林晓']);
    } finally {
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });
}
