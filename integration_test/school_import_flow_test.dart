import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/importing/import_page.dart';
import 'package:unipocket/importing/school_import_page.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import '../test/support/widget_actions.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 系统选择真实学校 XLSX、预览、排除备注、保存与再次导入', (tester) async {
    final store = PlannerStore.open(
      name: const String.fromEnvironment(
        'ACCEPTANCE_DATABASE',
        defaultValue: 'unipocket_school_acceptance',
      ),
    );
    final planner = SemesterPlanner(store);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    try {
      if ((await planner.load()).semesters.isEmpty) {
        const times = [
          PeriodTime(480, 525),
          PeriodTime(535, 580),
          PeriodTime(600, 645),
          PeriodTime(655, 700),
          PeriodTime(810, 855),
          PeriodTime(865, 910),
          PeriodTime(930, 975),
          PeriodTime(985, 1030),
          PeriodTime(1050, 1095),
          PeriodTime(1095, 1140),
          PeriodTime(1170, 1215),
          PeriodTime(1215, 1260),
        ];
        await planner.saveSemester(
          SemesterDraft(
            name: '学校导入验收学期',
            firstMonday: DateTime.utc(2026, 8, 31),
            totalWeeks: 20,
            periods: {for (var d = 1; d <= 7; d++) d: times},
          ),
          makeCurrent: true,
        );
      }
      final initial = await planner.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SchoolImportPage(planner: planner),
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await capture('17-android-file-entry');
      await tester.tap(find.byKey(const ValueKey('pick-school-file')));
      await tester.pump();
      debugPrint('TASK17_SELECT_ACTUAL_FILE');
      for (
        var i = 0;
        i < 600 && find.byType(ImportPreviewPage).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ImportPreviewPage), findsOneWidget);
      await tester.pumpAndSettle();
      await capture('17-android-school-preview');
      expect((await planner.load()).courses.length, initial.courses.length);
      if (initial.courses.isEmpty) {
        for (var i = 0; i < 3; i++) {
          await tapVisible(
            tester,
            find.byKey(ValueKey('select-import-remark-$i')),
          );
        }
        await capture('17-android-unresolved-excluded');
        await tapVisible(tester, find.byKey(const ValueKey('confirm-import')));
        await capture('17-android-confirmation');
        await tapVisible(tester, find.byKey(const ValueKey('save-import')));
        await waitFor(tester, find.text('成功加入 10 门课程'));
        await capture('17-android-success');
        expect((await planner.load()).courses, hasLength(10));
      } else {
        expect(find.text('选中 3 门'), findsOneWidget);
        // The three unscheduled remarks remain unresolved. Scheduled courses
        // are all automatically skipped; no second save is possible.
        for (var i = 0; i < 3; i++) {
          await tapVisible(
            tester,
            find.byKey(ValueKey('select-import-remark-$i')),
          );
        }
        await capture('17-android-repeat-skipped');
        await tester.ensureVisible(
          find.byKey(const ValueKey('confirm-import')),
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirm-import')),
              )
              .onPressed,
          isNull,
        );
        final repeated = await planner.load();
        expect(repeated.courses.length, initial.courses.length);
        expect(
          repeated.courses.fold<int>(0, (n, c) => n + c.schedules.length),
          initial.courses.fold<int>(0, (n, c) => n + c.schedules.length),
        );
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      await store.close();
    }
  });
}
