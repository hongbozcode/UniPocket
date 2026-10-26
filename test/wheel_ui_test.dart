import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/random_tools/wheel_page.dart';

import 'support/candidate_random.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  testWidgets('从工具页创建列表，全部候选仅抽一次，指针与结果一致，返回取消', (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() async {
      final directory = Directory.systemTemp.createTempSync(
        'unipocket-wheel-ui-',
      );
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: SemesterPlanner(store),
            random: CandidateRandom([0, 1, 2, 0], 3),
          ),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('转盘'));
        await waitFor(tester, find.text('新建转盘'));
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('wheel-spin')))
              .onPressed,
          isNull,
        );
        await tapVisible(tester, find.text('新建转盘'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '列表名称'),
          '午餐',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '选项（每行一项）'),
          '面馆\n面馆\n轻食',
        );
        await tester.pump();
        expect(find.textContaining('重复文字'), findsOneWidget);
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('午餐 · 3项'));
        for (final entry in [(1, '面馆'), (2, '面馆'), (3, '轻食')]) {
          final action = find.byKey(const ValueKey('wheel-spin'));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pump();
          expect(find.text('转动中…'), findsOneWidget);
          expect(tester.widget<FilledButton>(action).onPressed, isNull);
          await tester.tap(action);
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('wheel-result')))
                .data,
            entry.$2,
          );
          expect(
            find.bySemanticsLabel('指针：第${entry.$1}项，${entry.$2}'),
            findsOneWidget,
          );
        }
        await tester.ensureVisible(find.byKey(const ValueKey('wheel-spin')));
        await tester.tap(find.byKey(const ValueKey('wheel-spin')));
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('转盘'));
        await waitFor(tester, find.text('午餐 · 3项'));
        expect(find.text('等待转动'), findsOneWidget);
        await tapVisible(tester, find.text('编辑选项'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '列表名称'),
          '不保存',
        );
        await tapVisible(tester, find.byTooltip('取消编辑'));
        expect(find.text('午餐 · 3项'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        directory.deleteSync(recursive: true);
      }
    });
    semantics.dispose();
  });

  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍字：空列表、单选项、长文字、多列表切换和编辑可达', (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final semantics = tester.ensureSemantics();
        await tester.runAsync(() async {
          final store = PlannerStore(NativeDatabase.memory());
          final planner = SemesterPlanner(store);
          const long = '这是一个很长的午餐选项名称并且包含 English words 以及更多中文';
          const title = '很长的列表名称也应能够完整换行显示';
          try {
            await planner.saveWheelList(name: '空列表', items: []);
            await planner.saveWheelList(name: title, items: [long]);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(useMaterial3: true),
                home: WheelPage(
                  planner: planner,
                  random: CandidateRandom([0, 0], 1),
                ),
              ),
            );
            await waitFor(tester, find.text('空列表 · 0项'));
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('wheel-spin')),
              200,
            );
            expect(
              tester
                  .widget<FilledButton>(
                    find.byKey(const ValueKey('wheel-spin')),
                  )
                  .onPressed,
              isNull,
            );
            await tapVisible(tester, find.text('空列表 · 0项'));
            await tapVisible(tester, find.text(title));
            final action = find.byKey(const ValueKey('wheel-spin'));
            await tapVisible(tester, action);
            await tester.pump(const Duration(seconds: 4));
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<Text>(find.byKey(const ValueKey('wheel-result')))
                  .data,
              long,
            );
            expect(find.bySemanticsLabel('指针：第1项，$long'), findsOneWidget);
            await tapVisible(
              tester,
              find.text('● 1. $long', findRichText: true),
            );
            expect(tester.takeException(), isNull);
            await tapVisible(tester, find.text('编辑选项'));
            await tester.enterText(
              find.widgetWithText(TextFormField, '选项（每行一项）'),
              '唯一选项',
            );
            await tapVisible(tester, find.text('保存到本机'));
            await waitFor(tester, find.text('$title · 1项'));
            expect((await planner.loadWheelLists()).last.items, ['唯一选项']);
            await tapVisible(tester, find.text('等待转动'));
            expect(find.text('等待转动'), findsOneWidget);
            if (action.evaluate().isEmpty) {
              await tester.scrollUntilVisible(action, 100);
            }
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            await tester.tap(action);
            await tester.pump();
            await tester.ensureVisible(find.text('取消转动'));
            await tester.tap(find.text('取消转动'));
            await tester.pump();
            await tester.pump(const Duration(seconds: 4));
            expect(find.text('已取消转动，未揭晓结果'), findsOneWidget);
            await tapVisible(tester, find.text('等待转动'));
            expect(find.text('等待转动'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
        semantics.dispose();
      });
    }
  }
}
