import 'package:unipocket/importing/model.dart';
import 'package:unipocket/timetable/model.dart';

// Synthetic candidates only: no school parser, row locator or identity rules.
ImportCandidate testCandidate(
  String name, {
  String? id,
  int day = 1,
  int start = 1,
  Set<int> weeks = const {1},
  List<String> errors = const [],
  String? duplicate,
  bool? selected,
}) => ImportCandidate(
  id: id ?? name,
  sourceLabel: '示例课程数据（仅用于测试）',
  name: name,
  errors: errors,
  duplicateDescription: duplicate,
  selected: selected,
  schedules: [
    ScheduleDraft(
      weekday: day,
      startPeriod: start,
      endPeriod: start,
      location: '测试教室',
      weeks: weeks,
    ),
  ],
);
