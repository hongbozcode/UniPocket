import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/groups.dart';
import 'package:unipocket/random_tools/groups_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/widget_actions.dart';

void main() {
  testWidgets('800ms洗牌后逐张发牌，1865ms完成且临时名签清理', (tester) async {
    tester.view.physicalSize = const Size(393, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      final output = Directory('build/groups-preview')
        ..createSync(recursive: true);
      Future<int> capture(String name) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('group-scene')),
        );
        final frame = await boundary.toImage();
        final bytes = (await frame.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        frame.dispose();
        return Object.hashAll(bytes);
      }

      try {
        await planner.saveGroupList(
          name: '名单',
          members: [
            for (var i = 1; i <= 10; i++) GroupMember(id: i, name: '伙伴$i'),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: GroupsPage(planner: planner, random: Random(14)),
          ),
        );
        await waitFor(tester, find.text('名单 · 10人'));
        await tester.tap(find.byKey(const ValueKey('group-start')));
        for (
          var i = 0;
          i < 100 && find.text('先洗洗牌，再认识新的伙伴').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pump();
        var previous = 0;
        final hashes = <int>{};
        for (final at in [0, 200, 500, 799, 800, 950, 1200, 1800, 1864]) {
          await tester.pump(Duration(milliseconds: at - previous));
          hashes.add(await capture('dealing-$at'));
          expect(find.byKey(const ValueKey('group-result')), findsNothing);
          previous = at;
        }
        expect(hashes.length, greaterThan(5));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('group-result')), findsOneWidget);
        expect(find.text('10 张姓名牌'), findsNothing);
        expect(find.text('取消分组'), findsNothing);
        for (var i = 1; i <= 10; i++) {
          expect(find.text('伙伴$i'), findsOneWidget);
        }
        await capture('landed');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await store.close();
      }
    });
  });
}
