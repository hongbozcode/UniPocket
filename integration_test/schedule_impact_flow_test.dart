import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/schedule_impact_flow.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_impact_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets(
    restore ? 'Android 新进程恢复安排变更、独立补课及保留的 DDL' : 'Android 安排影响、冲突和课程删除完整操作',
    (tester) async {
      final store = PlannerStore.open(name: databaseName);
      final planner = SemesterPlanner(store);
      var converted = false;
      Future<void> capture(String name) async {
        if (defaultTargetPlatform == TargetPlatform.android && !converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
          await tester.pumpAndSettle();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await binding.takeScreenshot(name);
      }

      try {
        if (!restore) await seedScheduleImpact(planner);
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 10, 25, 23),
          ),
        );
        if (restore) {
          await verifyScheduleImpactRestoration(
            tester,
            planner,
            capture: capture,
          );
        } else {
          await runScheduleImpactCreation(tester, planner, capture: capture);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    },
  );
}
