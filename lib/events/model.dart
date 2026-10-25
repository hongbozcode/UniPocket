import '../semesters/model.dart';

enum EventKind { exam, custom }

class CountdownEventDraft {
  CountdownEventDraft({
    required this.title,
    required DateTime targetDate,
    this.kind = EventKind.exam,
    this.isPinned = false,
    this.reminderMinutes = 540,
  }) : targetDate = DateTime.utc(
         targetDate.year,
         targetDate.month,
         targetDate.day,
       );

  final String title;
  final DateTime targetDate;
  final EventKind kind;
  final bool isPinned;

  /// Minutes after midnight on the event's campus date; null disables reminders.
  final int? reminderMinutes;

  void validate() {
    if (title.trim().isEmpty) throw const InputProblem('请输入事件标题。');
    if (reminderMinutes != null &&
        (reminderMinutes! < 0 || reminderMinutes! > 1439)) {
      throw const InputProblem('请选择当天 00:00 至 23:59 之间的提醒时间。');
    }
    if (targetDate.year < 1900 || targetDate.year > 2200) {
      throw const InputProblem('请选择 1900 至 2200 年之间的日期。');
    }
  }
}

class CountdownEvent extends CountdownEventDraft {
  CountdownEvent({
    required this.id,
    required super.title,
    required super.targetDate,
    required super.kind,
    required super.isPinned,
    super.reminderMinutes,
  });

  final int id;

  int daysRemaining(DateTime campusNow) => targetDate
      .difference(DateTime.utc(campusNow.year, campusNow.month, campusNow.day))
      .inDays;

  String countdownText(DateTime campusNow) {
    final days = daysRemaining(campusNow);
    return days == 0
        ? '就是今天'
        : days > 0
        ? '$days 天'
        : '已过去 ${-days} 天';
  }
}

List<CountdownEvent> selectEvents(
  List<CountdownEvent> events,
  DateTime campusNow, {
  bool history = false,
}) =>
    events
        .where((event) => (event.daysRemaining(campusNow) < 0) == history)
        .toList()
      ..sort((a, b) {
        if (!history && a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        final dates = history
            ? b.targetDate.compareTo(a.targetDate)
            : a.targetDate.compareTo(b.targetDate);
        return dates == 0 ? a.id.compareTo(b.id) : dates;
      });
