import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'model.dart';

const taskDanger = Color(0xffb32643);

class TaskCompletionFeedback extends StatelessWidget {
  const TaskCompletionFeedback({
    required this.completed,
    required this.reminderStatus,
    super.key,
  });
  final bool completed;
  final String reminderStatus;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(completed ? '任务已完成' : '已撤销完成'),
      Text(reminderStatus, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.campusNow,
    required this.onEdit,
    required this.onToggle,
    this.course,
    super.key,
  });
  final LearningTask task;
  final DateTime campusNow;
  final Course? course;
  final VoidCallback onEdit;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final group = task.groupAt(campusNow);
    final overdue = group == TaskGroup.overdue;
    final due = group == TaskGroup.today
        ? '今天 ${PeriodTime.format(task.dueMinutes)}'
        : '${task.dueDate.month}月${task.dueDate.day}日 ${PeriodTime.format(task.dueMinutes)}';
    return Material(
      color: Colors.white.withValues(alpha: .87),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: '${task.isCompleted ? '撤销完成' : '完成'}：${task.title}',
            onPressed: onToggle,
            icon: Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: task.isCompleted
                  ? const Color(0xff198568)
                  : const Color(0xffa5b0c5),
              size: 27,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        final title = Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        );
                        final badge = course == null
                            ? null
                            : Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 110,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: courseTint(course!.colorIndex),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  course!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: courseAccent(course!.colorIndex),
                                  ),
                                ),
                              );
                        if (box.maxWidth < 240 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              if (badge != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: badge,
                                ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: title),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              badge,
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: DesignIcon(
                            'clock',
                            size: 14,
                            color: Color(0xff73819a),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${task.isCompleted
                                ? '已完成 · '
                                : overdue
                                ? '已逾期 · '
                                : ''}$due',
                            style: TextStyle(
                              fontSize: 12,
                              color: overdue
                                  ? taskDanger
                                  : const Color(0xff73819a),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskSection extends StatelessWidget {
  const TaskSection({required this.group, required this.children, super.key});
  final TaskGroup group;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, tint) = switch (group) {
      TaskGroup.overdue => (
        '已逾期',
        'warning',
        taskDanger,
        const Color(0xffffedf0),
      ),
      TaskGroup.today => (
        '今天',
        'calendar',
        primaryBlue,
        const Color(0xffeaf2ff),
      ),
      TaskGroup.upcoming => ('接下来', 'clock', inkColor, Colors.white),
      TaskGroup.completed => (
        '已完成',
        'check',
        const Color(0xff198568),
        const Color(0xffe6f5ed),
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
            child: Row(
              children: [
                DesignIcon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${children.length}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            children[i],
          ],
        ],
      ),
    );
  }
}
