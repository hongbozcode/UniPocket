import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';

import '../test/support/widget_actions.dart';

// Design comparison data only. It never enters the normal application database.
const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_visual_comparison',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('参考图的第 8 周与五门课程在 Android 实际渲染，录课颜色预览可见', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    try {
      final semester = await planner.saveSemester(
        SemesterDraft(
          name: '2026 秋季学期',
          firstMonday: DateTime.utc(2026, 8, 31),
          totalWeeks: 20,
          periods: {
            for (var day = 1; day <= 7; day++)
              day: [
                const PeriodTime(480, 525),
                const PeriodTime(535, 580),
                const PeriodTime(600, 645),
                const PeriodTime(655, 700),
                const PeriodTime(840, 885),
                const PeriodTime(895, 940),
                const PeriodTime(960, 1005),
                const PeriodTime(1015, 1060),
              ],
          },
        ),
      );
      ScheduleDraft schedule(int day, int start, int end, String location) =>
          ScheduleDraft(
            weekday: day,
            startPeriod: start,
            endPeriod: end,
            location: location,
            weeks: {for (var week = 1; week <= 20; week++) week},
          );
      final samples = [
        ('高等数学', 0, [schedule(1, 1, 2, 'A201'), schedule(5, 1, 2, 'A201')]),
        ('程序设计', 1, [schedule(3, 1, 2, '机房203')]),
        ('大学物理', 2, [schedule(2, 3, 4, 'C103')]),
        ('体育', 3, [schedule(4, 5, 6, '体育馆')]),
        ('大学英语', 4, [schedule(5, 5, 6, 'B302')]),
      ];
      for (final (name, color, schedules) in samples) {
        await planner.saveCourse(
          CourseDraft(
            semesterId: semester,
            name: name,
            colorIndex: color,
            schedules: schedules,
          ),
        );
      }
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          clock: () => DateTime.utc(2026, 10, 22, 23),
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02-reference-home');
      await tapVisible(tester, find.text('课表'));
      expect(find.text('第 8 周'), findsOneWidget);
      expect(find.text('体育'), findsOneWidget);
      expect(find.text('大学物理'), findsOneWidget);
      await binding.takeScreenshot('02-reference-week');
      await tapVisible(tester, find.byTooltip('添加课程'));
      await tester.enterText(find.byKey(const ValueKey('course-name')), '离散数学');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02-course-color-preview');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
