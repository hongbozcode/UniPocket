import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../ui/design.dart';
import 'model.dart';
import 'messages.dart';
import 'import_widgets.dart';

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
      if (value == null) throw const InputProblem('节次请填数字，例如第 1 节填“1”。');
      return value;
    }

    final selected = <int>{};
    for (final part in weeks.text.trim().split(RegExp(r'[、,，\s]+'))) {
      final range = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(part);
      if (range == null) throw const InputProblem('教学周可以这样填：1-8、10、12。');
      final first = int.parse(range[1]!);
      final last = int.parse(range[2] ?? range[1]!);
      if (first < 1 || last < first || last > totalWeeks) {
        throw InputProblem('这个学期有 $totalWeeks 周，请在 1–$totalWeeks 周内填写。');
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
        throw const InputProblem('核对好后，勾选“以上信息已核对”就能继续。');
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
      setState(() => _error = importGuidance(error.message));
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? key,
    String? hint,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      key: key,
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, helperText: hint),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('修改课程信息')),
    body: SafeArea(
      child: PageContent(
        controller: _scroll,
        children: [
          PageHeading(
            '把课程信息补完整',
            widget.candidate.sourceLabel,
            art: 'book',
            bottomSpacing: 20,
          ),
          if (widget.candidate.errors.isNotEmpty) ...[
            ImportNotice(
              '这几处需要你看一下',
              message: widget.candidate.errors.map((e) => '• $e').join('\n'),
            ),
            const SizedBox(height: 16),
          ],
          SurfaceCard(
            child: Column(
              children: [
                _field('课程名称', _name, key: const ValueKey('import-name')),
                _field('教师（选填）', _teacher),
              ],
            ),
          ),
          for (var i = 0; i < _schedules.length; i++)
            Padding(
              key: ObjectKey(_schedules[i]),
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
                    DropdownButtonFormField<int>(
                      initialValue: switch (int.tryParse(
                        _schedules[i].weekday.text,
                      )) {
                        final int day when day >= 1 && day <= 7 => day,
                        _ => null,
                      },
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '上课星期'),
                      items: [
                        for (var day = 1; day <= 7; day++)
                          DropdownMenuItem(
                            value: day,
                            child: Text(weekdayNames[day - 1]),
                          ),
                      ],
                      onChanged: (day) => _schedules[i].weekday.text = '$day',
                    ),
                    const SizedBox(height: 16),
                    _field('开始节次', _schedules[i].start, number: true),
                    _field('结束节次', _schedules[i].end, number: true),
                    _field('上课地点（选填）', _schedules[i].location),
                    _field('教学周', _schedules[i].weeks, hint: '例如 1-8、10、12'),
                    TextButton(
                      onPressed: () {
                        final removed = _schedules[i];
                        setState(() => _schedules.removeAt(i));
                        removed.dispose();
                      },
                      child: const Text('删除这条安排'),
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
          if (widget.candidate.errors.isNotEmpty)
            CheckboxListTile(
              key: const ValueKey('import-reviewed'),
              value: _reviewed,
              onChanged: (value) => setState(() => _reviewed = value!),
              title: const Text('以上信息已核对'),
              contentPadding: EdgeInsets.zero,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImportNotice(_error!, error: true),
            ),
          FilledButton(
            key: const ValueKey('apply-import-correction'),
            onPressed: _apply,
            child: const Text('完成核对'),
          ),
        ],
      ),
    ),
  );
}
