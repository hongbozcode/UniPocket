import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app.dart';
import 'semesters/planner.dart';
import 'storage/planner_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(UniPocketApp(planner: SemesterPlanner(PlannerStore.open())));
}
