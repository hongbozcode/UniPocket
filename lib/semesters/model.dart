import 'package:timezone/timezone.dart' as tz;

import '../timetable/model.dart';
import '../tasks/model.dart';
import '../events/model.dart';

class PeriodTime {
  const PeriodTime(this.startMinutes, this.endMinutes);

  final int startMinutes;
  final int endMinutes;

  static String format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class SemesterDraft {
  SemesterDraft({
    required this.name,
    required DateTime firstMonday,
    required this.totalWeeks,
    required Map<int, List<PeriodTime>> periods,
  }) : firstMonday = DateTime.utc(
         firstMonday.year,
         firstMonday.month,
         firstMonday.day,
       ),
       periods = Map.unmodifiable({
         for (final entry in periods.entries)
           entry.key: List<PeriodTime>.unmodifiable(entry.value),
       });

  final String name;
  final DateTime firstMonday;
  final int totalWeeks;
  final Map<int, List<PeriodTime>> periods;

  void validate() {
    if (name.trim().isEmpty) throw const InputProblem('请输入学期名称。');
    if (firstMonday.weekday != DateTime.monday) {
      throw const InputProblem('第 1 教学周的起始日期必须是周一。');
    }
    if (totalWeeks < 1) throw const InputProblem('总周数必须为正整数。');
    if (periods.values.every((day) => day.isEmpty)) {
      throw const InputProblem('请至少配置一天的一个节次。');
    }
    for (final entry in periods.entries) {
      if (entry.key < 1 || entry.key > 7) throw const InputProblem('请选择周一至周日。');
      var previousEnd = -1;
      for (var i = 0; i < entry.value.length; i++) {
        final period = entry.value[i];
        final label =
            '周${['一', '二', '三', '四', '五', '六', '日'][entry.key - 1]}第 ${i + 1} 节';
        if (period.startMinutes < 0 ||
            period.endMinutes >= 1440 ||
            period.startMinutes >= period.endMinutes) {
          throw InputProblem('$label：时间须在当天内，结束时间须晚于开始时间。');
        }
        if (period.startMinutes < previousEnd) {
          throw InputProblem('$label：节次须按时间排序，且不能与上一节重叠。');
        }
        previousEnd = period.endMinutes;
      }
    }
  }
}

class Semester extends SemesterDraft {
  Semester({
    required this.id,
    required super.name,
    required super.firstMonday,
    required super.totalWeeks,
    required super.periods,
  });

  final int id;
}

class PlannerState {
  PlannerState({
    required List<Semester> semesters,
    required this.currentSemesterId,
    required this.campusTimeZone,
    List<Course> courses = const [],
    List<LearningTask> tasks = const [],
    List<CountdownEvent> events = const [],
  }) : semesters = List.unmodifiable(semesters),
       tasks = List.unmodifiable(tasks),
       events = List.unmodifiable(events),
       courses = List.unmodifiable(courses);

  final List<Semester> semesters;
  final int? currentSemesterId;
  final String campusTimeZone;
  final List<Course> courses;
  final List<LearningTask> tasks;
  final List<CountdownEvent> events;

  Timetable? get timetable =>
      currentSemester == null ? null : Timetable(currentSemester!, courses);

  List<ClassOccurrence> today(DateTime instant) =>
      timetable?.onDate(campusTime(instant)) ?? [];

  Semester? get currentSemester {
    for (final semester in semesters) {
      if (semester.id == currentSemesterId) return semester;
    }
    return null;
  }

  tz.TZDateTime campusTime(DateTime instant) =>
      tz.TZDateTime.from(instant, tz.getLocation(campusTimeZone));
}

class InputProblem implements Exception {
  const InputProblem(this.message);
  final String message;
  @override
  String toString() => message;
}
