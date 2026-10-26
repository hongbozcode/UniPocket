import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/random_tools/tool_library.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/widget_actions.dart';
import 'support/tool_discovery_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  testWidgets('首页顺序为今日课程、未完成任务、近期事件、常用工具，末项进入工具箱', (tester) async {
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      try {
        await seedDiscoveryHome(planner);
        await tester.pumpWidget(
          UniPocketApp(planner: planner, clock: () => discoveryInstant),
        );
        await waitFor(tester, find.text('今日课程'));
        final positions = <double>[];
        final scrollable = find.byType(Scrollable).first;
        for (final label in ['今日课程', '学习任务', '近期倒计时', '常用工具']) {
          final target = find.text(label);
          if (target.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              target,
              200,
              scrollable: scrollable,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          positions.add(
            tester.getTopLeft(target).dy +
                tester.state<ScrollableState>(scrollable).position.pixels,
          );
        }
        expect(positions[0], lessThan(positions[1]));
        expect(positions[1], lessThan(positions[2]));
        expect(positions[2], lessThan(positions[3]));
        await tapVisible(tester, find.text('全部工具'));
        await waitFor(tester, find.byKey(const ValueKey('tool-search')));
        expect(find.text('随机工具箱'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
  testWidgets('搜索、收藏与最近空状态，首页进入后重新打开仍保留', (tester) async {
    await tester.runAsync(() async {
      final directory = Directory.systemTemp.createTempSync('discovery-ui-');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      try {
        await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await waitFor(tester, find.byKey(const ValueKey('tool-search')));
        await tapVisible(tester, find.text('收藏'));
        expect(find.text('还没有收藏工具'), findsOneWidget);
        await tapVisible(tester, find.text('最近使用'));
        expect(find.text('还没有使用记录'), findsOneWidget);
        await tapVisible(tester, find.text('全部'));
        await tester.enterText(
          find.byKey(const ValueKey('tool-search')),
          '不存在',
        );
        await tester.pumpAndSettle();
        expect(find.text('没有找到相关工具'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('tool-search')),
          ' 硬币 ',
        );
        await tester.pumpAndSettle();
        expect(find.text('抛硬币'), findsOneWidget);
        expect(find.text('掷骰子'), findsNothing);
        await tapVisible(tester, find.byKey(const ValueKey('favorite-coin')));
        await waitFor(tester, find.byTooltip('取消收藏抛硬币'));
        await tapVisible(tester, find.byKey(const ValueKey('tool-coin')));
        await waitFor(tester, find.text('正面还是反面，交给这一抛'));
        await tapVisible(tester, find.byTooltip(RegExp('^返回')));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('首页'));
        await tapVisible(tester, find.byKey(const ValueKey('home-tool-coin')));
        await waitFor(tester, find.text('正面还是反面，交给这一抛'));
        await tapVisible(tester, find.byTooltip(RegExp('^返回')));
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await waitFor(tester, find.byKey(const ValueKey('tool-search')));
        await tapVisible(tester, find.text('收藏'));
        expect(find.text('抛硬币'), findsOneWidget);
        await tapVisible(tester, find.text('最近使用'));
        expect(find.text('抛硬币'), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('favorite-coin')));
        await waitFor(tester, find.byTooltip('收藏抛硬币'));
        await tapVisible(tester, find.text('收藏'));
        expect(find.text('还没有收藏工具'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        directory.deleteSync(recursive: true);
      }
    });
  });

  for (final width in [320.0, 393.0]) {
    testWidgets('$width 窄屏双倍文字安全区，全部六项可进入且末项可达', (tester) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final planner = SemesterPlanner(store);
        try {
          await tester.pumpWidget(UniPocketApp(planner: planner));
          await waitFor(tester, find.text('UniPocket'));
          await tapVisible(tester, find.text('工具'));
          await waitFor(tester, find.byKey(const ValueKey('tool-search')));
          for (final tool in RandomTool.values) {
            await tapVisible(tester, find.byKey(ValueKey('tool-${tool.name}')));
            await waitFor(tester, find.byTooltip(RegExp('^返回')));
            expect(find.text(tool.title), findsOneWidget);
            await tapVisible(tester, find.byTooltip(RegExp('^返回')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(
            (await planner.loadToolLibrary()).tools(filter: ToolFilter.recent),
            RandomTool.values.reversed,
          );
          await tapVisible(tester, find.text('首页'));
          await tapVisible(
            tester,
            find.byKey(const ValueKey('home-tool-coin')),
          );
          await waitFor(tester, find.text('正面还是反面，交给这一抛'));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }
}
