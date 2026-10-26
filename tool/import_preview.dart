import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/importing/model.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';

/// Manual Android preview, deliberately separate from the automated test
/// binding and the normal application's database. The overlapping lessons
/// demonstrate that conflicts can be explicitly retained during import.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  const database = String.fromEnvironment(
    'IMPORT_PREVIEW_DATABASE',
    defaultValue: 'unipocket_import_manual_preview',
  );
  final store = PlannerStore.open(name: database);
  final planner = SemesterPlanner(
    store,
    notifications: const AndroidNotifications(),
  );
  await store.transaction(() async {
    if ((await planner.load()).semesters.isEmpty) {
      final semester = await planner.saveSemester(
        SemesterDraft(
          name: '导入演示学期（测试数据）',
          firstMonday: DateTime.utc(2026, 8, 31),
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
      ScheduleDraft schedule() => ScheduleDraft(
        weekday: 1,
        startPeriod: 1,
        endPeriod: 1,
        location: '测试教室',
        weeks: {1},
      );
      // The two overlapping courses are committed together, just as in the
      // preview flow. These are explicit demo data, not a school template.
      final preview = await planner.previewImport(
        ImportDraft(
          semesterId: semester,
          candidates: [
            ImportCandidate(
              id: 'existing',
              sourceLabel: '手动演示数据',
              name: '测试原有课程',
              schedules: [schedule()],
            ),
            ImportCandidate(
              id: 'imported',
              sourceLabel: '手动演示数据',
              name: '测试导入数学',
              colorIndex: 1,
              schedules: [schedule()],
            ),
          ],
        ),
      );
      await preview.commit(allowConflicts: true);
    }
  });
  runApp(
    UniPocketApp(
      planner: planner,
      clock: () => DateTime.utc(2026, 8, 31, 0, 15),
    ),
  );
}
