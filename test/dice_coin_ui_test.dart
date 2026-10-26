import 'dart:math';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/widget_actions.dart';
import 'support/candidate_random.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('从工具入口掷骰子，六个候选均可得到一致骰面与文字，进行中不重复抽取', (tester) async {
    tester.view.physicalSize = const Size(393, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: SemesterPlanner(store),
            random: CandidateRandom([0, 1, 2, 3, 4, 5], 6),
          ),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('掷骰子'));
        expect(find.text('等待投掷'), findsOneWidget);
        for (final point in [1, 2, 3, 4, 5, 6]) {
          final action = find.byKey(const ValueKey('random-action'));
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pump();
          expect(find.text('投掷中…'), findsOneWidget);
          expect(tester.widget<FilledButton>(action).onPressed, isNull);
          await tester.tap(action);
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(find.text('$point'), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp('骰面：$point 点')), findsOneWidget);
          expect(find.text('再掷一次'), findsOneWidget);
        }
        await tapVisible(tester, find.byTooltip('返回'));
        await tapVisible(tester, find.text('掷骰子'));
        expect(find.text('等待投掷'), findsOneWidget);
        expect(find.text('本次点数'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        semantics.dispose();
      }
    });
  });

  testWidgets('硬币两面对应星星和月牙，返回取消与重开数据库均不保留结果', (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semantics = tester.ensureSemantics();
    await tester.runAsync(() async {
      final directory = Directory.systemTemp.createTempSync('unipocket-toss-');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      final random = CandidateRandom([0, 1, 0, 1], 2);
      try {
        await tester.pumpWidget(
          UniPocketApp(planner: SemesterPlanner(store), random: random),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        expect(find.text('转盘'), findsOneWidget);
        await tapVisible(tester, find.text('抛硬币'));
        expect(find.text('等待投掷'), findsOneWidget);
        for (final result in [('正面', '星星正面'), ('反面', '月牙反面')]) {
          await tapVisible(tester, find.byKey(const ValueKey('random-action')));
          // runAsync uses wall time; advance the widget feedback clock explicitly.
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(find.text(result.$1), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('币面：${result.$2}')),
            findsOneWidget,
          );
        }
        await tester.tap(find.byKey(const ValueKey('random-action')));
        await tester.pump();
        expect(find.text('投掷中…'), findsOneWidget);
        expect(find.text('反面'), findsNothing);
        // Pop the route immediately while feedback is pending (Android back).
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('抛硬币'));
        expect(find.text('等待投掷'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('等待投掷'), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('random-action')));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text('反面'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        await tester.pumpWidget(
          UniPocketApp(planner: SemesterPlanner(store), random: random),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('抛硬币'));
        expect(find.text('等待投掷'), findsOneWidget);
        expect(find.text('本次结果'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        directory.deleteSync(recursive: true);
        semantics.dispose();
      }
    });
  });

  for (final width in [320.0, 393.0]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('$width 宽度 $textScale 倍文字，安全区内结果和重复操作可滚动访问', (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await tester.runAsync(() async {
          final store = PlannerStore(NativeDatabase.memory());
          try {
            await tester.pumpWidget(
              UniPocketApp(planner: SemesterPlanner(store), random: Random(7)),
            );
            await waitFor(tester, find.text('UniPocket'));
            await tapVisible(tester, find.text('工具'));
            for (final title in ['掷骰子', '抛硬币']) {
              await tapVisible(tester, find.text(title));
              for (var attempt = 0; attempt < 2; attempt++) {
                await tapVisible(
                  tester,
                  find.byKey(const ValueKey('random-action')),
                );
                await tester.pump(const Duration(seconds: 1));
                await tester.pumpAndSettle();
                await tester.ensureVisible(
                  find.byKey(const ValueKey('toss-result')),
                );
                expect(
                  tester
                      .widget<Text>(find.byKey(const ValueKey('toss-result')))
                      .data,
                  title == '掷骰子'
                      ? matches(RegExp(r'^[1-6]$'))
                      : isIn(['正面', '反面']),
                );
                expect(tester.takeException(), isNull);
              }
              await tapVisible(tester, find.text('结果仅本次展示，不保存历史'));
              await tapVisible(tester, find.byTooltip('返回'));
              expect(tester.takeException(), isNull);
            }
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }
}
