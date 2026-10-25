import '../semesters/model.dart';

class ScheduleDraft {
  ScheduleDraft({
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required this.location,
    required Set<int> weeks,
  }) : weeks = Set.unmodifiable(weeks);

  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String location;
  final Set<int> weeks;

  void validate(SemesterDraft semester) {
    if (weekday < 1 || weekday > 7) {
      throw const InputProblem('请选择周一至周日。');
    }
    final periods = semester.periods[weekday] ?? [];
    if (startPeriod < 1 ||
        endPeriod < startPeriod ||
        endPeriod > periods.length) {
      throw const InputProblem('起止节次必须按顺序选择，且已在该星期的学期设置中配置。');
    }
    if (weeks.isEmpty || weeks.any((w) => w < 1 || w > semester.totalWeeks)) {
      throw const InputProblem('请至少选择一个教学周，且不能超出学期总周数。');
    }
  }
}

class ClassSchedule extends ScheduleDraft {
  ClassSchedule({
    required this.id,
    required super.weekday,
    required super.startPeriod,
    required super.endPeriod,
    required super.location,
    required super.weeks,
  });
  final int id;
}

class CourseDraft {
  CourseDraft({
    required this.semesterId,
    required this.name,
    this.teacher = '',
    this.colorIndex = 0,
    required List<ScheduleDraft> schedules,
  }) : schedules = List.unmodifiable(schedules);

  final int semesterId;
  final String name;
  final String teacher;
  final int colorIndex;
  final List<ScheduleDraft> schedules;

  void validate(SemesterDraft semester) {
    validateCourseDetails(name, colorIndex);
    if (schedules.isEmpty) throw const InputProblem('请至少添加一个上课安排。');
    for (final schedule in schedules) {
      schedule.validate(semester);
    }
  }
}

void validateCourseDetails(String name, int colorIndex) {
  if (name.trim().isEmpty) throw const InputProblem('请输入课程名称。');
  if (colorIndex < 0) {
    throw const InputProblem('请选择有效的课程颜色。');
  }
}

class CourseConflict extends InputProblem {
  CourseConflict(List<String> conflicts)
    : super('以下上课安排时间冲突，仍要保留吗？\n${conflicts.join('\n')}');
}

List<String> courseConflicts(
  CourseDraft draft,
  Semester semester,
  List<Course> courses,
) {
  final conflicts = <String>[];
  final compared = <(String, ScheduleDraft)>[
    for (final course in courses)
      if (course.semesterId == semester.id)
        for (final schedule in course.schedules) (course.name, schedule),
  ];
  for (final schedule in draft.schedules) {
    final periods = semester.periods[schedule.weekday]!;
    for (final (name, other) in compared) {
      if (schedule.weekday != other.weekday) continue;
      final sharedWeeks = schedule.weeks.intersection(other.weeks).toList()
        ..sort();
      if (sharedWeeks.isEmpty) continue;
      if (periods[schedule.startPeriod - 1].startMinutes <
              periods[other.endPeriod - 1].endMinutes &&
          periods[other.startPeriod - 1].startMinutes <
              periods[schedule.endPeriod - 1].endMinutes) {
        conflicts.add(
          '$name · 周${['一', '二', '三', '四', '五', '六', '日'][schedule.weekday - 1]} · 第 ${sharedWeeks.join('、')} 周 · 第 ${other.startPeriod}–${other.endPeriod} 节',
        );
      }
    }
    compared.add(('本课程的另一上课安排', schedule));
  }
  return conflicts;
}

class Course extends CourseDraft {
  Course({
    required this.id,
    required super.semesterId,
    required super.name,
    required super.teacher,
    required super.colorIndex,
    required List<ClassSchedule> super.schedules,
  });
  final int id;
}

class ClassOccurrence {
  const ClassOccurrence({
    required this.course,
    required this.schedule,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });
  final Course course;
  final ScheduleDraft schedule;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  String get location => schedule.location;
}

/// Dates are campus calendar dates, represented at UTC midnight so device
/// timezone changes and daylight saving transitions cannot shift teaching weeks.
class Timetable {
  Timetable(this.semester, Iterable<Course> courses)
    : courses = List.unmodifiable(
        courses.where((c) => c.semesterId == semester.id),
      );
  final Semester semester;
  final List<Course> courses;

  int weekOf(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final days = day.difference(semester.firstMonday).inDays;
    return (days / 7).floor() + 1;
  }

  DateTime mondayOf(int week) =>
      semester.firstMonday.add(Duration(days: (week - 1) * 7));

  List<ClassOccurrence> onDate(DateTime date) {
    final week = weekOf(date);
    if (week < 1 || week > semester.totalWeeks) return [];
    final day = DateTime.utc(date.year, date.month, date.day);
    final periods = semester.periods[day.weekday] ?? [];
    final result = <ClassOccurrence>[
      for (final course in courses)
        for (final schedule in course.schedules)
          if (schedule.weekday == day.weekday && schedule.weeks.contains(week))
            ClassOccurrence(
              course: course,
              schedule: schedule,
              date: day,
              startMinutes: periods[schedule.startPeriod - 1].startMinutes,
              endMinutes: periods[schedule.endPeriod - 1].endMinutes,
            ),
    ];
    result.sort((a, b) {
      final time = a.startMinutes.compareTo(b.startMinutes);
      return time == 0 ? a.course.id.compareTo(b.course.id) : time;
    });
    return result;
  }

  List<ClassOccurrence> inWeek(int week) => [
    if (week >= 1 && week <= semester.totalWeeks)
      for (var day = 0; day < 7; day++)
        ...onDate(mondayOf(week).add(Duration(days: day))),
  ];
}
