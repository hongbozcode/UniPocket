import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/roll_call.dart';
import 'package:unipocket/random_tools/roll_call_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/roll_call_random.dart';
import 'support/widget_actions.dart';

void main() {
  testWidgets('点名纵向滚动有连续绘制变化，1.4秒落定后姓名和备注才提交', (tester) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      final output = Directory('build/roll-call-preview')
        ..createSync(recursive: true);
      Future<int> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('roll-call-scene')),
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
        await planner.saveRollCallList(
          name: '学习小组',
          members: [
            const RollCallMember(id: 1, name: '林晓', detail: '0112'),
            const RollCallMember(id: 2, name: '顾言', detail: '0103'),
            const RollCallMember(id: 3, name: '许诺', detail: '0004'),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: RollCallPage(
              planner: planner,
              random: RollCallRandom([(3, 2)]),
            ),
          ),
        );
        await waitFor(tester, find.text('学习小组 · 3人'));
        final action = find.byKey(const ValueKey('roll-call-draw'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await capture('ready');
        await tester.tap(action);
        for (
          var i = 0;
          i < 100 && find.text('名字滚动中…').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pump();
        final frames = <int>{};
        var previous = 0;
        for (final at in [0, 150, 450, 900, 1300, 1399]) {
          await tester.pump(Duration(milliseconds: at - previous));
          frames.add(await capture('rolling-$at'));
          expect(find.text('名字滚动中…'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('roll-call-identification')),
            findsNothing,
          );
          expect((await planner.loadRollCallLists()).single.drawn, isEmpty);
          previous = at;
        }
        expect(frames.length, greaterThan(3));
        await tester.pump(const Duration(milliseconds: 1));
        await waitFor(tester, find.text('本次抽中'));
        await tester.pumpAndSettle();
        await capture('landed');
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey('roll-call-result')),
              )
              .data,
          '许诺',
        );
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey('roll-call-identification')),
              )
              .data,
          '0004',
        );
        expect((await planner.loadRollCallLists()).single.drawn, [3]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}
