import 'package:unipocket/semesters/model.dart';

SemesterDraft semesterDraft(String name) => SemesterDraft(
  name: name,
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
);
