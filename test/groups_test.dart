import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/groups.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/roll_call_random.dart';

void main() {
  test('schema12 升级保留学习数据与各工具轮次，新增名单可使用', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v12.sql').readAsStringSync());
        },
      ),
    );
    try {
      final planner = SemesterPlanner(store);
      final before = await planner.load();
      expect(before.semesters, isNotEmpty);
      expect(before.courses, isNotEmpty);
      expect(before.tasks, isNotEmpty);
      expect(before.classExceptions, hasLength(2));
      expect((await planner.loadWheelLists()).single.items, ['甲', '乙']);
      final roll = (await planner.loadRollCallLists()).single;
      expect(roll.round, 3);
      expect(roll.drawn, [1]);
      final pool = (await planner.loadLotteryPools()).single;
      expect(pool.round, 2);
      expect(pool.drawn, [0]);
      expect(await planner.loadGroupLists(), isEmpty);
      final list = await planner.saveGroupList(
        name: '新名单',
        members: [const GroupMember(id: 1, name: '新同学')],
      );
      expect(
        (await planner.makeGroups(
          list.id,
          mode: GroupMode.count,
          amount: 1,
        )).single.single.name,
        '新同学',
      );
      expect((await planner.loadRollCallLists()).single.drawn, [1]);
      expect((await planner.loadLotteryPools()).single.drawn, [0]);
      final after = await planner.load();
      expect(after.currentSemesterId, before.currentSemesterId);
      expect(after.campusTimeZone, before.campusTimeZone);
      expect(after.tasks.single.title, before.tasks.single.title);
    } finally {
      await store.close();
    }
  });
  test('先打乱再分配，10人上限4得4/3/3；每个人恰好出现一次', () async {
    final store = PlannerStore(NativeDatabase.memory());
    final planner = SemesterPlanner(store);
    try {
      final list = await planner.saveGroupList(
        name: '名单',
        members: [for (var i = 1; i <= 10; i++) GroupMember(id: i, name: '同名')],
      );
      final result = await planner.makeGroups(
        list.id,
        mode: GroupMode.limit,
        amount: 4,
        random: RollCallRandom([
          (10, 0),
          (9, 0),
          (8, 0),
          (7, 0),
          (6, 0),
          (5, 0),
          (4, 0),
          (3, 0),
          (2, 0),
        ]),
      );
      expect(result.map((g) => g.length), [4, 3, 3]);
      expect(result.map((g) => g.map((m) => m.id).toList()).toList(), [
        [2, 5, 8, 1],
        [3, 6, 9],
        [4, 7, 10],
      ]);
      expect(result.expand((g) => g).map((m) => m.id).toSet(), {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
      });
      for (var count = 1; count <= 10; count++) {
        final groups = await planner.makeGroups(
          list.id,
          mode: GroupMode.count,
          amount: count,
        );
        final sizes = groups.map((g) => g.length).toList()..sort();
        expect(groups.length, count);
        expect(sizes.last - sizes.first, lessThanOrEqualTo(1));
        expect(groups.expand((g) => g).map((m) => m.id).toSet(), {
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
        });
      }
      final single = await planner.makeGroups(
        list.id,
        mode: GroupMode.limit,
        amount: 100,
      );
      expect(single.single.length, 10);
      final hugeLimit = await planner.makeGroups(
        list.id,
        mode: GroupMode.limit,
        amount: 9223372036854775807,
      );
      expect(hugeLimit.single.length, 10);
      for (final mode in GroupMode.values) {
        for (final amount in [0, -1]) {
          await expectLater(
            planner.makeGroups(list.id, mode: mode, amount: amount),
            throwsFormatException,
          );
        }
      }
      await expectLater(
        planner.makeGroups(list.id, mode: GroupMode.count, amount: 11),
        throwsFormatException,
      );
      final empty = await planner.saveGroupList(name: '空', members: []);
      await expectLater(
        planner.makeGroups(empty.id, mode: GroupMode.limit, amount: 1),
        throwsFormatException,
      );
      for (final members in [
        [const GroupMember(id: 1, name: ' ')],
        [const GroupMember(id: 0, name: '甲')],
        [
          const GroupMember(id: 1, name: '甲'),
          const GroupMember(id: 1, name: '乙'),
        ],
      ]) {
        expect(
          () =>
              planner.saveGroupList(id: list.id, name: '非法', members: members),
          throwsFormatException,
        );
      }
      expect(
        () => planner.saveGroupList(id: list.id, name: ' ', members: []),
        throwsFormatException,
      );
      expect((await planner.loadGroupLists()).first.members.length, 10);
    } finally {
      await store.close();
    }
  });
  test('独立命名名单保留同名成员，真实文件重开后可读和编辑', () async {
    final dir = Directory.systemTemp.createTempSync('groups-');
    final file = File('${dir.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final list = await planner.saveGroupList(
        name: ' 学习伙伴 ',
        members: [
          const GroupMember(id: 1, name: ' 林晓 ', detail: ' 0112 '),
          const GroupMember(id: 2, name: '林晓', detail: '组长'),
        ],
      );
      await planner.saveGroupList(name: '空名单', members: []);
      await planner.saveWheelList(name: '其他工具', items: ['甲']);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final lists = await planner.loadGroupLists();
      expect(lists.map((l) => l.name), ['学习伙伴', '空名单']);
      expect(lists.first.members.map((m) => m.id), [1, 2]);
      expect(lists.first.members.map((m) => m.name), ['林晓', '林晓']);
      expect(lists.first.members.map((m) => m.detail), ['0112', '组长']);
      await planner.saveGroupList(
        id: list.id,
        name: '修改后',
        members: [lists.first.members.last],
      );
      expect((await planner.loadGroupLists()).first.members.single.id, 2);
      expect((await planner.loadWheelLists()).single.items, ['甲']);
      expect(await planner.loadRollCallLists(), isEmpty);
      expect(await planner.loadLotteryPools(), isEmpty);
    } finally {
      await store.close();
      dir.deleteSync(recursive: true);
    }
  });
}
