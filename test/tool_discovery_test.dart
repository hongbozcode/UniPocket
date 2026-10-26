import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/tool_library.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

void main() {
  test('schema13 升级保留学习记录、独立名单与抽取轮次，新增发现状态可保存', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v13.sql').readAsStringSync());
        },
      ),
    );
    try {
      final planner = SemesterPlanner(store);
      final state = await planner.load();
      expect(state.semesters.single.name, '升级前的秋季');
      expect(state.campusTimeZone, 'Asia/Tokyo');
      expect(state.courses.single.name, '大学物理');
      expect(state.tasks.single.title, '物理实验报告');
      expect(state.events.single.title, '期中考试');
      expect(state.classExceptions, hasLength(2));
      expect((await planner.loadWheelLists()).single.items, ['甲', '乙']);
      expect((await planner.loadRollCallLists()).single.drawn, [1]);
      expect((await planner.loadRollCallLists()).single.round, 3);
      expect((await planner.loadLotteryPools()).single.drawn, [0]);
      expect((await planner.loadLotteryPools()).single.round, 2);
      expect(
        (await planner.loadGroupLists()).single.members.single.detail,
        '01',
      );
      expect(
        (await planner.loadToolLibrary()).tools(filter: ToolFilter.recent),
        isEmpty,
      );
      await planner.setToolFavorite(RandomTool.groups, true);
      await planner.recordToolUse(RandomTool.groups);
      expect(
        (await planner.loadToolLibrary()).tools(filter: ToolFilter.favorites),
        [RandomTool.groups],
      );
      expect(
        (await planner.loadGroupLists()).single.members.single.name,
        '保留成员',
      );
    } finally {
      await store.close();
    }
  });

  test('收藏与最近使用独立保存，重复进入置顶且重开数据库保留', () async {
    final directory = Directory.systemTemp.createTempSync('tool-library-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      var library = await planner.loadToolLibrary();
      expect(library.tools().map((tool) => tool.title), [
        '转盘',
        '随机点名',
        '随机分组',
        '抽签',
        '掷骰子',
        '抛硬币',
      ]);
      expect(library.tools(filter: ToolFilter.favorites), isEmpty);
      expect(library.tools(filter: ToolFilter.recent), isEmpty);
      await planner.setToolFavorite(RandomTool.wheel, true);
      await planner.recordToolUse(RandomTool.coin);
      await planner.recordToolUse(RandomTool.wheel);
      await planner.recordToolUse(RandomTool.coin);
      await planner.setToolFavorite(RandomTool.coin, true);
      await planner.setToolFavorite(RandomTool.wheel, false);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      library = await planner.loadToolLibrary();
      expect(library.tools(filter: ToolFilter.favorites), [RandomTool.coin]);
      expect(library.tools(filter: ToolFilter.recent), [
        RandomTool.coin,
        RandomTool.wheel,
      ]);
      expect(library.tools(query: '  硬币  '), [RandomTool.coin]);
      expect(library.tools(query: '不存在'), isEmpty);
      expect(library.tools(filter: ToolFilter.favorites, query: '转盘'), isEmpty);
      expect(library.homeTools.take(2), [RandomTool.coin, RandomTool.wheel]);
    } finally {
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });
}
