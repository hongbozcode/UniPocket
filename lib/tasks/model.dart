import '../semesters/model.dart';

/// A campus calendar date and wall-clock minute, independent of the device zone.
class LearningTaskDraft {
  LearningTaskDraft({
    required this.title,
    required DateTime dueDate,
    this.dueMinutes = 1439,
    this.notes = '',
    this.courseId,
  }) : dueDate = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);

  final String title;
  final DateTime dueDate;
  final int dueMinutes;
  final String notes;
  final int? courseId;

  void validate() {
    if (title.trim().isEmpty) throw const InputProblem('请输入任务标题。');
    if (dueMinutes < 0 || dueMinutes >= 1440) {
      throw const InputProblem('请选择当天内的有效截止时间。');
    }
  }
}

enum TaskGroup { overdue, today, upcoming, completed }

class LearningTask extends LearningTaskDraft {
  LearningTask({
    required this.id,
    required super.title,
    required super.dueDate,
    required super.dueMinutes,
    required super.notes,
    required super.courseId,
    required this.isCompleted,
  });

  final int id;
  final bool isCompleted;

  DateTime get deadline => dueDate.add(Duration(minutes: dueMinutes));

  TaskGroup groupAt(DateTime campusNow) {
    if (isCompleted) return TaskGroup.completed;
    final wallNow = DateTime.utc(
      campusNow.year,
      campusNow.month,
      campusNow.day,
      campusNow.hour,
      campusNow.minute,
      campusNow.second,
      campusNow.millisecond,
      campusNow.microsecond,
    );
    if (deadline.isBefore(wallNow)) return TaskGroup.overdue;
    if (dueDate ==
        DateTime.utc(campusNow.year, campusNow.month, campusNow.day)) {
      return TaskGroup.today;
    }
    return TaskGroup.upcoming;
  }
}

List<LearningTask> selectTasks(
  List<LearningTask> tasks, {
  bool completed = false,
  int? courseId,
  bool independentOnly = false,
}) =>
    tasks
        .where(
          (task) =>
              task.isCompleted == completed &&
              (courseId == null || task.courseId == courseId) &&
              (!independentOnly || task.courseId == null),
        )
        .toList()
      ..sort((a, b) {
        final order = a.deadline.compareTo(b.deadline);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
