import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'semesters/model.dart';
import 'semesters/planner.dart';
import 'semesters/semester_editor.dart';
import 'semesters/semester_pages.dart';
import 'ui/design.dart';
import 'timetable/model.dart';
import 'timetable/course_editor.dart';
import 'timetable/timetable_page.dart';
import 'tasks/model.dart';
import 'tasks/task_editor.dart';
import 'tasks/task_widgets.dart';
import 'tasks/tasks_page.dart';
import 'events/model.dart';
import 'events/event_editor.dart';
import 'events/event_widgets.dart';
import 'events/events_page.dart';
import 'reminders/notification_card.dart';
import 'random_tools/tools_page.dart';

class UniPocketApp extends StatelessWidget {
  const UniPocketApp({
    required this.planner,
    this.clock,
    this.random,
    super.key,
  });
  final SemesterPlanner planner;
  final DateTime Function()? clock;
  final Random? random;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'UniPocket',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _AppShell(
      planner: planner,
      clock: clock ?? DateTime.now,
      random: random,
    ),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.planner, required this.clock, this.random});
  final SemesterPlanner planner;
  final DateTime Function() clock;
  final Random? random;
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  PlannerState? _state;
  String? _error;
  var _page = 0;
  var _busy = false;
  Timer? _clockRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _clockRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
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
    _clockRefresh?.cancel();
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
      if (mounted) setState(() => _error = '无法读取本地数据，请重试。现有数据不会被清空。');
    }
  }

  Future<void> _edit([Semester? semester]) async {
    final state = _state!;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SemesterEditor(
          planner: widget.planner,
          campusNow: state.campusTime(widget.clock().toUtc()),
          campusTimeZone: state.campusTimeZone,
          currentSemesterId: state.currentSemesterId,
          semester: semester,
        ),
      ),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('学期已保存到本机')));
      }
    }
  }

  Future<void> _manage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SemesterManagement(planner: widget.planner),
      ),
    );
    await _load();
  }

  Future<void> _task([LearningTask? task]) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(saved)));
      }
    }
  }

  Future<void> _tasks() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TasksPage(planner: widget.planner, clock: widget.clock),
      ),
    );
    await _load();
  }

  Future<void> _event([CountdownEvent? event]) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final saved = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditor(
          planner: widget.planner,
          state: _state!,
          clock: widget.clock,
          event: event,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(saved)));
      }
    }
  }

  Future<void> _events() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventsPage(planner: widget.planner, clock: widget.clock),
      ),
    );
    await _load();
  }

  Widget _eventSummary(DateTime now) {
    final events = selectEvents(_state!.events, now);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DesignIcon('calendar', size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '近期倒计时',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              RoundDesignButton(
                icon: 'plus',
                label: '创建倒计时',
                onPressed: () => _event(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Text(
              '还没有进行中的事件，记下下一个重要的日子吧。',
              style: TextStyle(fontSize: 13, color: Color(0xff73819a)),
            ),
          for (final event in events.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EventCard(
                event: event,
                campusNow: now,
                onEdit: () => _event(event),
              ),
            ),
          TextButton(onPressed: _events, child: const Text('查看全部倒计时')),
        ],
      ),
    );
  }

  Future<void> _toggleTask(LearningTask task, [bool? completed]) async {
    if (_busy) return;
    final target = completed ?? !task.isCompleted;
    setState(() => _busy = true);
    try {
      await widget.planner.setTaskCompleted(task.id, target);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
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
              onPressed: () => _toggleTask(task, !target),
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

  Widget _taskSummary(DateTime now) {
    final tasks = selectTasks(_state!.tasks);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DesignIcon('task', size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '学习任务',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              RoundDesignButton(
                icon: 'plus',
                label: '创建任务',
                onPressed: () => _task(),
              ),
            ],
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '还没有未完成任务，记下下一个小目标吧。',
              style: TextStyle(fontSize: 13, color: Color(0xff73819a)),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _task(),
              icon: const Icon(Icons.add),
              label: const Text('创建任务'),
            ),
          ],
          for (final task in tasks.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TaskCard(
                task: task,
                campusNow: now,
                course: _state!.courses
                    .where((c) => c.id == task.courseId)
                    .firstOrNull,
                onEdit: () => _task(task),
                onToggle: _busy ? null : () => _toggleTask(task),
              ),
            ),
          TextButton(
            onPressed: _tasks,
            child: Text(
              tasks.length > 3 ? '查看全部任务（${tasks.length} 项未完成）' : '查看全部任务',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _course([Course? course, ClassOccurrence? occurrence]) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final state = _state!;
    final semester = state.currentSemester;
    if (semester == null) return;
    final usedColors = state.courses
        .where((c) => c.semesterId == semester.id)
        .map((c) => c.colorIndex)
        .toSet();
    var initialColor = 0;
    while (usedColors.contains(initialColor)) {
      initialColor++;
    }
    final saved = await Navigator.push<CourseEditorResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseEditor(
          planner: widget.planner,
          semester: semester,
          campusTimeZone: state.campusTimeZone,
          course: course,
          initialColorIndex: initialColor,
          occurrence: occurrence,
          classExceptions: state.classExceptions,
          independentLessons: state.independentLessons,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved.deleted
                  ? '课程已删除，学习任务已保留。${widget.planner.reminderSyncFailed ? '提醒撤销失败，请在设置中重试' : '课程未来提醒已撤销'}'
                  : '课程已保存到本机。${widget.planner.courseReminderStatus(_state!.courses.singleWhere((c) => c.id == saved.courseId), _state!)}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _timeZone() async {
    final zone = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CampusTimeZonePicker(currentZone: _state!.campusTimeZone),
      ),
    );
    if (zone == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.planner.setCampusTimeZone(zone);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = '时区保存失败，原设置保持不变，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _startCard() => SurfaceCard(
    color: lavenderSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '先创建一个学期',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('设置教学周和每日节次，为接下来的学习安排做好准备。无需账号，断网也能保存。'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('创建学期'),
        ),
      ],
    ),
  );

  Widget _home() {
    final now = _state!.campusTime(widget.clock().toUtc());
    final today = _state!.today(widget.clock().toUtc());
    final semester = _state!.currentSemester;
    final week = _state!.timetable?.weekOf(now);
    final weekText = semester == null
        ? ''
        : (week! >= 1 && week <= semester.totalWeeks
              ? ' · 第 $week 周'
              : ' · 学期外');
    return PageContent(
      children: [
        Row(
          children: [
            const DesignIcon('badge', size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'UniPocket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            if (semester != null)
              RoundDesignButton(
                icon: 'plus',
                label: '添加课程',
                onPressed: () => _course(),
                primary: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        PageHeading(
          '${now.hour < 12
              ? '早上好'
              : now.hour < 18
              ? '下午好'
              : '晚上好'}，\n今天也从容一点',
          '${now.month}月${now.day}日 ${weekdayNames[now.weekday - 1]}$weekText\n校园时间  ${_state!.campusTimeZone}',
          art: 'sun',
        ),
        if (semester == null)
          _startCard()
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const DesignIcon('calendar', size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '今日课程',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _page = 1),
                      child: const Text(
                        '全部',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff73819a),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TodayCourses(
                  occurrences: today,
                  campusNow: now,
                  onEdit: _course,
                  onOccurrence: (o) => _course(o.course, o),
                  emptyText: _state!.timetable!.courses.isEmpty
                      ? '还没有录入课程，点击右上角添加。'
                      : '今天没有课程，可以从容安排时间。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            semester.name,
            style: const TextStyle(fontSize: 12, color: Color(0xff73819a)),
          ),
          Text(
            '第 1 周周一 · ${dateText(semester.firstMonday)}',
            style: const TextStyle(fontSize: 11, color: Color(0xff73819a)),
          ),
        ],
        const SizedBox(height: 20),
        _taskSummary(now),
        const SizedBox(height: 20),
        _eventSummary(now),
      ],
    );
  }

  Widget _timetable() => _state!.currentSemester != null
      ? TimetablePage(
          state: _state!,
          campusNow: _state!.campusTime(widget.clock().toUtc()),
          onAdd: () => _course(),
          onEdit: _course,
          onOccurrence: (o) => _course(o.course, o),
          onManage: _manage,
          onTasks: _tasks,
          onEvents: _events,
        )
      : PageContent(
          children: [
            PageHeading(
              '我的课表',
              '校园时间 · ${_state!.campusTimeZone}',
              art: 'book',
            ),
            _startCard(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _tasks,
              icon: const DesignIcon('task'),
              label: const Text('学习任务'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _events,
              icon: const DesignIcon('calendar'),
              label: const Text('倒计时'),
            ),
          ],
        );

  Widget _tools() => ToolsPage(random: widget.random);

  Widget _settings() => PageContent(
    children: [
      const PageHeading('校园设置', '让校园日常，更合你的节奏'),
      Text(
        '学习安排',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: const DesignIcon('calendar'),
              title: const Text('学期管理'),
              subtitle: Text(_state!.currentSemester?.name ?? '尚未创建学期'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _manage,
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: const DesignIcon('clock'),
              title: const Text('节次时间'),
              subtitle: Text(
                _state!.currentSemester == null ? '请先创建学期' : '按当前学期分别设置每天的节次',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _edit(_state!.currentSemester),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: const DesignIcon('globe'),
              title: const Text('校园时区'),
              subtitle: Text(_state!.campusTimeZone),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : _timeZone,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        '提醒',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      NotificationCard(planner: widget.planner),
      const SizedBox(height: 24),
      SurfaceCard(
        color: const Color(0xffe6f5ed),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据留在自己手中',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('无需账号，离线使用。学习数据保存在当前设备，应用不会主动上传。'),
            if (kIsWeb) ...[
              const SizedBox(height: 10),
              const Text('网页数据保存在当前浏览器的此站点中。清除站点数据或结束隐私浏览可能会丢失记录。'),
            ],
            const SizedBox(height: 10),
            const Text('备份恢复将在后续版本开放。'),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  ProblemBanner(_error!),
                  TextButton(onPressed: _load, child: const Text('重新读取')),
                ],
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: _state == null
                ? (_error == null
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink())
                : switch (_page) {
                    0 => _home(),
                    1 => _timetable(),
                    2 => _tools(),
                    _ => _settings(),
                  },
          ),
        ],
      ),
    ),
    bottomNavigationBar: Material(
      key: const ValueKey('main-navigation'),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              for (final (index, entry) in [
                ('home', '首页'),
                ('calendar', '课表'),
                ('grid', '工具'),
                ('settings', '设置'),
              ].indexed)
                Expanded(
                  child: AppNavigationItem(
                    icon: entry.$1,
                    label: entry.$2,
                    selected: index == _page,
                    onTap: () => setState(() => _page = index),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
