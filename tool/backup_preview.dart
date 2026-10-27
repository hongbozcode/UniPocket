import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:unipocket/app.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

/// Normal Flutter binding for manual inspection of the acceptance database.
/// Does not seed data or touch the production database by default.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(
    UniPocketApp(
      planner: SemesterPlanner(
        PlannerStore.open(
          name: const String.fromEnvironment(
            'ACCEPTANCE_DATABASE',
            defaultValue: 'unipocket_task18_20261027_delivery2',
          ),
        ),
        notifications: const AndroidNotifications(namespace: 'task18'),
      ),
    ),
  );
}
