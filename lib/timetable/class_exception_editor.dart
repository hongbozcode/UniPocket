import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'model.dart';

class ClassExceptionEditor extends StatefulWidget {
  const ClassExceptionEditor({
    required this.planner,
    required this.occurrence,
    required this.campusTimeZone,
    this.cancel = false,
    super.key,
  });
  final SemesterPlanner planner;
  final ClassOccurrence occurrence;
  final String campusTimeZone;
  final bool cancel;

  @override
  State<ClassExceptionEditor> createState() => _ClassExceptionEditorState();
}

class _ClassExceptionEditorState extends State<ClassExceptionEditor> {
  late DateTime _date = widget.occurrence.date;
  late int _start = widget.occurrence.startMinutes;
  late int _end = widget.occurrence.endMinutes;
  late final _location = TextEditingController(
    text: widget.occurrence.location,
  );
  final _scroll = ScrollController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _location.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: '调课日期 · ${widget.campusTimeZone}',
    );
    if (selected != null && mounted) {
      setState(
        () => _date = DateTime.utc(selected.year, selected.month, selected.day),
      );
    }
  }

  Future<void> _pickTime(bool start) async {
    final minutes = start ? _start : _end;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: start ? '开始时间 · 校园时间' : '结束时间 · 校园时间',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (start) {
          _start = selected.hour * 60 + selected.minute;
        } else {
          _end = selected.hour * 60 + selected.minute;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final occurrence = widget.occurrence;
    final draft = ClassExceptionDraft(
      scheduleId: (occurrence.schedule as ClassSchedule).id,
      originalDate: occurrence.originalDate,
      targetDate: _date,
      startMinutes: _start,
      endMinutes: _end,
      location: _location.text,
      isCancelled: widget.cancel,
    );
    try {
      try {
        await widget.planner.saveClassException(draft);
      } on CourseConflict catch (conflict) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('调课时间冲突'),
            content: SingleChildScrollView(child: Text(conflict.message)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('返回修改'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('仍然保存'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await widget.planner.saveClassException(draft, allowConflicts: true);
      }
      if (mounted) Navigator.pop(context, true);
    } on InputProblem catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，原课次保持不变，请重试。');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_error != null) _scroll.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.occurrence;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.cancel ? '单次停课' : '单次调课')),
        body: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: _busy,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '校园时间 · ${widget.campusTimeZone}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff73819a),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ProblemBanner(_error!),
                  SurfaceCard(
                    color: courseTint(occurrence.course.colorIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occurrence.course.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('原课次 · ${dateText(occurrence.originalDate)}'),
                        const SizedBox(height: 6),
                        Text(
                          '当前安排 · ${dateText(occurrence.date)}\n${PeriodTime.format(occurrence.startMinutes)}–${PeriodTime.format(occurrence.endMinutes)} · ${occurrence.location.isEmpty ? '地点未填写' : occurrence.location}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.cancel)
                    const SurfaceCard(
                      color: lavenderSoft,
                      child: Text('仅取消这个原课次及其已调课安排。整门课程、其他课次与目标周原有课程均保留。'),
                    )
                  else ...[
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '调整后的安排',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('exception-date'),
                            onPressed: _pickDate,
                            icon: const DesignIcon('calendar'),
                            label: Text(dateText(_date)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('exception-start'),
                            onPressed: () => _pickTime(true),
                            icon: const DesignIcon('clock'),
                            label: Text('开始 ${PeriodTime.format(_start)}'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: const ValueKey('exception-end'),
                            onPressed: () => _pickTime(false),
                            icon: const DesignIcon('clock'),
                            label: Text('结束 ${PeriodTime.format(_end)}'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const ValueKey('exception-location'),
                            controller: _location,
                            maxLines: null,
                            decoration: const InputDecoration(
                              labelText: '地点（可选）',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '只调整这一次上课，可跨周。其他课次保持原安排；新安排有时间冲突时会先提示。',
                      style: TextStyle(fontSize: 13, color: Color(0xff52617a)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('save-exception'),
                    onPressed: _busy ? null : _save,
                    child: Text(
                      _busy
                          ? '正在保存…'
                          : widget.cancel
                          ? '确认停课'
                          : '保存调课',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('取消编辑'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
