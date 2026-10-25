import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/design.dart';
import 'model.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({
    required this.planner,
    required this.state,
    required this.campusNow,
    this.task,
    super.key,
  });
  final SemesterPlanner planner;
  final PlannerState state;
  final DateTime campusNow;
  final LearningTask? task;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final _title = TextEditingController(text: widget.task?.title);
  late final _notes = TextEditingController(text: widget.task?.notes);
  late DateTime _date =
      widget.task?.dueDate ??
      DateTime.utc(
        widget.campusNow.year,
        widget.campusNow.month,
        widget.campusNow.day,
      );
  late int _minutes = widget.task?.dueMinutes ?? 1439;
  late int? _courseId = widget.task?.courseId;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.planner.saveTask(
        LearningTaskDraft(
          title: _title.text,
          dueDate: _date,
          dueMinutes: _minutes,
          notes: _notes.text,
          courseId: _courseId,
        ),
        id: widget.task?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } on InputProblem catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '任务保存失败，请重试。原记录保持不变。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这项任务？'),
        content: Text('“${widget.task!.title}”将从本机删除，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.planner.deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = '删除失败，原记录仍在，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(_date.year < 1900 ? _date.year : 1900),
      lastDate: DateTime(_date.year > 2200 ? _date.year : 2200, 12, 31),
      helpText: '截止日期 · ${widget.state.campusTimeZone}',
      currentDate: DateTime(
        widget.campusNow.year,
        widget.campusNow.month,
        widget.campusNow.day,
      ),
    );
    if (chosen != null && mounted) {
      setState(
        () => _date = DateTime.utc(chosen.year, chosen.month, chosen.day),
      );
    }
  }

  Future<void> _pickTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      helpText: '截止时间 · 校园时间',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _minutes = chosen.hour * 60 + chosen.minute);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? '创建学习任务' : '编辑学习任务')),
      body: SafeArea(
        top: false,
        child: AbsorbPointer(
          absorbing: _busy,
          child: PageContent(
            children: [
              Text(
                '校园时间 · ${widget.state.campusTimeZone}',
                style: const TextStyle(color: Color(0xff73819a), fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (_error != null) ProblemBanner(_error!),
              if (_busy) const LinearProgressIndicator(),
              TextField(
                key: const ValueKey('task-title'),
                controller: _title,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  hintText: '例如：高数习题 第五章',
                ),
                textInputAction: TextInputAction.next,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              SurfaceCard(
                color: lavenderSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '截止日期与时间',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const DesignIcon('calendar', size: 20),
                      label: Text(dateText(_date)),
                    ),
                    TextButton.icon(
                      onPressed: _pickTime,
                      icon: const DesignIcon('clock', size: 20),
                      label: Text(PeriodTime.format(_minutes)),
                      key: const ValueKey('task-time'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '仅选择日期时默认 23:59，点击时间可修改。',
                      style: TextStyle(fontSize: 12, color: Color(0xff52617a)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                key: const ValueKey('task-course'),
                initialValue: _courseId ?? -1,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '关联课程（可选）'),
                items: [
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('独立任务 · 不关联课程'),
                  ),
                  for (final course in widget.state.courses)
                    DropdownMenuItem(
                      value: course.id,
                      child: Text(
                        '${course.name} · ${widget.state.semesters.firstWhere((s) => s.id == course.semesterId).name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) =>
                    setState(() => _courseId = id == -1 ? null : id),
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('task-notes'),
                controller: _notes,
                minLines: 3,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? '正在保存…' : '保存任务'),
              ),
              if (widget.task != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('删除任务'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
