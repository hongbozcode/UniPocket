import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'course_change.dart';
import 'model.dart';

class CourseImpactPage extends StatefulWidget {
  const CourseImpactPage({
    required this.planner,
    required this.impact,
    required this.campusTimeZone,
    super.key,
  });
  final SemesterPlanner planner;
  final CourseChangeImpact impact;
  final String campusTimeZone;

  @override
  State<CourseImpactPage> createState() => _CourseImpactPageState();
}

class _CourseImpactPageState extends State<CourseImpactPage> {
  final _choices = <(int, DateTime), OrphanChoice>{};
  final _scroll = ScrollController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      try {
        await widget.planner.applyCourseChange(
          widget.impact,
          choices: _choices,
        );
      } on CourseConflict catch (e) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('上课时间冲突'),
            content: SingleChildScrollView(child: Text(e.message)),
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
        await widget.planner.applyCourseChange(
          widget.impact,
          choices: _choices,
          allowConflicts: true,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on InputProblem catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，原课程与例外保持不变，请重试。');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_error != null) _scroll.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final impact = widget.impact;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('确认安排变更')),
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
                    color: courseTint(impact.draft.colorIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          impact.draft.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${impact.course.schedules.length} 个原安排 → ${impact.draft.schedules.length} 个上课安排',
                        ),
                        const SizedBox(height: 8),
                        Text('${impact.retained.length} 项调停课仍有效，将保留原课次关联。'),
                        Text('${impact.orphaned.length} 项例外失去原课次关联，请逐项选择。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final e in impact.retained)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SurfaceCard(
                        color: lavenderSoft,
                        child: Text(
                          '保留${e.isCancelled ? '停课' : '调课'} · 原课次 ${dateText(e.originalDate)}'
                          '${e.isCancelled ? '' : '\n${dateText(e.targetDate)} · ${PeriodTime.format(e.startMinutes)}–${PeriodTime.format(e.endMinutes)}\n${e.location}'}',
                        ),
                      ),
                    ),
                  for (var i = 0; i < impact.orphaned.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const DesignIcon(
                                  'warning',
                                  color: Color(0xffb32643),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '失去关联 · ${impact.orphaned[i].isCancelled ? '原停课' : '原调课'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '原课次 ${dateText(impact.orphaned[i].originalDate)}',
                            ),
                            Text(
                              '${dateText(impact.orphaned[i].targetDate)} · '
                              '${PeriodTime.format(impact.orphaned[i].startMinutes)}–${PeriodTime.format(impact.orphaned[i].endMinutes)}\n'
                              '${impact.orphaned[i].location.isEmpty ? '地点未填写' : impact.orphaned[i].location}',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              impact.orphaned[i].isCancelled
                                  ? '此项原为停课。若选择保留，将在上述日期和时间新增一次独立补课；选择删除则不安排上课。'
                                  : '保留后仍属于本课程，但不再随重复安排变化。',
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<OrphanChoice>(
                              key: ValueKey('orphan-choice-$i'),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '请选择处理方式',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: OrphanChoice.keepIndependent,
                                  child: Text('保留为独立补课'),
                                ),
                                DropdownMenuItem(
                                  value: OrphanChoice.delete,
                                  child: Text('删除此例外'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _choices[impact.orphaned[i].key] = value!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Text(
                    '确认前不会写入。已有独立补课和学习任务保持保留；时间冲突会再次提示。',
                    style: TextStyle(fontSize: 13, color: Color(0xff52617a)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? '正在保存…' : '确认变更'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('返回修改'),
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
