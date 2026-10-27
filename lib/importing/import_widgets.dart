import 'package:flutter/material.dart';

import '../timetable/model.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'model.dart';

class ImportNotice extends StatelessWidget {
  const ImportNotice(this.title, {this.message, this.error = false, super.key});
  final String title;
  final String? message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? const Color(0xffffedf0) : const Color(0xfffff4d2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignIcon(
            'warning',
            size: 18,
            color: error ? const Color(0xffa6374a) : const Color(0xff86631b),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String importScheduleText(ScheduleDraft schedule) {
  final weekday = schedule.weekday >= 1 && schedule.weekday <= 7
      ? weekdayNames[schedule.weekday - 1]
      : '星期待核对';
  final periods = schedule.startPeriod == schedule.endPeriod
      ? '第 ${schedule.startPeriod} 节'
      : '第 ${schedule.startPeriod}–${schedule.endPeriod} 节';
  final weeks = schedule.weeks.toList()..sort();
  final ranges = <String>[];
  for (var i = 0; i < weeks.length; i++) {
    final start = weeks[i];
    while (i + 1 < weeks.length && weeks[i + 1] == weeks[i] + 1) {
      i++;
    }
    ranges.add(start == weeks[i] ? '$start' : '$start–${weeks[i]}');
  }
  return '$weekday · $periods\n'
      '${schedule.location.trim().isEmpty ? '地点待补充' : schedule.location} · '
      '${ranges.isEmpty ? '教学周待核对' : '第 ${ranges.join('、')} 周'}';
}

class ImportCandidateCard extends StatefulWidget {
  const ImportCandidateCard({
    required this.row,
    required this.enabled,
    required this.onSelected,
    required this.onEdit,
    super.key,
  });
  final ImportRow row;
  final bool enabled;
  final ValueChanged<bool> onSelected;
  final VoidCallback onEdit;

  @override
  State<ImportCandidateCard> createState() => _ImportCandidateCardState();
}

class _ImportCandidateCardState extends State<ImportCandidateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.row.candidate;
    final needsCheck = widget.row.errors.isNotEmpty;
    final showDetails = c.selected || _expanded;
    final status = !c.selected
        ? c.duplicateDescription == null
              ? '已跳过'
              : '重复课程 · 已跳过'
        : needsCheck
        ? '需要核对'
        : c.schoolIdentity && widget.row.duplicateScheduleCount > 0
        ? '重复安排自动跳过 · 仅加入新安排'
        : c.duplicateDescription == null
        ? '准备导入'
        : '重复课程 · 仍将导入';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                key: ValueKey('select-import-${c.id}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  c.name.trim().isEmpty ? '还没有课程名称' : c.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: needsCheck && c.selected
                          ? const Color(0xff86631b)
                          : const Color(0xff73819a),
                    ),
                  ),
                ),
                value: c.selected,
                secondary: c.selected
                    ? null
                    : IconButton(
                        key: ValueKey('details-import-${c.id}'),
                        tooltip: _expanded ? '收起详情' : '查看详情',
                        onPressed: widget.enabled
                            ? () => setState(() => _expanded = !_expanded)
                            : null,
                        icon: RotatedBox(
                          quarterTurns: _expanded ? 1 : 0,
                          child: const DesignIcon('right', size: 18),
                        ),
                      ),
                onChanged: widget.enabled
                    ? (value) => widget.onSelected(value!)
                    : null,
              ),
              if (showDetails) ...[
                if (widget.row.duplicateScheduleCount > 0)
                  Text(
                    '${widget.row.duplicateScheduleCount} 个重复安排将自动跳过',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff73819a),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: courseTint(c.colorIndex < 0 ? 0 : c.colorIndex)
                        .withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < c.schedules.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                          child: Text(
                            importScheduleText(c.schedules[i]),
                            style: const TextStyle(fontSize: 13, height: 1.7),
                          ),
                        ),
                      if (c.teacher.isNotEmpty)
                        Text(
                          '教师 ${c.teacher}',
                          style: const TextStyle(fontSize: 12, height: 1.7),
                        ),
                    ],
                  ),
                ),
                if (c.selected && needsCheck)
                  ImportNotice(
                    widget.row.errors.first,
                    message: widget.row.errors.length > 1
                        ? '还有 ${widget.row.errors.length - 1} 处信息需要核对，点“修改信息”查看。'
                        : '可以修改信息，也可以先取消勾选。',
                  ),
                if (!c.selected && needsCheck)
                  const Text(
                    '这门课暂不导入，你可以查看详情后再决定。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff73819a),
                      height: 1.6,
                    ),
                  ),
              ],
              if (c.selected || _expanded)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (c.selected || _expanded)
                      TextButton(
                        key: ValueKey('edit-import-${c.id}'),
                        onPressed: widget.enabled ? widget.onEdit : null,
                        child: const Text('修改信息'),
                      ),
                    if (c.selected)
                      TextButton(
                        key: ValueKey('details-import-${c.id}'),
                        onPressed: widget.enabled
                            ? () => setState(() => _expanded = !_expanded)
                            : null,
                        child: Text(_expanded ? '收起详情' : '查看详情'),
                      ),
                  ],
                ),
              if (_expanded) ...[
                const Divider(height: 16),
                Text(
                  '来源：${c.sourceLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff73819a),
                    height: 1.6,
                  ),
                ),
                if (c.duplicateDescription != null)
                  Text(
                    c.duplicateDescription!,
                    style: const TextStyle(fontSize: 12, height: 1.6),
                  ),
                for (final error in widget.row.errors)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '• $error',
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ImportConflicts extends StatelessWidget {
  const ImportConflicts(this.conflicts, {super.key});
  final List<String> conflicts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final conflict in conflicts)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfffff8e5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            conflict,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
    ],
  );
}
