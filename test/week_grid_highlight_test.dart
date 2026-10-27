import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/timetable/week_grid.dart';
import 'package:unipocket/ui/design.dart';

void main() {
  testWidgets('今日课程结束后的空课时与其他日期底色一致，日期仍可辨认', (tester) async {
    tester.view.physicalSize = const Size(393, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semester = Semester(
      id: 1,
      name: '秋季',
      firstMonday: DateTime.utc(2026, 8, 31),
      totalWeeks: 20,
      periods: {
        for (var d = 1; d <= 7; d++)
          d: [
            for (var p = 0; p < 12; p++) PeriodTime(480 + p * 50, 525 + p * 50),
          ],
      },
    );
    final course = Course.fromDraft(
      1,
      CourseDraft(
        semesterId: 1,
        name: '职业教育学',
        colorIndex: 2,
        schedules: [
          ScheduleDraft(
            weekday: 2,
            startPeriod: 7,
            endPeriod: 8,
            location: 'B303',
            weeks: {9},
          ),
        ],
      ),
    );
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: WeekGrid(
              timetable: Timetable(semester, [course]),
              week: 9,
              today: DateTime.utc(2026, 10, 27),
              onEdit: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('职业教育学'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('周二 2026-10-27 今天')), findsOneWidget);
    final grid = tester.getRect(find.byKey(const ValueKey('week-grid')));
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final origin = boundary.localToGlobal(Offset.zero);
      // Sample well inside the empty final cell, away from borders and text.
      // The timetable's seven weekday headers provide actual column positions.
      int pixelAt(Offset position) {
        final p = position - origin;
        return pixels.getUint32(
          (p.dy.floor() * image.width + p.dx.floor()) * 4,
        );
      }

      final todayX = tester
          .getCenter(find.bySemanticsLabel(RegExp('周二 2026-10-27 今天')))
          .dx;
      final otherX = tester
          .getCenter(find.bySemanticsLabel(RegExp('周三 2026-10-28')))
          .dx;
      final emptyY = grid.bottom - 20;
      expect(
        pixelAt(Offset(todayX, emptyY)),
        pixelAt(Offset(otherX, emptyY)),
        reason: '无课时应保持统一底色，不能在课程下方留下整列紫色区域',
      );
      image.dispose();
    });
  });
}
