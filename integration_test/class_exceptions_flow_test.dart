import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/class_exception_flow.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_exceptions_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');
const phoneOffset = int.fromEnvironment(
  'ACCEPTANCE_PHONE_OFFSET',
  defaultValue: 480,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets(restore ? 'Android 新进程恢复跨周调课与停课' : 'Android 单次调课与停课真实操作', (
    tester,
  ) async {
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
      expect(
        DateTime.utc(2026, 10, 23).toLocal().timeZoneOffset.inMinutes,
        phoneOffset,
      );
      if (!restore) await seedExceptionCourses(planner);
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          clock: () => DateTime.utc(2026, 10, 22, 23).toLocal(),
        ),
      );
      if (restore) {
        await verifyExceptionRestoration(tester, planner, capture: capture);
      } else {
        await runExceptionCreation(tester, planner, capture: capture);
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
