import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/random_tools/tool_library.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/tool_discovery_fixture.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_discovery_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 工具搜索收藏最近、首页入口及新进程恢复', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    final vertical = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    Future<void> top() async {
      await tester.drag(vertical, const Offset(0, 10000));
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot('15-android-$name');
    }

    try {
      if (!restore) await seedDiscoveryHome(planner);
      await tester.pumpWidget(
        UniPocketApp(planner: planner, clock: () => discoveryInstant),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await capture(restore ? 'home-restored' : 'home');
      await tapVisible(tester, find.text('工具'));
      await waitFor(tester, find.byKey(const ValueKey('tool-search')));
      if (!restore) {
        await capture('tools');
        await tapVisible(tester, find.text('收藏'));
        expect(find.text('还没有收藏工具'), findsOneWidget);
        await capture('favorites-empty');
        await tapVisible(tester, find.text('最近使用'));
        expect(find.text('还没有使用记录'), findsOneWidget);
        await capture('recent-empty');
        await tapVisible(tester, find.text('全部'));
        await tester.enterText(
          find.byKey(const ValueKey('tool-search')),
          '没有这个工具',
        );
        await tester.pumpAndSettle();
        await capture('search-empty');
        await tester.enterText(
          find.byKey(const ValueKey('tool-search')),
          ' 硬币 ',
        );
        await tester.pumpAndSettle();
        expect(find.text('抛硬币'), findsOneWidget);
        expect(find.text('掷骰子'), findsNothing);
        await capture('search');
        await tapVisible(tester, find.byTooltip('清空搜索'));
        for (final tool in [
          RandomTool.wheel,
          RandomTool.rollCall,
          RandomTool.die,
        ]) {
          await tapVisible(
            tester,
            find.byKey(ValueKey('favorite-${tool.name}')),
          );
          await waitFor(tester, find.byTooltip('取消收藏${tool.title}'));
        }
        for (final tool in RandomTool.values) {
          await tapVisible(tester, find.byKey(ValueKey('tool-${tool.name}')));
          await waitFor(tester, find.byTooltip(RegExp('^返回')));
          expect(find.text(tool.title), findsOneWidget);
          await tapVisible(tester, find.byTooltip(RegExp('^返回')));
        }
        await top();
        await capture('tools-favorites');
      }
      await tapVisible(tester, find.text('收藏'));
      expect(
        (await planner.loadToolLibrary()).tools(filter: ToolFilter.favorites),
        [RandomTool.wheel, RandomTool.rollCall, RandomTool.die],
      );
      await capture(restore ? 'favorites-restored' : 'favorites');
      await tapVisible(tester, find.text('最近使用'));
      expect(
        (await planner.loadToolLibrary())
            .tools(filter: ToolFilter.recent)
            .first,
        restore ? RandomTool.wheel : RandomTool.coin,
      );
      await capture(restore ? 'recent-restored' : 'recent');
      await tapVisible(tester, find.text('首页'));
      await tapVisible(tester, find.byKey(const ValueKey('home-tool-wheel')));
      await waitFor(tester, find.text('转盘'));
      await tapVisible(tester, find.byTooltip('返回'));
      await tester.ensureVisible(find.text('常用工具'));
      await capture(restore ? 'home-tools-restored' : 'home-tools');
      await tapVisible(tester, find.text('全部工具'));
      await waitFor(tester, find.byKey(const ValueKey('tool-search')));
      await tapVisible(tester, find.text('最近使用'));
      expect(
        (await planner.loadToolLibrary())
            .tools(filter: ToolFilter.recent)
            .first,
        RandomTool.wheel,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
