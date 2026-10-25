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
  List<Course> courses, [
  List<ClassExceptionDraft> classExceptions = const [],
]) {
  final timetable = Timetable(semester, courses, classExceptions);
  final compared = <ClassOccurrence>[];
  final conflicts = <String>{};
  for (final schedule in draft.schedules) {
    final periods = semester.periods[schedule.weekday]!;
    for (final week in schedule.weeks) {
      final date = timetable
          .mondayOf(week)
          .add(Duration(days: schedule.weekday - 1));
      final start = periods[schedule.startPeriod - 1].startMinutes;
      final end = periods[schedule.endPeriod - 1].endMinutes;
      for (final other in [
        ...timetable.onDate(date),
        ...compared.where((o) => o.date == date),
      ]) {
        if (start < other.endMinutes && other.startMinutes < end) {
          conflicts.add(
            '${other.course.name} · ${date.year}-${date.month}-${date.day} · ${PeriodTime.format(other.startMinutes)}–${PeriodTime.format(other.endMinutes)}',
          );
        }
      }
      compared.add(
        ClassOccurrence(
          course: Course(
            id: -1,
            semesterId: draft.semesterId,
            name: '本课程的另一上课安排',
            teacher: draft.teacher,
            colorIndex: draft.colorIndex,
            schedules: [],
          ),
          schedule: schedule,
          date: date,
          startMinutes: start,
          endMinutes: end,
        ),
      );
    }
  }
  return conflicts.toList();
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
    this.sourceDate,
    this.overrideLocation,
  });
  final Course course;
  final ScheduleDraft schedule;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final DateTime? sourceDate;
  final String? overrideLocation;
  DateTime get originalDate => sourceDate ?? date;
  bool get isRescheduled => sourceDate != null;
  String get location => overrideLocation ?? schedule.location;
}

/// An exception is keyed by the original schedule and campus calendar date,
/// never by its destination. Two lessons of one schedule can share a date.
class ClassExceptionDraft {
  ClassExceptionDraft({
    required this.scheduleId,
    required DateTime originalDate,
    required DateTime targetDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.location,
    this.isCancelled = false,
  }) : originalDate = DateTime.utc(
         originalDate.year,
         originalDate.month,
         originalDate.day,
       ),
       targetDate = DateTime.utc(
         targetDate.year,
         targetDate.month,
         targetDate.day,
       );

  final int scheduleId;
  final DateTime originalDate;
  final DateTime targetDate;
  final int startMinutes;
  final int endMinutes;
  final String location;
  final bool isCancelled;

  void validate() {
    if (targetDate.year < 1900 || targetDate.year > 2200) {
      throw const InputProblem('请选择 1900–2200 年内的日期。');
    }
    if (startMinutes < 0 || endMinutes >= 1440 || startMinutes >= endMinutes) {
      throw const InputProblem('结束时间须晚于开始时间，且须在同一天内。');
    }
  }
}

/// Dates are campus calendar dates, represented at UTC midnight so device
/// timezone changes and daylight saving transitions cannot shift teaching weeks.
class Timetable {
  Timetable(
    this.semester,
    Iterable<Course> courses, [
    Iterable<ClassExceptionDraft> classExceptions = const [],
  ]) : courses = List.unmodifiable(
         courses.where((c) => c.semesterId == semester.id),
       ),
       classExceptions = List.unmodifiable(classExceptions);
  final Semester semester;
  final List<Course> courses;
  final List<ClassExceptionDraft> classExceptions;

  int weekOf(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final days = day.difference(semester.firstMonday).inDays;
    return (days / 7).floor() + 1;
  }

  DateTime mondayOf(int week) =>
      semester.firstMonday.add(Duration(days: (week - 1) * 7));

  Iterable<int> get _exceptionWeeks sync* {
    final scheduleIds = courses
        .expand((c) => c.schedules)
        .whereType<ClassSchedule>()
        .map((s) => s.id)
        .toSet();
    for (final exception in classExceptions) {
      if (!exception.isCancelled &&
          scheduleIds.contains(exception.scheduleId)) {
        yield weekOf(exception.targetDate);
      }
    }
  }

  int get firstVisibleWeek =>
      [1, ..._exceptionWeeks].reduce((a, b) => a < b ? a : b);
  int get lastVisibleWeek =>
      [semester.totalWeeks, ..._exceptionWeeks].reduce((a, b) => a > b ? a : b);

  List<ClassOccurrence> onDate(DateTime date) {
    final week = weekOf(date);
    final day = DateTime.utc(date.year, date.month, date.day);
    final periods = semester.periods[day.weekday] ?? [];
    final result = <ClassOccurrence>[
      for (final course in courses)
        for (final schedule in course.schedules)
          if (schedule.weekday == day.weekday &&
              schedule.weeks.contains(week) &&
              !classExceptions.any(
                (e) =>
                    schedule is ClassSchedule &&
                    e.scheduleId == schedule.id &&
                    e.originalDate == day,
              ))
            ClassOccurrence(
              course: course,
              schedule: schedule,
              date: day,
              startMinutes: periods[schedule.startPeriod - 1].startMinutes,
              endMinutes: periods[schedule.endPeriod - 1].endMinutes,
            ),
      for (final course in courses)
        for (final schedule in course.schedules)
          for (final exception in classExceptions)
            if (schedule is ClassSchedule &&
                exception.scheduleId == schedule.id &&
                !exception.isCancelled &&
                exception.targetDate == day)
              ClassOccurrence(
                course: course,
                schedule: schedule,
                date: day,
                sourceDate: exception.originalDate,
                startMinutes: exception.startMinutes,
                endMinutes: exception.endMinutes,
                overrideLocation: exception.location,
              ),
    ];
    result.sort((a, b) {
      final time = a.startMinutes.compareTo(b.startMinutes);
      return time == 0 ? a.course.id.compareTo(b.course.id) : time;
    });
    return result;
  }

  List<ClassOccurrence> inWeek(int week) => [
    if (week >= firstVisibleWeek && week <= lastVisibleWeek)
      for (var day = 0; day < 7; day++)
        ...onDate(mondayOf(week).add(Duration(days: day))),
  ];
}
