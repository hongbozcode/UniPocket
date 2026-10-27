import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

/// Normal binding for manual interaction with the isolated acceptance database.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(
    UniPocketApp(
      planner: SemesterPlanner(
        PlannerStore.open(
          name: const String.fromEnvironment(
            'IMPORT_PREVIEW_DATABASE',
            defaultValue: 'unipocket_task17_20261027_delivery',
          ),
        ),
        notifications: const AndroidNotifications(),
      ),
      clock: () => DateTime.utc(2026, 10, 27, 0, 15),
    ),
  );
}
