import 'package:timezone/timezone.dart' as tz;

import '../events/model.dart';
import '../semesters/model.dart';
import 'notifications.dart';

DateTime? eventReminderAt(CountdownEventDraft event, String zone) {
  final minutes = event.reminderMinutes;
  if (minutes == null) return null;
  final date = event.targetDate;
  return tz.TZDateTime(
    tz.getLocation(zone),
    date.year,
    date.month,
    date.day,
    minutes ~/ 60,
    minutes % 60,
  ).toUtc();
}

List<LocalReminder> futureEventReminders(PlannerState state, DateTime now) => [
  for (final event in state.events)
    if (eventReminderAt(event, state.campusTimeZone) case final at?
        when at.isAfter(now.toUtc()))
      LocalReminder(
        key: 'event:${event.id}',
        at: at,
        title: event.title,
        body: '今天是${event.targetDate.month}月${event.targetDate.day}日，记得关注这项安排。',
      ),
];
