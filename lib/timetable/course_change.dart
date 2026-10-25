import 'dart:convert';

import '../semesters/model.dart';
import 'model.dart';

enum OrphanChoice { keepIndependent, delete }

class CourseChangeImpact {
  CourseChangeImpact({
    required this.course,
    required this.draft,
    required this.semester,
    required this.revision,
    required List<ClassExceptionDraft> retained,
    required List<ClassExceptionDraft> orphaned,
  }) : retained = List.unmodifiable(retained),
       orphaned = List.unmodifiable(orphaned);
  final Course course;
  final CourseDraft draft;
  final Semester semester;
  final String revision;
  final List<ClassExceptionDraft> retained;
  final List<ClassExceptionDraft> orphaned;
}

CourseChangeImpact courseChangeImpact(
  PlannerState state,
  int id,
  CourseDraft draft,
) {
  final course = state.courses.where((c) => c.id == id).firstOrNull;
  if (course == null) throw const InputProblem('课程不存在，请返回后重试。');
  if (draft.semesterId != course.semesterId) {
    throw const InputProblem('不能将课程移动到其他学期。');
  }
  final semester = state.semesters.singleWhere(
    (s) => s.id == course.semesterId,
  );
  draft.validate(semester);
  final existingIds = course.schedules
      .cast<ClassSchedule>()
      .map((s) => s.id)
      .toSet();
  final proposedIds = draft.schedules
      .whereType<ClassSchedule>()
      .map((s) => s.id)
      .toList();
  if (proposedIds.toSet().length != proposedIds.length ||
      proposedIds.any((id) => !existingIds.contains(id))) {
    throw const InputProblem('上课安排已变更，请返回后重新编辑。');
  }
  final retained = <ClassExceptionDraft>[];
  final orphaned = <ClassExceptionDraft>[];
  for (final exception in state.classExceptions.where(
    (e) => existingIds.contains(e.scheduleId),
  )) {
    final schedule = draft.schedules
        .whereType<ClassSchedule>()
        .where((s) => s.id == exception.scheduleId)
        .firstOrNull;
    final week = Timetable(semester, []).weekOf(exception.originalDate);
    (schedule != null &&
                schedule.weekday == exception.originalDate.weekday &&
                schedule.weeks.contains(week)
            ? retained
            : orphaned)
        .add(exception);
  }
  return CourseChangeImpact(
    course: course,
    draft: draft,
    semester: semester,
    revision: courseRevision(state, course),
    retained: retained,
    orphaned: orphaned,
  );
}

/// Reject stale previews instead of applying decisions to a different set of lessons.
String courseRevision(
  PlannerState state,
  Course course, {
  bool includeTasks = false,
}) {
  final semester = state.semesters.singleWhere(
    (s) => s.id == course.semesterId,
  );
  final ids = course.schedules.cast<ClassSchedule>().map((s) => s.id).toSet();
  return jsonEncode([
    course.id,
    course.name,
    course.teacher,
    course.colorIndex,
    semester.firstMonday.toIso8601String(),
    semester.totalWeeks,
    [
      for (final entry in semester.periods.entries)
        [
          entry.key,
          for (final p in entry.value) [p.startMinutes, p.endMinutes],
        ],
    ],
    [
      for (final s in course.schedules.cast<ClassSchedule>())
        [
          s.id,
          s.weekday,
          s.startPeriod,
          s.endPeriod,
          s.location,
          s.weeks.toList()..sort(),
        ],
    ],
    [
      for (final e in state.classExceptions.where(
        (e) => ids.contains(e.scheduleId),
      ))
        [
          e.scheduleId,
          e.originalDate.toIso8601String(),
          e.targetDate.toIso8601String(),
          e.startMinutes,
          e.endMinutes,
          e.location,
          e.isCancelled,
        ],
    ],
    [
      for (final l in state.independentLessons.where(
        (l) => l.courseId == course.id,
      ))
        [
          l.id,
          l.date.toIso8601String(),
          l.startMinutes,
          l.endMinutes,
          l.location,
        ],
    ],
    if (includeTasks)
      [for (final t in state.tasks.where((t) => t.courseId == course.id)) t.id],
  ]);
}

class CourseDeletionImpact {
  const CourseDeletionImpact({
    required this.course,
    required this.exceptionCount,
    required this.independentCount,
    required this.taskCount,
    required this.revision,
  });
  final Course course;
  final int exceptionCount;
  final int independentCount;
  final int taskCount;
  final String revision;
}

/// Compare the final effective lessons, including moves and independent makeups.
List<String> effectiveCourseConflicts(Timetable timetable, int courseId) {
  final dates = <DateTime>{};
  for (final course in timetable.courses.where((c) => c.id == courseId)) {
    for (final schedule in course.schedules) {
      for (final week in schedule.weeks) {
        dates.add(
          timetable.mondayOf(week).add(Duration(days: schedule.weekday - 1)),
        );
      }
    }
  }
  dates.addAll(
    timetable.classExceptions
        .where((e) => !e.isCancelled)
        .map((e) => e.targetDate),
  );
  dates.addAll(
    timetable.independentLessons
        .where((l) => l.courseId == courseId)
        .map((l) => l.date),
  );
  final conflicts = <String>{};
  for (final date in dates) {
    final lessons = timetable.onDate(date);
    for (var i = 0; i < lessons.length; i++) {
      for (var j = i + 1; j < lessons.length; j++) {
        final a = lessons[i], b = lessons[j];
        if ((a.course.id == courseId || b.course.id == courseId) &&
            a.startMinutes < b.endMinutes &&
            b.startMinutes < a.endMinutes) {
          conflicts.add(
            '${a.course.name} / ${b.course.name} · ${date.year}-${date.month}-${date.day} · '
            '${PeriodTime.format(a.startMinutes)}–${PeriodTime.format(a.endMinutes)} / '
            '${PeriodTime.format(b.startMinutes)}–${PeriodTime.format(b.endMinutes)}',
          );
        }
      }
    }
  }
  return conflicts.toList();
}
