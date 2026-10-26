import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../timetable/model.dart';
import '../ui/course_palette.dart';
import '../ui/design.dart';
import 'candidate_editor.dart';
import 'model.dart';

/// The parser integration seam. Real school file selection is supplied by the
/// school adapter; production UI never creates synthetic candidates here.
class ImportPreviewPage extends StatefulWidget {
  const ImportPreviewPage({
    required this.planner,
    required this.sourceName,
    required this.loadCandidates,
    this.initialSemesterId,
    super.key,
  });
  final SemesterPlanner planner;
  final String sourceName;
  final Future<List<ImportCandidate>> Function() loadCandidates;
  final int? initialSemesterId;

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  List<ImportCandidate> _candidates = [];
  PlannerState? _state;
  int? _semesterId;
  ImportPreview? _preview;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _confirming = false;
  int? _savedCount;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final candidates = await widget.loadCandidates();
      final state = await widget.planner.load();
      if (!mounted) return;
      _candidates = candidates;
      _state = state;
      _semesterId = state.semesters.any((s) => s.id == widget.initialSemesterId)
          ? widget.initialSemesterId
          : state.currentSemesterId ?? state.semesters.firstOrNull?.id;
      await _refresh();
    } catch (_) {
      _showError('解析结果加载失败，请重试。已有课表保持完整。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    try {
      if (_semesterId != null) {
        final preview = await widget.planner.previewImport(
          ImportDraft(semesterId: _semesterId!, candidates: _candidates),
        );
        if (mounted) setState(() => _preview = preview);
      }
    } on InputProblem catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('无法检查候选结果，请重试。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(ImportCandidate candidate) async {
    final semester = _state!.semesters.singleWhere((s) => s.id == _semesterId);
    final corrected = await Navigator.push<ImportCandidate>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImportCandidateEditor(candidate: candidate, semester: semester),
      ),
    );
    if (!mounted || corrected == null) return;
    _candidates = [
      for (final c in _candidates)
        if (c.id == corrected.id) corrected else c,
    ];
    await _refresh();
  }

  Future<void> _submit() async {
    final preview = _preview;
    if (_saving || preview == null || !preview.canSubmit) return;
    // Lock edits, navigation and repeated taps while the confirmation is open.
    setState(() {
      _saving = true;
      _confirming = true;
    });
    final semester = _state!.semesters.singleWhere((s) => s.id == _semesterId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('将 ${preview.selectedCount} 项课程一次保存到“${semester.name}”。'),
              const SizedBox(height: 12),
              const Text('未选中的项目不会保存。'),
              if (preview.conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('以下时间冲突需要你确认保留：'),
                Text(preview.conflicts.join('\n')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续核对'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(preview.conflicts.isEmpty ? '保存到目标学期' : '保留冲突并保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed != true) {
      setState(() => _saving = false);
      return;
    }
    try {
      final ids = await preview.commit(
        allowConflicts: preview.conflicts.isNotEmpty,
      );
      if (mounted) {
        setState(() {
          _savedCount = ids.length;
          _error = null;
        });
        if (_scroll.hasClients) _scroll.jumpTo(0);
      }
    } on CourseConflict {
      await _refresh();
      _showError('课表冲突已变化，请重新核对并确认。');
    } on InputProblem catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('导入失败，未保存任何本次导入内容。请重试。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _row(ImportRow row) {
    final c = row.candidate;
    final color = c.colorIndex < 0 ? 0 : c.colorIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        color: c.selected ? courseTint(color) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.sourceLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xff52617a)),
            ),
            const SizedBox(height: 8),
            Text(
              c.name.trim().isEmpty ? '课程名称待修正' : c.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (c.teacher.isNotEmpty) Text('教师：${c.teacher}'),
            for (final schedule in c.schedules)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '星期 ${schedule.weekday} · 第 ${schedule.startPeriod}–${schedule.endPeriod} 节\n'
                  '${schedule.location.isEmpty ? '地点未填写' : schedule.location}\n'
                  '第 ${(schedule.weeks.toList()..sort()).join('、')} 周',
                ),
              ),
            if (c.duplicateDescription != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('重复识别 · 默认跳过\n${c.duplicateDescription}'),
              ),
            if (row.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ProblemBanner(
                '${c.selected ? '需要修正或排除' : '已排除，不会保存'}\n${row.errors.join('\n')}',
              ),
            ],
            CheckboxListTile(
              key: ValueKey('select-import-${c.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(c.selected ? '已选择导入' : '已排除'),
              value: c.selected,
              onChanged: _loading || _saving
                  ? null
                  : (selected) {
                      _candidates = [
                        for (final other in _candidates)
                          if (other.id == c.id)
                            other.copyWith(selected: selected)
                          else
                            other,
                      ];
                      _refresh();
                    },
            ),
            OutlinedButton(
              key: ValueKey('edit-import-${c.id}'),
              onPressed: _loading || _saving ? null : () => _edit(c),
              child: const Text('核对并修正'),
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
      appBar: AppBar(
        title: const Text('导入预览'),
        actions: [
          if (_savedCount == null)
            TextButton(
              onPressed: _saving ? null : () => Navigator.maybePop(context),
              child: const Text('取消导入'),
            ),
        ],
      ),
      body: SafeArea(
        child: PageContent(
          controller: _scroll,
          children: [
            PageHeading(
              _savedCount == null ? '先核对，再加入课表' : '导入完成',
              widget.sourceName,
              art: 'book',
            ),
            if (_savedCount != null) ...[
              SurfaceCard(
                color: lavenderSoft,
                child: Text(
                  '已将 $_savedCount 项课程保存到目标学期。\n${widget.planner.reminderAvailability}',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.maybePop(context, true),
                child: const Text('返回课表'),
              ),
            ] else ...[
              if (_error != null) ProblemBanner(_error!),
              if (_loading || (_saving && !_confirming)) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(_saving ? '正在提交，请稍候…' : '正在加载与检查候选结果…'),
                ),
                const SizedBox(height: 16),
              ],
              if (_state != null && _state!.semesters.isEmpty)
                const SurfaceCard(child: Text('请先在设置中添加学期，再导入课表。')),
              if (_state != null && _state!.semesters.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey('import-semester-$_semesterId'),
                  initialValue: _semesterId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '目标学期'),
                  items: [
                    for (final semester in _state!.semesters)
                      DropdownMenuItem(
                        value: semester.id,
                        child: Text(semester.name),
                      ),
                  ],
                  onChanged: _loading || _saving
                      ? null
                      : (id) {
                          _semesterId = id;
                          _refresh();
                        },
                ),
                const SizedBox(height: 16),
                Text(
                  '校园时间 ${_state!.campusTimeZone}',
                  style: const TextStyle(color: Color(0xff73819a)),
                ),
                const SizedBox(height: 16),
              ],
              if (_preview != null) ...[
                SurfaceCard(
                  color: lavenderSoft,
                  child: Text(
                    '候选 ${_candidates.length} 项 · 选择 ${_preview!.selectedCount} 项\n'
                    '未解决的错误须修正或排除；取消不会更改已有课表。',
                  ),
                ),
                const SizedBox(height: 16),
                if (_candidates.isEmpty)
                  const SurfaceCard(child: Text('没有可导入的候选课程，请返回检查文件。')),
                for (final row in _preview!.rows) _row(row),
                if (_preview!.conflicts.isNotEmpty) ...[
                  SurfaceCard(
                    color: const Color(0xfffff4d2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '时间冲突 · 需要单独确认',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(_preview!.conflicts.join('\n')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _loading || _saving || !_preview!.canSubmit
                      ? null
                      : _submit,
                  child: Text('确认导入 ${_preview!.selectedCount} 项'),
                ),
              ],
              if (_error != null && !_loading && !_saving)
                TextButton(
                  onPressed: _state == null ? _load : _refresh,
                  child: const Text('重试'),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
