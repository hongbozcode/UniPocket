import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/candidate_random.dart';

void main() {
  test('重复模式完整等概率候选，编辑和重置拒绝旧反馈及非法修改', () async {
    final store = PlannerStore(NativeDatabase.memory());
    final planner = SemesterPlanner(store);
    try {
      final pool = await planner.saveLotteryPool(name: '签池', items: ['甲', '乙']);
      await planner.resetLottery(pool.id, repeat: true);
      for (var i = 0; i < 3; i++) {
        await (await planner.prepareLottery(
          pool.id,
          random: CandidateRandom([1], 2),
        )).complete();
      }
      var saved = (await planner.loadLotteryPools()).single;
      expect(saved.drawn, [1, 1, 1]);
      expect(saved.candidates, [0, 1]);
      final stale = await planner.prepareLottery(pool.id);
      await planner.resetLottery(pool.id, repeat: false);
      await expectLater(stale.complete(), throwsStateError);
      final editing = await planner.prepareLottery(pool.id);
      await planner.saveLotteryPool(id: pool.id, name: '改名', items: ['新签']);
      await expectLater(editing.complete(), throwsStateError);
      expect(
        () => planner.saveLotteryPool(id: pool.id, name: '错误', items: [' ']),
        throwsFormatException,
      );
      saved = (await planner.loadLotteryPools()).single;
      expect(saved.name, '改名');
      expect(saved.items, ['新签']);
      expect(saved.drawn, isEmpty);
      final competing = await Future.wait([
        planner.prepareLottery(pool.id),
        planner.prepareLottery(pool.id),
      ]);
      await competing.first.complete();
      await expectLater(competing.last.complete(), throwsStateError);
      expect((await planner.loadLotteryPools()).single.drawn, [0]);
    } finally {
      await store.close();
    }
  });

  test('schema11 迁移保留学习、转盘与点名轮次，新增签池独立抽取', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
          db.execute('''
CREATE TABLE independent_lesson_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, course_id INTEGER NOT NULL REFERENCES course_records(id) ON DELETE CASCADE, date TEXT NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, location TEXT NOT NULL);
ALTER TABLE learning_task_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 1440;
ALTER TABLE course_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 10;
ALTER TABLE countdown_event_records ADD COLUMN reminder_minutes INTEGER NULL DEFAULT 540;
CREATE TABLE wheel_list_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, items TEXT NOT NULL);
INSERT INTO wheel_list_records (name, items) VALUES ('原转盘', '["甲","乙"]');
CREATE TABLE roll_call_list_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, members TEXT NOT NULL, repeat INTEGER NOT NULL DEFAULT 0, round INTEGER NOT NULL DEFAULT 1, revision INTEGER NOT NULL DEFAULT 0, drawn TEXT NOT NULL DEFAULT '[]');
INSERT INTO roll_call_list_records (name, members, round, drawn) VALUES ('原点名', '[{"id":1,"name":"甲","detail":""},{"id":2,"name":"乙","detail":""}]', 3, '[1]');
PRAGMA user_version = 11;
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
      final roll = (await planner.loadRollCallLists()).single;
      expect(roll.round, 3);
      expect(roll.drawn, [1]);
      expect(await planner.loadLotteryPools(), isEmpty);
      final pool = await planner.saveLotteryPool(name: '新签池', items: ['签']);
      await (await planner.prepareLottery(pool.id)).complete();
      expect((await planner.loadLotteryPools()).single.drawn, [0]);
      expect((await planner.loadRollCallLists()).single.drawn, [1]);
      expect(
        (await planner.load()).tasks.single.title,
        state.tasks.single.title,
      );
    } finally {
      await store.close();
    }
  });
  test('签池独立保存重复签文，取消不消耗，完成一次，重启续轮及耗尽主动重置', () async {
    final dir = Directory.systemTemp.createTempSync('lottery-');
    final file = File('${dir.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final pool = await planner.saveLotteryPool(
        name: ' 今日签池 ',
        items: ['好事将近', '好事将近'],
      );
      await planner.saveLotteryPool(name: '空签池', items: []);
      await planner.saveWheelList(name: '独立转盘', items: ['其他']);
      final cancelled = await planner.prepareLottery(
        pool.id,
        random: CandidateRandom([1], 2),
      );
      expect(cancelled.text, '好事将近');
      expect((await planner.loadLotteryPools()).first.drawn, isEmpty);
      cancelled.cancel();
      await expectLater(cancelled.complete(), throwsStateError);
      final first = await planner.prepareLottery(
        pool.id,
        random: CandidateRandom([1], 2),
      );
      await Future.wait([first.complete(), first.complete()]);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final pools = await planner.loadLotteryPools();
      expect(pools.map((p) => p.name), ['今日签池', '空签池']);
      expect(pools.first.items, ['好事将近', '好事将近']);
      expect(pools.first.drawn, [1]);
      final second = await planner.prepareLottery(
        pool.id,
        random: CandidateRandom([0], 1),
      );
      expect((await second.complete()).drawn, [1, 0]);
      await expectLater(planner.prepareLottery(pool.id), throwsStateError);
      final reset = await planner.resetLottery(pool.id);
      expect(reset.round, 2);
      expect(reset.drawn, isEmpty);
      expect((await planner.loadWheelLists()).single.items, ['其他']);
      expect(await planner.loadRollCallLists(), isEmpty);
    } finally {
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
