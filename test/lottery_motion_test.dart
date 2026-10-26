import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unipocket/random_tools/lottery_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/roll_call_random.dart';
import 'support/widget_actions.dart';

void main() {
  testWidgets('签袋摇动与纸签升起有连续绘制变化，1.6秒完成才提交', (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      final output = Directory('build/lottery-preview')
        ..createSync(recursive: true);
      Future<int> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('lottery-scene')),
        );
        final frame = await boundary.toImage();
        final png = (await frame.toByteData(format: ui.ImageByteFormat.png))!;
        final bytes = png.buffer.asUint8List();
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        final hash = Object.hashAll(bytes);
        frame.dispose();
        return hash;
      }

      try {
        await planner.saveLotteryPool(
          name: '学习小组',
          items: ['好事将近', '休息一下', '今天也顺利'],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: LotteryPage(
              planner: planner,
              random: RollCallRandom([(3, 2)]),
            ),
          ),
        );
        await waitFor(tester, find.text('学习小组 · 3项'));
        final action = find.byKey(const ValueKey('lottery-draw'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await capture('ready');
        await tester.tap(action);
        for (
          var i = 0;
          i < 100 && find.text('摇一摇，等待纸签升起…').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pump();
        final frames = <int>{};
        var previous = 0;
        for (final at in [0, 150, 450, 850, 900, 1200, 1599]) {
          await tester.pump(Duration(milliseconds: at - previous));
          frames.add(await capture('rolling-$at'));
          expect(find.text('摇一摇，等待纸签升起…'), findsOneWidget);
          expect(find.byKey(const ValueKey('lottery-result')), findsNothing);
          expect((await planner.loadLotteryPools()).single.drawn, isEmpty);
          previous = at;
        }
        expect(frames.length, greaterThan(3));
        await tester.pump(const Duration(milliseconds: 1));
        await waitFor(tester, find.text('本次抽中'));
        await tester.pumpAndSettle();
        await capture('landed');
        expect(find.text('今\n天\n也\n顺\n利'), findsOneWidget);
        expect((await planner.loadLotteryPools()).single.drawn, [2]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}
