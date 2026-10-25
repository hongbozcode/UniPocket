import 'package:timezone/timezone.dart' as tz;

import '../semesters/model.dart';
import '../timetable/model.dart';
import 'notifications.dart';

DateTime? courseReminderAt(ClassOccurrence occurrence, String zone) {
  final lead = occurrence.course.reminderMinutesBefore;
  if (lead == null) return null;
  final date = occurrence.date;
  return tz.TZDateTime(
    tz.getLocation(zone),
    date.year,
    date.month,
    date.day,
    occurrence.startMinutes ~/ 60,
    occurrence.startMinutes % 60,
  ).toUtc().subtract(Duration(minutes: lead));
}

/// Enumerate actual dates, including makeups outside the teaching calendar.
/// Use the timetable's effective instances so cancellations never reappear.
List<ClassOccurrence> currentCourseOccurrences(PlannerState state) {
  final semester = state.currentSemester;
  if (semester == null) return [];
  final timetable = Timetable(
    semester,
    state.courses,
    state.classExceptions,
    state.independentLessons,
  );
  final scheduleIds = timetable.courses
      .expand((c) => c.schedules)
      .whereType<ClassSchedule>()
      .map((s) => s.id)
      .toSet();
  final dates = <DateTime>{
    for (final course in timetable.courses)
      for (final schedule in course.schedules)
        for (final week in schedule.weeks)
          timetable.mondayOf(week).add(Duration(days: schedule.weekday - 1)),
    for (final exception in state.classExceptions)
      if (!exception.isCancelled && scheduleIds.contains(exception.scheduleId))
        exception.targetDate,
    for (final lesson in state.independentLessons)
      if (timetable.courses.any((c) => c.id == lesson.courseId)) lesson.date,
  }.toList()..sort();
  return [for (final date in dates) ...timetable.onDate(date)];
}

List<LocalReminder> futureCourseReminders(PlannerState state, DateTime now) => [
  for (final occurrence in currentCourseOccurrences(state))
    if (courseReminderAt(occurrence, state.campusTimeZone) case final at?
        when at.isAfter(now.toUtc()))
      LocalReminder(
        key: occurrence.isIndependent
            ? 'independent:${occurrence.independentLessonId}'
            : 'class:${(occurrence.schedule as ClassSchedule).id}:${occurrence.originalDate.toIso8601String()}',
        at: at,
        title: occurrence.course.name,
        body: _lessonMessage(occurrence),
      ),
];

String _lessonMessage(ClassOccurrence occurrence) {
  final time =
      '${occurrence.date.month}月${occurrence.date.day}日 ${PeriodTime.format(occurrence.startMinutes)}';
  final message = occurrence.isIndependent
      ? '补课时间：$time'
      : occurrence.isRescheduled
      ? '已调至 $time'
      : '$time 上课';
  return '$message${occurrence.location.isEmpty ? '' : '，地点：${occurrence.location}'}。';
}
