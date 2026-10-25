import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/design.dart';
import 'model.dart';
import 'task_editor.dart';
import 'task_widgets.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({required this.planner, required this.clock, super.key});
  final SemesterPlanner planner;
  final DateTime Function() clock;
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with WidgetsBindingObserver {
  PlannerState? _state;
  bool _completed = false;
  int? _courseId;
  bool _independent = false;
  bool _busy = false;
  String? _error;
  Timer? _refresh;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await widget.planner.load();
      await widget.planner.refreshReminders();
      if (mounted) {
        setState(() {
          _state = state;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法读取学习任务，请重试。现有记录保持不变。');
    }
  }

  Future<void> _edit([LearningTask? task]) async {
    _messenger.currentState?.removeCurrentSnackBar();
    final state = _state!;
    final saved = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditor(
          planner: widget.planner,
          state: state,
          campusNow: state.campusTime(widget.clock().toUtc()),
          task: task,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) {
        _messenger.currentState!.hideCurrentSnackBar();
        _messenger.currentState!.showSnackBar(SnackBar(content: Text(saved)));
      }
    }
  }

  Future<void> _toggle(LearningTask task, [bool? completed]) async {
    if (!mounted || _busy) return;
    final target = completed ?? !task.isCompleted;
    setState(() => _busy = true);
    try {
      await widget.planner.setTaskCompleted(task.id, target);
      await _load();
      if (mounted) {
        _messenger.currentState!.hideCurrentSnackBar();
        _messenger.currentState!.showSnackBar(
          SnackBar(
            content: TaskCompletionFeedback(
              completed: target,
              reminderStatus: widget.planner.taskReminderStatus(
                _state!.tasks.singleWhere((t) => t.id == task.id),
                _state!.campusTimeZone,
              ),
            ),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () => _toggle(task, !target),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '状态保存失败，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _filters() {
    final switcher = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xffeaf0f8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (final completed in [false, true])
            Expanded(
              child: Semantics(
                selected: _completed == completed,
                child: Material(
                  color: _completed == completed
                      ? const Color(0xffd6c1fc)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => setState(() => _completed = completed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(
                        '${completed ? '已完成' : '未完成'}  ${_state!.tasks.where((t) => t.isCompleted == completed).length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _completed == completed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _completed == completed
                              ? const Color(0xff301985)
                              : const Color(0xff52617a),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final course = PopupMenuButton<int>(
      tooltip: '筛选课程',
      initialValue: _independent ? -1 : _courseId ?? 0,
      onSelected: (id) => setState(() {
        _independent = id == -1;
        _courseId = id > 0 ? id : null;
      }),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 0, child: Text('全部课程')),
        const PopupMenuItem(value: -1, child: Text('独立任务')),
        for (final course in _state!.courses)
          PopupMenuItem(
            value: course.id,
            child: Text(
              '${course.name} · ${_state!.semesters.firstWhere((s) => s.id == course.semesterId).name}',
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffd5deed)),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _independent
                    ? '独立任务'
                    : _courseId == null
                    ? '全部课程'
                    : _state!.courses
                              .where((c) => c.id == _courseId)
                              .firstOrNull
                              ?.name ??
                          '课程已删除',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xff52617a)),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xff73819a),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth >= 330 &&
                MediaQuery.textScalerOf(context).scale(12) < 18
            ? Row(
                children: [
                  Expanded(child: switcher),
                  const SizedBox(width: 8),
                  SizedBox(width: 110, child: course),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [switcher, const SizedBox(height: 10), course],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final now = state?.campusTime(widget.clock().toUtc());
    final tasks = state == null
        ? <LearningTask>[]
        : selectTasks(
            state.tasks,
            completed: _completed,
            courseId: _courseId,
            independentOnly: _independent,
          );
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_busy) const LinearProgressIndicator(),
              Expanded(
                child: state == null && _error == null
                    ? const Center(child: CircularProgressIndicator())
                    : PageContent(
                        children: [
                          Row(
                            children: [
                              RoundDesignButton(
                                icon: 'back',
                                label: '返回',
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Text(
                                  '学习任务',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              RoundDesignButton(
                                icon: 'plus',
                                label: '创建任务',
                                onPressed: state == null || _busy
                                    ? null
                                    : () => _edit(),
                                primary: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_error != null) ...[
                            ProblemBanner(_error!),
                            TextButton(
                              onPressed: _load,
                              child: const Text('重新读取'),
                            ),
                          ],
                          if (state != null) ...[
                            PageHeading(
                              '每一个小目标，\n都值得完成',
                              '校园时间  ${state.campusTimeZone}',
                              art: 'pencil',
                              bottomSpacing: 14,
                            ),
                            _filters(),
                            if (tasks.isEmpty)
                              SurfaceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.tasks.isEmpty
                                          ? '还没有学习任务'
                                          : _completed
                                          ? '暂无已完成任务'
                                          : '当前筛选下没有未完成任务',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('给小目标留一个截止时间，一步一步完成。'),
                                    const SizedBox(height: 14),
                                    FilledButton.icon(
                                      onPressed: () => _edit(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('创建任务'),
                                    ),
                                  ],
                                ),
                              ),
                            for (final group in TaskGroup.values)
                              if (tasks.any((t) => t.groupAt(now!) == group))
                                TaskSection(
                                  group: group,
                                  children: [
                                    for (final task in tasks.where(
                                      (t) => t.groupAt(now!) == group,
                                    ))
                                      TaskCard(
                                        task: task,
                                        campusNow: now!,
                                        course: state.courses
                                            .where((c) => c.id == task.courseId)
                                            .firstOrNull,
                                        onEdit: () => _edit(task),
                                        onToggle: _busy
                                            ? null
                                            : () => _toggle(task),
                                      ),
                                  ],
                                ),
                            const SizedBox(height: 14),
                            Center(
                              child: SvgPicture.asset(
                                'docs/design/resources/illustrations/book.svg',
                                width: 145,
                                height: 110,
                                excludeFromSemantics: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '完成后可撤销',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xff73819a),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
