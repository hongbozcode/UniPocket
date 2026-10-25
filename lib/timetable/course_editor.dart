import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/design.dart';
import '../ui/course_palette.dart';
import 'model.dart';
import 'class_exception_editor.dart';
import 'course_impact_page.dart';

enum CourseEditorResult { saved, deleted }

String scheduleText(ScheduleDraft schedule, Semester semester) {
  final weeks = schedule.weeks.toList()..sort();
  final periods = semester.periods[schedule.weekday]!;
  return '${weekdayNames[schedule.weekday - 1]} · 第 ${schedule.startPeriod}–${schedule.endPeriod} 节\n'
      '${PeriodTime.format(periods[schedule.startPeriod - 1].startMinutes)}–${PeriodTime.format(periods[schedule.endPeriod - 1].endMinutes)}\n'
      '${schedule.location.isEmpty ? '地点未填写' : schedule.location}\n第 ${weeks.join('、')} 周';
}

class CourseEditor extends StatefulWidget {
  const CourseEditor({
    required this.planner,
    required this.semester,
    required this.campusTimeZone,
    this.course,
    this.initialColorIndex = 0,
    this.occurrence,
    this.classExceptions = const [],
    this.independentLessons = const [],
    super.key,
  });
  final SemesterPlanner planner;
  final Semester semester;
  final String campusTimeZone;
  final Course? course;
  final int initialColorIndex;
  final ClassOccurrence? occurrence;
  final List<ClassExceptionDraft> classExceptions;
  final List<IndependentLesson> independentLessons;

  @override
  State<CourseEditor> createState() => _CourseEditorState();
}

class _ScheduleFields {
  _ScheduleFields(Semester semester, {ClassSchedule? schedule})
    : id = schedule?.id,
      weekday =
          schedule?.weekday ??
          semester.periods.entries.firstWhere((e) => e.value.isNotEmpty).key,
      weeks =
          schedule?.weeks.toSet() ??
          {for (var w = 1; w <= semester.totalWeeks; w++) w} {
    if (schedule != null) {
      start.text = '${schedule.startPeriod}';
      end.text = '${schedule.endPeriod}';
      location.text = schedule.location;
    }
  }
  final int? id;
  int weekday;
  final start = TextEditingController(text: '1');
  final end = TextEditingController(text: '1');
  final location = TextEditingController();
  Set<int> weeks;
  void dispose() {
    start.dispose();
    end.dispose();
    location.dispose();
  }
}

class _CourseEditorState extends State<CourseEditor> {
  late final _name = TextEditingController(text: widget.course?.name ?? '');
  late final _teacher = TextEditingController(
    text: widget.course?.teacher ?? '',
  );
  late int _color = widget.course?.colorIndex ?? widget.initialColorIndex;
  final _scroll = ScrollController();
  final _schedules = <_ScheduleFields>[];
  var _saving = false;
  var _editingSchedules = false;
  String? _error;

  Future<void> _exception(
    ClassOccurrence occurrence, {
    bool cancel = false,
  }) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassExceptionEditor(
          planner: widget.planner,
          occurrence: occurrence,
          campusTimeZone: widget.campusTimeZone,
          cancel: cancel,
        ),
      ),
    );
    if (saved == true && mounted) {
      Navigator.pop(context, CourseEditorResult.saved);
    }
  }

  Widget _occurrenceActions(ClassOccurrence occurrence) => SurfaceCard(
    color: lavenderSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          occurrence.isIndependent ? '独立补课' : '本次上课',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${dateText(occurrence.date)} · ${occurrence.location.isEmpty ? '地点未填写' : occurrence.location}',
        ),
        if (occurrence.isRescheduled)
          Text('已调课 · 原课次 ${dateText(occurrence.originalDate)}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: () => _exception(occurrence),
              child: Text(occurrence.isIndependent ? '编辑独立补课' : '单次调课'),
            ),
            TextButton(
              onPressed: () => _exception(occurrence, cancel: true),
              child: Text(occurrence.isIndependent ? '取消独立补课' : '单次停课'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _savedException(ClassExceptionDraft exception) {
    final schedule = widget.course!.schedules.cast<ClassSchedule>().singleWhere(
      (s) => s.id == exception.scheduleId,
    );
    final occurrence = ClassOccurrence(
      course: widget.course!,
      schedule: schedule,
      date: exception.targetDate,
      sourceDate: exception.originalDate,
      startMinutes: exception.startMinutes,
      endMinutes: exception.endMinutes,
      overrideLocation: exception.location,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        color: lavenderSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${exception.isCancelled ? '已停课' : '已调课'} · 原课次 ${dateText(exception.originalDate)}',
            ),
            if (!exception.isCancelled)
              Text(
                '${dateText(exception.targetDate)} · ${PeriodTime.format(exception.startMinutes)}–${PeriodTime.format(exception.endMinutes)}\n${exception.location}',
              ),
            TextButton(
              onPressed: () => _exception(occurrence),
              child: Text(exception.isCancelled ? '重新安排这次上课' : '编辑这次调课'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.course == null) {
      final fields = _ScheduleFields(widget.semester);
      if (widget.semester.periods[fields.weekday]!.length >= 2) {
        fields.end.text = '2';
      }
      _schedules.add(fields);
    } else {
      _schedules.addAll(
        widget.course!.schedules.cast<ClassSchedule>().map(
          (s) => _ScheduleFields(widget.semester, schedule: s),
        ),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _scroll.dispose();
    for (final fields in _schedules) {
      fields.dispose();
    }
    super.dispose();
  }

  Future<void> _range(_ScheduleFields fields) async {
    final start = TextEditingController(text: '1');
    final end = TextEditingController(text: '${widget.semester.totalWeeks}');
    String? error;
    final route = DialogRoute<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('选择连续周'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ProblemBanner(error!),
                TextField(
                  controller: start,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '起始周'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '结束周'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final a = int.tryParse(start.text.trim());
                final b = int.tryParse(end.text.trim());
                if (a == null ||
                    b == null ||
                    a < 1 ||
                    b < a ||
                    b > widget.semester.totalWeeks) {
                  update(() => error = '请输入学期内有效的起止周。');
                } else {
                  Navigator.pop(context, {for (var w = a; w <= b; w++) w});
                }
              },
              child: const Text('应用连续周'),
            ),
          ],
        ),
      ),
    );
    final range = await Navigator.of(context).push(route);
    await route.completed;
    start.dispose();
    end.dispose();
    if (range != null && mounted) setState(() => fields.weeks = range);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.course case final course?) {
        if (_editingSchedules) {
          final impact = await widget.planner.previewCourseChange(
            course.id,
            _draft(),
          );
          if (!mounted) return;
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CourseImpactPage(
                planner: widget.planner,
                impact: impact,
                campusTimeZone: widget.campusTimeZone,
              ),
            ),
          );
          if (saved != true) return;
        } else {
          await widget.planner.updateCourseDetails(
            course.id,
            name: _name.text,
            teacher: _teacher.text,
            colorIndex: _color,
          );
        }
      } else {
        final draft = CourseDraft(
          semesterId: widget.semester.id,
          name: _name.text,
          teacher: _teacher.text,
          colorIndex: _color,
          schedules: [
            for (var i = 0; i < _schedules.length; i++)
              _readSchedule(_schedules[i], i + 1),
          ],
        );
        try {
          await widget.planner.saveCourse(draft);
        } on CourseConflict catch (conflict) {
          if (!mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('上课时间冲突'),
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
          await widget.planner.saveCourse(draft, allowConflicts: true);
        }
      }
      if (mounted) Navigator.pop(context, CourseEditorResult.saved);
    } on InputProblem catch (problem) {
      if (mounted) setState(() => _error = problem.message);
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，请检查本机存储空间后重试。');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        if (_error != null) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  CourseDraft _draft() => CourseDraft(
    semesterId: widget.semester.id,
    name: _name.text,
    teacher: _teacher.text,
    colorIndex: _color,
    schedules: [
      for (var i = 0; i < _schedules.length; i++)
        _readSchedule(_schedules[i], i + 1),
    ],
  );

  Future<void> _delete() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final impact = await widget.planner.previewCourseDeletion(
        widget.course!.id,
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除课程'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('删除“${impact.course.name}”后，将清理：'),
                const SizedBox(height: 12),
                Text(
                  '${impact.course.schedules.length} 个上课安排、${impact.exceptionCount} 项调停课及 ${impact.independentCount} 次独立补课。',
                ),
                const SizedBox(height: 12),
                Text('${impact.taskCount} 项学习任务将解除课程关联并保留，截止时间、备注和完成状态不变。'),
                const SizedBox(height: 12),
                const Text('删除后不可撤销。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffb32643),
              ),
              child: const Text('确认删除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.planner.deleteCourse(impact);
      if (mounted) Navigator.pop(context, CourseEditorResult.deleted);
    } on InputProblem catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '删除失败，课程与学习任务保持不变，请重试。');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        if (_error != null) _scroll.jumpTo(0);
      }
    }
  }

  ScheduleDraft _readSchedule(_ScheduleFields fields, int number) {
    final start = int.tryParse(fields.start.text.trim());
    final end = int.tryParse(fields.end.text.trim());
    if (start == null || end == null) {
      throw InputProblem('上课安排 $number：节次须为整数。');
    }
    final schedule = fields.id != null
        ? ClassSchedule(
            id: fields.id!,
            weekday: fields.weekday,
            startPeriod: start,
            endPeriod: end,
            location: fields.location.text,
            weeks: fields.weeks,
          )
        : ScheduleDraft(
            weekday: fields.weekday,
            startPeriod: start,
            endPeriod: end,
            location: fields.location.text,
            weeks: fields.weeks,
          );
    try {
      schedule.validate(widget.semester);
    } on InputProblem catch (e) {
      throw InputProblem('上课安排 $number：${e.message}');
    }
    return schedule;
  }

  Widget _schedule(_ScheduleFields fields, int index) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '上课安排 ${index + 1}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey('schedule-day-$index'),
          initialValue: fields.weekday,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '星期'),
          items: [
            for (var day = 1; day <= 7; day++)
              DropdownMenuItem(value: day, child: Text(weekdayNames[day - 1])),
          ],
          onChanged: (day) => setState(() => fields.weekday = day!),
        ),
        const SizedBox(height: 12),
        Text(
          '当天已配置 ${widget.semester.periods[fields.weekday]?.length ?? 0} 节；时间按校园时区解释。',
        ),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('schedule-start-$index'),
          controller: fields.start,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '起始节次'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('schedule-end-$index'),
          controller: fields.end,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '结束节次'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('schedule-location-$index'),
          controller: fields.location,
          decoration: const InputDecoration(labelText: '地点（可选）'),
        ),
        const SizedBox(height: 16),
        const Text('教学周 · 可点选任意周'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final mode in ['全部周', '单周', '双周'])
              TextButton(
                onPressed: () => setState(() {
                  fields.weeks = {
                    for (var w = 1; w <= widget.semester.totalWeeks; w++)
                      if (mode == '全部周' || (mode == '单周' ? w.isOdd : w.isEven))
                        w,
                  };
                }),
                child: Text(mode),
              ),
            TextButton(
              onPressed: () => _range(fields),
              child: const Text('连续周'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var week = 1; week <= widget.semester.totalWeeks; week++)
              FilterChip(
                label: Text('$week'),
                tooltip: '第 $week 周',
                selected: fields.weeks.contains(week),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    fields.weeks.add(week);
                  } else {
                    fields.weeks.remove(week);
                  }
                }),
              ),
          ],
        ),
        if (_schedules.length > 1)
          TextButton.icon(
            key: ValueKey('remove-schedule-$index'),
            onPressed: () {
              setState(() => _schedules.remove(fields));
              fields.dispose();
            },
            icon: const Icon(Icons.close),
            label: Text(fields.id == null ? '移除此未保存安排' : '移除此上课安排'),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.course == null ? '添加课程' : '课程详情')),
    body: SafeArea(
      child: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.semester.name}\n校园时间 · ${widget.campusTimeZone}'),
              const SizedBox(height: 20),
              if (_error != null) ProblemBanner(_error!),
              if (widget.occurrence case final occurrence?
                  when !_editingSchedules) ...[
                _occurrenceActions(occurrence),
                const SizedBox(height: 20),
              ],
              TextField(
                key: const ValueKey('course-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: '课程名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('course-teacher'),
                controller: _teacher,
                decoration: const InputDecoration(labelText: '教师（可选）'),
              ),
              const SizedBox(height: 16),
              const Text('课程识别色 · 本课程的所有上课安排使用同一颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in {
                    for (var i = 0; i < courseColorNames.length; i++) i,
                    widget.initialColorIndex,
                    if (widget.course != null) widget.course!.colorIndex,
                  })
                    ChoiceChip(
                      key: ValueKey('course-color-$color'),
                      avatar: CircleAvatar(
                        backgroundColor: courseAccent(color),
                        radius: 9,
                      ),
                      label: Text(
                        color < courseColorNames.length
                            ? courseColorNames[color]
                            : '推荐色',
                      ),
                      backgroundColor: courseTint(color),
                      selectedColor: courseTint(color),
                      selected: _color == color,
                      onSelected: (_) => setState(() => _color = color),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('course-color-preview'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: courseTint(_color),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: courseAccent(_color)),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (_, value, child) => Text(
                    value.text.trim().isEmpty ? '课程颜色预览' : value.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.course case final course? when !_editingSchedules) ...[
                for (final exception in widget.classExceptions.where(
                  (e) => course.schedules.any(
                    (s) => s is ClassSchedule && s.id == e.scheduleId,
                  ),
                ))
                  _savedException(exception),
                for (final lesson in widget.independentLessons.where(
                  (l) =>
                      l.courseId == course.id &&
                      l.id != widget.occurrence?.independentLessonId,
                )) ...[
                  _occurrenceActions(lesson.occurrence(course)),
                  const SizedBox(height: 12),
                ],
                const Text(
                  '已有上课安排',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final schedule in course.schedules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SurfaceCard(
                      color: courseTint(_color),
                      child: Text(scheduleText(schedule, widget.semester)),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => setState(() => _editingSchedules = true),
                  child: const Text('修改重复安排'),
                ),
              ] else ...[
                for (var i = 0; i < _schedules.length; i++)
                  Padding(
                    key: ObjectKey(_schedules[i]),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _schedule(_schedules[i], i),
                  ),
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _schedules.add(_ScheduleFields(widget.semester)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('添加上课安排'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('save-course'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '正在保存…' : '保存课程'),
              ),
              if (widget.course != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xffb32643),
                  ),
                  child: const Text('删除课程'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
