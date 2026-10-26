import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/random_tools/lottery_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/roll_call_random.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍字：空签池、完整长签文、重复模式与编辑重置确认', (tester) async {
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await tester.runAsync(() async {
          final store = PlannerStore(NativeDatabase.memory());
          final planner = SemesterPlanner(store);
          final longText =
              '这是一段完整的长签文，包含 English words 和换行\n${'愿你保持期待，慢慢前行。' * 30}';
          try {
            await planner.saveLotteryPool(name: '空签池', items: []);
            await planner.saveLotteryPool(
              name: '非常长的自定义签池名称需要换行完整显示',
              items: [longText],
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: appTheme(),
                home: LotteryPage(planner: planner),
              ),
            );
            await waitFor(tester, find.text('空签池 · 0项'));
            final draw = find.byKey(const ValueKey('lottery-draw'));
            await tester.scrollUntilVisible(
              draw,
              180,
              scrollable: verticalScroll(),
            );
            expect(tester.widget<FilledButton>(draw).onPressed, isNull);
            await tapVisible(tester, find.text('空签池 · 0项'));
            await tapVisible(tester, find.text('非常长的自定义签池名称需要换行完整显示'));
            await tapVisible(tester, draw);
            await waitFor(tester, find.byKey(const ValueKey('lottery-result')));
            expect(
              tester
                  .widget<SelectableText>(
                    find.byKey(const ValueKey('lottery-result')),
                  )
                  .data,
              longText,
            );
            await tester.scrollUntilVisible(
              draw,
              180,
              scrollable: verticalScroll(),
            );
            expect(tester.widget<FilledButton>(draw).onPressed, isNull);
            await tapVisible(tester, find.text('编辑签池'));
            await tapVisible(tester, find.text('保留进度'));
            expect((await planner.loadLotteryPools()).last.drawn, [0]);
            await tapVisible(tester, find.text('编辑签池'));
            await tapVisible(tester, find.text('继续编辑'));
            await tester.enterText(
              find.widgetWithText(TextFormField, '签池名称'),
              '放弃修改',
            );
            await tapVisible(tester, find.byTooltip('取消编辑'));
            expect((await planner.loadLotteryPools()).last.drawn, [0]);
            await tapVisible(tester, find.text('可重复'));
            await tapVisible(
              tester,
              find.widgetWithText(FilledButton, '开始新一轮'),
            );
            await waitFor(tester, find.text('完整签池 1 项'));
            expect(find.byType(LinearProgressIndicator), findsNothing);
            await tapVisible(tester, draw);
            await waitFor(tester, find.byKey(const ValueKey('lottery-result')));
            expect((await planner.loadLotteryPools()).last.drawn, [0]);
            await tapVisible(tester, find.text('编辑签池'));
            await tapVisible(tester, find.text('继续编辑'));
            await tester.enterText(
              find.widgetWithText(TextFormField, '签池名称'),
              '修改后',
            );
            await tapVisible(tester, find.text('保存到本机'));
            await waitFor(tester, find.text('修改后 · 1项'));
            expect(
              (await planner.loadLotteryPools()).last.items.single,
              longText,
            );
            expect((await planner.loadLotteryPools()).last.drawn, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }

  testWidgets('工具入口新建重复签文，抽取锁定，显式取消及后台不消耗', (tester) async {
    tester.view.physicalSize = const Size(393, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            random: RollCallRandom([(2, 1), (2, 0)]),
          ),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('抽签'));
        await tapVisible(tester, find.text('新建签池'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '签池名称'),
          '今日签池',
        );
        await tester.enterText(
          find.byKey(const ValueKey('ticket-text-1')),
          '好事将近',
        );
        await tapVisible(tester, find.text('添加签项'));
        await tester.enterText(
          find.byKey(const ValueKey('ticket-text-2')),
          '好事将近',
        );
        await tester.pump();
        expect(find.textContaining('有重复签文'), findsOneWidget);
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('今日签池 · 2项'));
        final draw = find.byKey(const ValueKey('lottery-draw'));
        for (final background in [false, true]) {
          await tester.scrollUntilVisible(
            draw,
            180,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          await tester.tap(draw);
          await waitForDrawing(tester);
          expect(
            tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, '编辑签池'),
                )
                .onPressed,
            isNull,
          );
          expect(
            tester
                .widget<TextButton>(find.widgetWithText(TextButton, '可重复'))
                .onPressed,
            isNull,
          );
          expect(tester.widget<FilledButton>(draw).onPressed, isNull);
          if (background) {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
          } else {
            await tester.ensureVisible(find.text('取消抽签'));
            await tester.tap(find.text('取消抽签'));
          }
          await tester.pumpAndSettle();
          expect((await planner.loadLotteryPools()).single.drawn, isEmpty);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}

Future<void> waitForDrawing(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.text('摇一摇，等待纸签升起…').evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await tester.pump();
  }
  expect(find.text('摇一摇，等待纸签升起…'), findsOneWidget);
  await tester.pump();
}

Finder verticalScroll() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;
