import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/roll_call_random.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_lottery_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');
const longText =
    '愿你在忙碌的日子里，也能留一点时间给自己。\n放下手机，走到窗边，看看晚霞；和朋友聊聊天，再带着好心情出发。Every small step counts.';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 签池重复项、完整长签文、返回取消及进程重启续轮', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    Future<void> capture(String name) async {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
        const Offset(0, 10000),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> scrollToDraw() async {
      final draw = find.byKey(const ValueKey('lottery-draw'));
      if (draw.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          draw,
          160,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
      }
      await tester.ensureVisible(draw);
      await tester.pumpAndSettle();
    }

    try {
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          random: RollCallRandom(restore ? [(2, 1)] : [(3, 0), (2, 1)]),
        ),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('工具'));
      await capture(restore ? '13-android-tools-restored' : '13-android-tools');
      await tapVisible(tester, find.text('抽签'));
      if (!restore) {
        await waitFor(tester, find.text('新建签池'));
        await capture('13-android-empty');
        await tapVisible(tester, find.text('新建签池'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '签池名称'),
          '今日签池',
        );
        for (var i = 1; i <= 3; i++) {
          if (i > 1) await tapVisible(tester, find.text('添加签项'));
          await tester.enterText(
            find.byKey(ValueKey('ticket-text-$i')),
            i == 3 ? longText : '好事将近',
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('13-android-editor');
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('今日签池 · 3项'));
        await capture('13-android-ready');
        await tapVisible(tester, find.byKey(const ValueKey('lottery-draw')));
        await waitFor(tester, find.byKey(const ValueKey('lottery-result')));
        expect((await planner.loadLotteryPools()).single.drawn, [0]);
        await capture('13-android-result');
        await tapVisible(tester, find.text('编辑签池'));
        await binding.takeScreenshot('13-android-edit-confirm');
        await tapVisible(tester, find.text('继续编辑'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '签池名称'),
          '不保存',
        );
        await tapVisible(tester, find.byTooltip('取消编辑'));
        expect((await planner.loadLotteryPools()).single.name, '今日签池');
        await scrollToDraw();
        await tester.tap(find.byKey(const ValueKey('lottery-draw')));
        for (
          var i = 0;
          i < 100 && find.text('摇一摇，等待纸签升起…').evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pump(const Duration(milliseconds: 1450));
        expect((await planner.loadLotteryPools()).single.drawn, [0]);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect((await planner.loadLotteryPools()).single.drawn, [0]);
        await tapVisible(tester, find.text('抽签'));
        await waitFor(tester, find.text('今日签池 · 3项'));
        await tapVisible(tester, find.text('今日签池 · 3项'));
        await tapVisible(tester, find.text('新建签池'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '签池名称'),
          '活动签池',
        );
        await tapVisible(tester, find.byTooltip('移除签 1'));
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('活动签池 · 0项'));
        await capture('13-android-empty-pool');
      } else {
        await waitFor(tester, find.text('今日签池 · 3项'));
        final pools = await planner.loadLotteryPools();
        expect(pools.map((p) => p.name), ['今日签池', '活动签池']);
        expect(pools.first.drawn, [0]);
        expect(pools.first.items, ['好事将近', '好事将近', longText]);
        await capture('13-android-process-restored');
        await tapVisible(tester, find.byKey(const ValueKey('lottery-draw')));
        await waitFor(tester, find.byKey(const ValueKey('lottery-result')));
        expect((await planner.loadLotteryPools()).first.drawn, [0, 2]);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey('lottery-result')),
              )
              .data,
          longText,
        );
        await capture('13-android-long-result');
        await tapVisible(tester, find.byKey(const ValueKey('lottery-result')));
        await binding.takeScreenshot('13-android-full-text');
        await tapVisible(tester, find.text('今日签池 · 3项'));
        await binding.takeScreenshot('13-android-picker');
        await tapVisible(tester, find.text('今日签池'));
        await tapVisible(tester, find.text('可重复'));
        await tapVisible(tester, find.widgetWithText(FilledButton, '开始新一轮'));
        await waitFor(tester, find.text('完整签池 3 项'));
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await capture('13-android-repeat');
      }
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
