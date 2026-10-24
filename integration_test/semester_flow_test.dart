import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

// Use the same database name for both stages, but a fresh name for each run.
// The second flutter drive invocation launches a new Android process.
const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_acceptance',
);
const restoreStage = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  testWidgets(
    restoreStage ? '新 Android 进程恢复所有学期和校园时区' : 'Android 用户操作保存学期与校园时区',
    (tester) async {
      final store = PlannerStore.open(name: databaseName);
      try {
        await tester.pumpWidget(UniPocketApp(planner: SemesterPlanner(store)));
        await tester.pumpAndSettle();
        if (!restoreStage) {
          await tester.tap(find.text('创建学期'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('semester-name')),
            'Android 验收秋季学期',
          );
          await tester.enterText(
            find.byKey(const ValueKey('first-monday')),
            '2026-08-31',
          );
          await tester.enterText(
            find.byKey(const ValueKey('total-weeks')),
            '20',
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('save-semester')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('save-semester')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('save-semester')));
          await tester.pumpAndSettle();
          expect(find.text('Android 验收秋季学期'), findsOneWidget);
          await tester.tap(find.text('设置'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('校园时区'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('校园时区'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('timezone-search')),
            'Asia/Tokyo',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ListTile, 'Asia/Tokyo'));
          await tester.pumpAndSettle();
        } else {
          expect(find.text('Android 验收秋季学期'), findsOneWidget);
          expect(find.textContaining('Asia/Tokyo'), findsWidgets);
          expect(find.textContaining('2026-08-31'), findsWidgets);
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          await binding.convertFlutterSurfaceToImage();
          await tester.pumpAndSettle();
        }
        await binding.takeScreenshot(
          restoreStage ? 'android-process-restored' : 'android-settings-saved',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    },
  );
}
