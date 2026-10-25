import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_timetable_acceptance',
);
const restoreStage = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets(
    restoreStage ? '新 Android 进程恢复课程、多安排与确认的冲突课程' : 'Android 手动录课、多个安排与冲突确认',
    (tester) async {
      final store = PlannerStore.open(name: databaseName);
      final planner = SemesterPlanner(store);
      var surfaceConverted = false;
      Future<void> tap(Finder finder) => tapVisible(tester, finder);

      Future<void> screenshot(String name) async {
        if (defaultTargetPlatform == TargetPlatform.android &&
            !surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
          await tester.pumpAndSettle();
        }
        await binding.takeScreenshot(name);
      }

      try {
        if (!restoreStage) {
          await planner.saveSemester(
            SemesterDraft(
              name: 'Android 课表验收学期',
              firstMonday: DateTime.utc(2026, 10, 19),
              totalWeeks: 20,
              periods: {
                for (var day = 1; day <= 7; day++)
                  day: [
                    const PeriodTime(480, 525),
                    const PeriodTime(535, 580),
                    const PeriodTime(600, 645),
                  ],
              },
            ),
          );
        }
        // A controlled clock makes the same Monday visible in both processes.
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 10, 19),
          ),
        );
        await tester.pumpAndSettle();
        if (!restoreStage) {
          await tap(find.text('添加课程'));
          await tester.enterText(
            find.byKey(const ValueKey('course-name')),
            '高等数学与数学分析',
          );
          await tester.enterText(
            find.byKey(const ValueKey('course-teacher')),
            '李老师',
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-location-0')),
            '数学楼 A201',
          );
          await tap(find.text('单周').first);
          await tap(find.text('添加上课安排'));
          await tap(find.byKey(const ValueKey('schedule-day-1')));
          await tap(find.text('周三').last);
          await tester.ensureVisible(
            find.byKey(const ValueKey('schedule-start-1')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-start-1')),
            '3',
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-end-1')),
            '3',
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-location-1')),
            '实验楼 B302',
          );
          await tap(find.text('双周').last);
          await tap(find.byKey(const ValueKey('save-course')));
          expect(find.text('高等数学与数学分析'), findsOneWidget);
          await screenshot('02-android-today-saved');
          await tap(find.text('添加课程'));
          await tester.enterText(
            find.byKey(const ValueKey('course-name')),
            '保留的冲突课程',
          );
          await tap(find.byKey(const ValueKey('save-course')));
          expect(find.text('上课时间冲突'), findsOneWidget);
          await screenshot('02-android-conflict');
          await tap(find.text('仍然保存'));
        }
        final state = await planner.load();
        expect(state.courses, hasLength(2));
        final math = state.courses.singleWhere((c) => c.name == '高等数学与数学分析');
        expect(math.teacher, '李老师');
        expect(math.schedules, hasLength(2));
        expect(math.schedules.first.location, '数学楼 A201');
        expect(math.schedules.last.location, '实验楼 B302');
        expect(math.schedules.first.weeks, {1, 3, 5, 7, 9, 11, 13, 15, 17, 19});
        expect(math.schedules.last.weeks, {2, 4, 6, 8, 10, 12, 14, 16, 18, 20});
        expect(state.today(DateTime.utc(2026, 10, 19)), hasLength(2));
        expect(find.text('高等数学与数学分析'), findsOneWidget);
        if (restoreStage) await screenshot('02-android-process-restored');
        await tap(find.text('课表'));
        await tap(find.byTooltip('下一周'));
        expect(find.text('第 2 周'), findsOneWidget);
        await screenshot(
          restoreStage ? '02-android-week-restored' : '02-android-week-saved',
        );
        await tap(find.text('今日'));
        expect(find.text('高等数学与数学分析'), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    },
  );
}
