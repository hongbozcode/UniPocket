import 'package:flutter/material.dart';

import '../semesters/model.dart';
import '../semesters/planner.dart';
import '../timetable/model.dart';
import '../ui/design.dart';
import 'candidate_editor.dart';
import 'model.dart';
import 'import_widgets.dart';

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
    FocusManager.instance.primaryFocus?.unfocus();
    // Submit failures sit beside the action that failed. This also agrees
    // with dialog focus restoration, which reveals that same action again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_preview == null ? 0 : _scroll.position.maxScrollExtent);
      }
    });
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
      _showError('没能读出课表，请再试一次。');
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
      _showError('暂时没能核对课表，请再试一次。');
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
        title: const Text('加入这个学期吗？'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                semester.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text('准备加入 ${preview.selectedCount} 门课程。'),
              if (preview.conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '有上课时间重叠。如果这就是学校的安排，可以一起保留。',
                  style: TextStyle(height: 1.6),
                ),
                ImportConflicts(preview.conflicts),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('keep-reviewing-import'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续核对'),
          ),
          FilledButton(
            key: const ValueKey('save-import'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(preview.conflicts.isEmpty ? '确认导入' : '保留并导入'),
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
      _showError('刚刚发现了新的时间重叠，请再看一眼后确认。');
    } on InputProblem catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('这次没能保存，请再试一次。\n没有加入任何新课程，原来的课表还在。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _row(ImportRow row) => ImportCandidateCard(
    key: ValueKey('candidate-${row.candidate.id}'),
    row: row,
    enabled: !_loading && !_saving,
    onEdit: () => _edit(row.candidate),
    onSelected: (selected) {
      _candidates = [
        for (final c in _candidates)
          if (c.id == row.candidate.id) c.copyWith(selected: selected) else c,
      ];
      _refresh();
    },
  );

  Widget _summary(ImportPreview preview) {
    final pending = preview.rows
        .where((r) => r.candidate.selected && r.errors.isNotEmpty)
        .length;
    final skipped = preview.rows.length - preview.selectedCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lavenderSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '共 ${preview.rows.length} 门课程',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '选中 ${preview.selectedCount} 门',
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pending > 0)
                Text(
                  '待核对 $pending 门',
                  style: const TextStyle(color: Color(0xff86631b)),
                ),
              if (skipped > 0)
                Text(
                  '已跳过 $skipped 门',
                  style: const TextStyle(color: Color(0xff73819a)),
                ),
            ],
          ),
          if (pending > 0 || preview.selectedCount == 0) ...[
            const SizedBox(height: 10),
            Text(
              pending > 0 ? '把待核对的信息补好，或先取消勾选。' : '勾选想加入课表的课程，就可以继续了。',
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ],
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
              key: const ValueKey('cancel-import'),
              onPressed: _saving ? null : () => Navigator.maybePop(context),
              child: const Text('暂不导入'),
            ),
        ],
      ),
      body: SafeArea(
        child: PageContent(
          controller: _scroll,
          children: [
            PageHeading(
              _savedCount == null ? '核对一下课表' : '课表已更新',
              widget.sourceName,
              art: 'book',
              bottomSpacing: 20,
            ),
            if (_savedCount != null) ...[
              SurfaceCard(
                color: const Color(0xffe6f5ed),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DesignIcon(
                      'check',
                      color: Color(0xff198568),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '成功加入 $_savedCount 门课程',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已保存到“${_state!.semesters.singleWhere((s) => s.id == _semesterId).name}”。',
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.planner.reminderAvailability,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff73819a),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.maybePop(context, true),
                child: const Text('回到课表'),
              ),
            ] else ...[
              if (_error != null && _preview == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ImportNotice(_error!, error: true),
                ),
              if (_loading || (_saving && !_confirming)) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _saving ? '正在把课程加入课表…' : '正在整理课表…',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff73819a),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_state != null && _state!.semesters.isEmpty)
                const ImportNotice(
                  '先准备一个学期',
                  message: '到“设置”添加学期和上课时间，再来导入课表。',
                ),
              if (_state != null && _state!.semesters.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey('import-semester-$_semesterId'),
                  initialValue: _semesterId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '导入到哪个学期',
                    helperText: '校园时间 · ${_state!.campusTimeZone}',
                    helperStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff73819a),
                    ),
                  ),
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
                const SizedBox(height: 20),
              ],
              if (_preview != null) ...[
                _summary(_preview!),
                const SizedBox(height: 16),
                if (_candidates.isEmpty)
                  const ImportNotice('这份课表里没有找到课程', message: '可以返回检查文件，再重新导入。'),
                for (final row in _preview!.rows) _row(row),
                if (_preview!.conflicts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      color: const Color(0xfffff4d2),
                      child: ExpansionTile(
                        key: const ValueKey('import-conflicts'),
                        title: const Text(
                          '有上课时间重叠',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${_preview!.conflicts.length} 处 · 点开核对，也可以确认保留',
                          style: const TextStyle(fontSize: 12),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        children: [ImportConflicts(_preview!.conflicts)],
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ImportNotice(_error!, error: true),
                  ),
                if (_preview!.canSubmit)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '确认后，选中的课程会一起加入这个学期。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff73819a),
                        height: 1.6,
                      ),
                    ),
                  ),
                FilledButton(
                  key: const ValueKey('confirm-import'),
                  onPressed: _loading || _saving || !_preview!.canSubmit
                      ? null
                      : _submit,
                  child: _saving && !_confirming
                      ? const Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              key: ValueKey('import-save-progress'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            Text('正在加入课表…'),
                          ],
                        )
                      : Text('导入 ${_preview!.selectedCount} 门课程'),
                ),
              ],
              if (_error != null && _preview == null && !_loading && !_saving)
                TextButton(
                  onPressed: _state == null ? _load : _refresh,
                  child: const Text('重新读取'),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
