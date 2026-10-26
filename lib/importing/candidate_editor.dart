import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../ui/design.dart';
import 'model.dart';

class ImportCandidateEditor extends StatefulWidget {
  const ImportCandidateEditor({
    required this.candidate,
    required this.semester,
    super.key,
  });
  final ImportCandidate candidate;
  final Semester semester;

  @override
  State<ImportCandidateEditor> createState() => _ImportCandidateEditorState();
}

class _ScheduleInput {
  _ScheduleInput(ScheduleDraft schedule)
    : weekday = TextEditingController(text: '${schedule.weekday}'),
      start = TextEditingController(text: '${schedule.startPeriod}'),
      end = TextEditingController(text: '${schedule.endPeriod}'),
      location = TextEditingController(text: schedule.location),
      weeks = TextEditingController(
        text: (schedule.weeks.toList()..sort()).join('、'),
      );
  final TextEditingController weekday, start, end, location, weeks;
  void dispose() {
    for (final input in [weekday, start, end, location, weeks]) {
      input.dispose();
    }
  }

  ScheduleDraft read(int totalWeeks) {
    int number(String text) {
      final value = int.tryParse(text.trim());
      if (value == null) throw const InputProblem('星期和节次须填写整数。');
      return value;
    }

    final selected = <int>{};
    for (final part in weeks.text.trim().split(RegExp(r'[、,，\s]+'))) {
      final range = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(part);
      if (range == null) throw const InputProblem('教学周请填写 1、3、5 或 1-8。');
      final first = int.parse(range[1]!);
      final last = int.parse(range[2] ?? range[1]!);
      if (first < 1 || last < first || last > totalWeeks) {
        throw const InputProblem('请按从小到大的有效范围填写教学周。');
      }
      selected.addAll([for (var week = first; week <= last; week++) week]);
    }
    return ScheduleDraft(
      weekday: number(weekday.text),
      startPeriod: number(start.text),
      endPeriod: number(end.text),
      location: location.text,
      weeks: selected,
    );
  }
}

class _ImportCandidateEditorState extends State<ImportCandidateEditor> {
  late final _name = TextEditingController(text: widget.candidate.name);
  late final _teacher = TextEditingController(text: widget.candidate.teacher);
  late final _schedules = widget.candidate.schedules
      .map(_ScheduleInput.new)
      .toList();
  bool _reviewed = false;
  String? _error;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _scroll.dispose();
    for (final schedule in _schedules) {
      schedule.dispose();
    }
    super.dispose();
  }

  void _apply() {
    try {
      if (widget.candidate.errors.isNotEmpty && !_reviewed) {
        throw const InputProblem('请核对识别问题，或返回预览排除此项。');
      }
      final corrected = widget.candidate.copyWith(
        name: _name.text.trim(),
        teacher: _teacher.text.trim(),
        schedules: _schedules
            .map((s) => s.read(widget.semester.totalWeeks))
            .toList(),
        errors: [],
      );
      corrected.toCourse(widget.semester.id).validate(widget.semester);
      Navigator.pop(context, corrected);
    } on InputProblem catch (error) {
      setState(() => _error = error.message);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  Widget _field(String label, TextEditingController controller, {Key? key}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          key: key,
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('修正候选课程')),
    body: SafeArea(
      child: PageContent(
        controller: _scroll,
        children: [
          PageHeading('核对课程与安排', widget.candidate.sourceLabel, art: 'book'),
          if (_error != null) ProblemBanner(_error!),
          if (widget.candidate.errors.isNotEmpty) ...[
            ProblemBanner(widget.candidate.errors.join('\n')),
            CheckboxListTile(
              key: const ValueKey('import-reviewed'),
              value: _reviewed,
              onChanged: (value) => setState(() => _reviewed = value!),
              title: const Text('我已核对并修正以上识别问题'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          SurfaceCard(
            child: Column(
              children: [
                _field('课程名称', _name, key: const ValueKey('import-name')),
                _field('教师（可不填）', _teacher),
              ],
            ),
          ),
          for (var i = 0; i < _schedules.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '上课安排 ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _field('星期（1 为周一，7 为周日）', _schedules[i].weekday),
                    _field('开始节次', _schedules[i].start),
                    _field('结束节次', _schedules[i].end),
                    _field('地点（可不填）', _schedules[i].location),
                    _field('教学周（如 1-8、10、12）', _schedules[i].weeks),
                    TextButton(
                      onPressed: () {
                        final removed = _schedules[i];
                        setState(() => _schedules.removeAt(i));
                        removed.dispose();
                      },
                      child: const Text('移除此安排'),
                    ),
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: () => setState(
              () => _schedules.add(
                _ScheduleInput(
                  ScheduleDraft(
                    weekday: 1,
                    startPeriod: 1,
                    endPeriod: 1,
                    location: '',
                    weeks: {1},
                  ),
                ),
              ),
            ),
            child: const Text('添加上课安排'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _apply, child: const Text('应用修改')),
        ],
      ),
    ),
  );
}
