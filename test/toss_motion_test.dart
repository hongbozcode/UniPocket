import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/candidate_random.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final die in [true, false]) {
    testWidgets('${die ? '骰子' : '硬币'}按 HTML 时序腾空、落地、回弹，旋转图像有变化且不越出投掷台', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final name = die ? 'die' : 'coin';
        final directory = Directory('build/toss-preview')
          ..createSync(recursive: true);
        Future<Rect> capture(int step) async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('toss-scene')),
          );
          final image = await boundary.toImage();
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          await File('${directory.path}/$name-$step.png')
              .writeAsBytes(png.buffer.asUint8List());
          var left = image.width, top = image.height, right = 0, bottom = 0;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final offset = (y * image.width + x) * 4;
              final r = pixels.getUint8(offset),
                  g = pixels.getUint8(offset + 1),
                  b = pixels.getUint8(offset + 2);
              final actor = die
                  ? b > 140 && b > r * 1.35 && b > g * 1.08
                  : r > 185 && g > 100 && b < 170;
              if (!actor) continue;
              if (x < left) left = x;
              if (x > right) right = x;
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
          image.dispose();
          final bounds = Rect.fromLTRB(
            left.toDouble(),
            top.toDouble(),
            right.toDouble(),
            bottom.toDouble(),
          );
          expect(bounds.isEmpty, isFalse);
          expect(bounds.left, greaterThan(0));
          expect(bounds.top, greaterThan(0));
          expect(bounds.right, lessThan(boundary.size.width - 1));
          expect(bounds.bottom, lessThan(boundary.size.height - 1));
          return bounds;
        }

        try {
          await tester.pumpWidget(
            UniPocketApp(
              planner: SemesterPlanner(store),
              random: CandidateRandom([die ? 3 : 0], die ? 6 : 2),
            ),
          );
          await waitFor(tester, find.text('UniPocket'));
          await tapVisible(tester, find.text('工具'));
          await tapVisible(tester, find.text(die ? '掷骰子' : '抛硬币'));
          final ready = await capture(0);
          await tester.tap(find.byKey(const ValueKey('random-action')));
          await tester.pump();
          final duration = die ? 1900 : 1800;
          final frames = <Rect>[];
          var elapsed = 0;
          for (var step = 1; step <= 20; step++) {
            final target = duration * step ~/ 20;
            await tester.pump(Duration(milliseconds: target - elapsed));
            elapsed = target;
            frames.add(await capture(step));
            if (step < 20) expect(find.text('投掷中…'), findsOneWidget);
          }
          // Compare rendered actor positions, rather than an animation object or
          // implementation parameters: a fixed icon with a timer cannot pass.
          // Projected corners constrain the highest cube pose to its safe area.
          expect(frames[7].center.dy, lessThan(ready.center.dy - 40));
          expect(frames[14].center.dy, greaterThan(frames[7].center.dy + 50));
          expect((frames.last.center.dy - ready.center.dy).abs(), lessThan(4));
          final widths = frames.map((r) => r.width).toList()..sort();
          expect(widths.last - widths.first, greaterThan(die ? 15 : 65));
          await tester.pumpAndSettle();
          expect(find.text(die ? '4' : '正面'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }
}
