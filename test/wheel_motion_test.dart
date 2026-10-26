import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/wheel_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/candidate_random.dart';
import 'support/widget_actions.dart';

void main() {
  testWidgets('六个扇区绘制颜色与获选位置一致，3.1秒后才揭晓且运动帧有变化', (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      const options = ['食堂一楼', '食堂二楼', '面馆', '盖饭', '轻食', '饺子'];
      // Literal source palette, sampled from the rendered sector under the pointer.
      const colors = [
        0xffe4f2ff,
        0xffeee4ff,
        0xfffff1bf,
        0xffe1f2e8,
        0xffffe5ec,
        0xffffe7d7,
      ];
      final directory = Directory('build/wheel-preview')
        ..createSync(recursive: true);
      Future<int> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('wheel-scene')),
        );
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File('${directory.path}/$name.png')
            .writeAsBytes(png.buffer.asUint8List());
        final offset = (70 * image.width + image.width ~/ 2 + 14) * 4;
        final color =
            0xff000000 |
            bytes.getUint8(offset) << 16 |
            bytes.getUint8(offset + 1) << 8 |
            bytes.getUint8(offset + 2);
        image.dispose();
        return color;
      }

      try {
        await planner.saveWheelList(name: '午餐怎么选', items: options);
        await tester.pumpWidget(
          MaterialApp(
            home: WheelPage(
              planner: planner,
              random: CandidateRandom([0, 1, 2, 3, 4, 5], 6),
            ),
          ),
        );
        await waitFor(tester, find.text('午餐怎么选 · 6项'));
        for (var i = 0; i < 6; i++) {
          final action = find.byKey(const ValueKey('wheel-spin'));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pump();
          final frames = <int>{};
          for (var step = 0; step < 10; step++) {
            await tester.pump(const Duration(milliseconds: 300));
            frames.add(await capture('candidate-$i-frame-$step'));
            expect(find.text('转动中…'), findsOneWidget);
          }
          expect(frames.length, greaterThan(1));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('wheel-result')))
                .data,
            options[i],
          );
          expect(await capture('candidate-$i-landed'), colors[i]);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}
