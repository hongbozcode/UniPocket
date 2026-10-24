import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'model.dart';
import 'planner.dart';

class SemesterEditor extends StatefulWidget {
  const SemesterEditor({
    required this.planner,
    required this.campusNow,
    required this.campusTimeZone,
    required this.currentSemesterId,
    this.semester,
    super.key,
  });
  final SemesterPlanner planner;
  final DateTime campusNow;
  final String campusTimeZone;
  final int? currentSemesterId;
  final Semester? semester;

  @override
  State<SemesterEditor> createState() => _SemesterEditorState();
}

class _PeriodFields {
  _PeriodFields(String startText, String endText)
    : start = TextEditingController(text: startText),
      end = TextEditingController(text: endText);
  final TextEditingController start;
  final TextEditingController end;
  void dispose() {
    start.dispose();
    end.dispose();
  }
}

class _SemesterEditorState extends State<SemesterEditor> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _name;
  late final TextEditingController _monday;
  late final TextEditingController _weeks;
  late final Map<int, List<_PeriodFields>> _periods;
  var _day = 1;
  var _saving = false;
  var _makeCurrent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final semester = widget.semester;
    final now = widget.campusNow;
    final nearestMonday = DateTime.utc(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    _name = TextEditingController(text: semester?.name ?? '');
    _monday = TextEditingController(
      text: dateText(semester?.firstMonday ?? nearestMonday),
    );
    _weeks = TextEditingController(text: '${semester?.totalWeeks ?? 20}');
    _makeCurrent = widget.currentSemesterId == null;
    _periods = {
      for (var day = 1; day <= 7; day++)
        day: [
          for (final period
              in semester == null
                  ? (day <= 5
                        ? [
                            const PeriodTime(480, 525),
                            const PeriodTime(535, 580),
                          ]
                        : <PeriodTime>[])
                  : (semester.periods[day] ?? <PeriodTime>[]))
            _PeriodFields(
              PeriodTime.format(period.startMinutes),
              PeriodTime.format(period.endMinutes),
            ),
        ],
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _monday.dispose();
    _weeks.dispose();
    _scroll.dispose();
    for (final fields in _periods.values.expand((p) => p)) {
      fields.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = DateTime.tryParse('${text}T00:00:00Z');
    return date != null && dateText(date) == text ? date : null;
  }

  int? _parseTime(String text) {
    if (!RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(text.trim())) {
      return null;
    }
    final parts = text.trim().split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _pickMonday() async {
    final initial = _parseDate(_monday.text);
    final fallback = DateTime(
      widget.campusNow.year,
      widget.campusNow.month,
      widget.campusNow.day - widget.campusNow.weekday + 1,
    );
    final date = await showDatePicker(
      context: context,
      initialDate:
          initial != null &&
              initial.weekday == 1 &&
              initial.year >= 1900 &&
              initial.year <= 2200
          ? DateTime(initial.year, initial.month, initial.day)
          : fallback,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      selectableDayPredicate: (date) => date.weekday == DateTime.monday,
      helpText: '选择第 1 教学周的周一',
    );
    if (date != null) _monday.text = dateText(date);
  }

  Future<void> _copyDay() async {
    var workdaysOnly = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('复制${weekdayNames[_day - 1]}的节次'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('将覆盖目标日期已有的节次，可在保存学期前继续修改。'),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('仅复制到周一至周五'),
                  subtitle: const Text('取消勾选则复制到周一至周日'),
                  value: workdaysOnly,
                  onChanged: (value) =>
                      setDialogState(() => workdaysOnly = value!),
                ),
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
              child: const Text('确认复制'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      for (var day = 1; day <= (workdaysOnly ? 5 : 7); day++) {
        if (day == _day) continue;
        for (final fields in _periods[day]!) {
          fields.dispose();
        }
        _periods[day] = [
          for (final fields in _periods[_day]!)
            _PeriodFields(fields.start.text, fields.end.text),
        ];
      }
    });
  }

  void _report(String message) {
    setState(() => _error = message);
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    // ListView may dispose fields above the viewport, so Form.validate alone
    // cannot validate all saved input. Always parse the retained controllers.
    if (_name.text.trim().isEmpty) {
      _report('请输入学期名称');
      return;
    }
    final monday = _parseDate(_monday.text);
    if (monday == null) {
      _report('请输入有效日期，例如 2026-08-31');
      return;
    }
    if (monday.weekday != DateTime.monday) {
      _report('第 1 教学周必须从周一开始');
      return;
    }
    final weeks = int.tryParse(_weeks.text);
    if (weeks == null || weeks < 1) {
      _report('请输入大于 0 的整数');
      return;
    }
    if (!_form.currentState!.validate()) {
      _report('请检查标出的输入项。节次时间使用 24 小时制，例如 08:00。');
      return;
    }
    final periods = <int, List<PeriodTime>>{};
    for (final entry in _periods.entries) {
      periods[entry.key] = [];
      for (var i = 0; i < entry.value.length; i++) {
        final start = _parseTime(entry.value[i].start.text);
        final end = _parseTime(entry.value[i].end.text);
        if (start == null || end == null) {
          setState(() => _day = entry.key);
          _report(
            '${weekdayNames[entry.key - 1]}第 ${i + 1} 节的时间格式不正确，请填写 HH:mm。',
          );
          return;
        }
        periods[entry.key]!.add(PeriodTime(start, end));
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.planner.saveSemester(
        SemesterDraft(
          name: _name.text,
          firstMonday: monday,
          totalWeeks: weeks,
          periods: periods,
        ),
        id: widget.semester?.id,
        makeCurrent: _makeCurrent,
      );
      if (mounted) Navigator.pop(context, true);
    } on InputProblem catch (error) {
      if (mounted) _report(error.message);
    } catch (_) {
      if (mounted) _report('保存失败，原有数据未改变。请检查本机存储空间后重试。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _periodRow(int index) {
    final fields = _periods[_day]![index];
    Widget timeField(
      TextEditingController controller,
      String label,
      String key,
    ) => TextFormField(
      key: ValueKey('$key-$_day-$index'),
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(labelText: label, hintText: '08:00'),
      validator: (value) =>
          _parseTime(value ?? '') == null ? '请输入有效的 HH:mm' : null,
    );
    final start = timeField(fields.start, '开始时间', 'period-start');
    final end = timeField(fields.end, '结束时间', 'period-end');
    return Padding(
      key: ObjectKey(fields),
      padding: const EdgeInsets.only(top: 12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '第 ${index + 1} 节',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '删除${weekdayNames[_day - 1]}第 ${index + 1} 节',
                  onPressed: () => setState(() {
                    _periods[_day]!.removeAt(index);
                    // Dispose after the old text fields have left the widget tree.
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => fields.dispose(),
                    );
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) >= 22) {
                  return Column(
                    children: [start, const SizedBox(height: 16), end],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: start),
                    const SizedBox(width: 12),
                    Expanded(child: end),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.semester == null ? '创建学期' : '编辑学期')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _form,
                child: ListView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Text('校园时间 · ${widget.campusTimeZone}'),
                    const SizedBox(height: 16),
                    if (_error != null) ProblemBanner(_error!),
                    TextFormField(
                      key: const ValueKey('semester-name'),
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '学期名称',
                        hintText: '例如：2026 秋季学期',
                      ),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? '请输入学期名称' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('first-monday'),
                      controller: _monday,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: '第 1 教学周的周一',
                        helperText: '格式 YYYY-MM-DD；日期按校园时区解释',
                        helperMaxLines: 3,
                        suffixIcon: IconButton(
                          tooltip: '选择周一',
                          onPressed: _pickMonday,
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      validator: (value) {
                        final date = _parseDate(value ?? '');
                        if (date == null) return '请输入有效日期，例如 2026-08-31';
                        return date.weekday == 1 ? null : '第 1 教学周必须从周一开始';
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('total-weeks'),
                      controller: _weeks,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '总周数'),
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                          ? null
                          : '请输入大于 0 的整数',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '每日节次',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('每天可分别设置。初始时间仅供修改，请按学校作息调整；没有节次的日期可以留空。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          ChoiceChip(
                            label: Text(weekdayNames[day - 1]),
                            selected: day == _day,
                            onSelected: (_) => setState(() {
                              _day = day;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _copyDay,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('复制到其他天'),
                      ),
                    ),
                    if (_periods[_day]!.isEmpty)
                      const SurfaceCard(child: Text('当天未设置节次。可添加节次，也可保持为空。')),
                    for (var i = 0; i < _periods[_day]!.length; i++)
                      _periodRow(i),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        final rows = _periods[_day]!;
                        final previous = rows.isEmpty
                            ? 470
                            : (_parseTime(rows.last.end.text) ?? 470);
                        final start = math.min(previous + 10, 1438);
                        rows.add(
                          _PeriodFields(
                            PeriodTime.format(start),
                            PeriodTime.format(math.min(start + 45, 1439)),
                          ),
                        );
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('添加节次'),
                    ),
                    const SizedBox(height: 20),
                    if (widget.semester?.id != widget.currentSemesterId ||
                        widget.semester == null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _makeCurrent,
                        onChanged: (value) =>
                            setState(() => _makeCurrent = value!),
                        title: const Text('设为当前学期'),
                        subtitle: const Text('第一个学期会自动设为当前学期；历史学期会保留。'),
                      )
                    else
                      const Text('此学期当前正在使用，编辑不会移除历史记录。'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('save-semester'),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? '正在保存…' : '保存学期'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
