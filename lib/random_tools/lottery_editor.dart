import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'lottery.dart';

class LotteryEditor extends StatefulWidget {
  const LotteryEditor({required this.planner, this.pool, super.key});
  final SemesterPlanner planner;
  final LotteryPool? pool;
  @override
  State<LotteryEditor> createState() => _LotteryEditorState();
}

class _LotteryEditorState extends State<LotteryEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.pool?.name ?? '');
  late final _items = [
    for (final text in widget.pool?.items ?? [''])
      TextEditingController(text: text),
  ];
  // Keep removed controllers alive until their fields have left the tree.
  final _removed = <TextEditingController>[];
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final c in [..._items, ..._removed]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.planner.saveLotteryPool(
        id: widget.pool?.id,
        name: _name.text,
        items: [for (final c in _items) c.text],
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，原签池与轮次未改变。请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = _items
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final duplicate = texts.toSet().length != texts.length;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pool == null ? '新建签池' : '编辑签池'),
          leading: IconButton(
            tooltip: '取消编辑',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const DesignIcon('back'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _name,
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: '签池名称'),
                      validator: (s) =>
                          s == null || s.trim().isEmpty ? '请为签池命名' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('每张签独立录入，可换行、不限示例长度。仅保存到抽签工具，不与其他工具共享。'),
                    if (widget.pool != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: ProblemBanner(
                          '保存修改将清除本次结果与本轮记录，开始新一轮；取消编辑保留原进度。',
                        ),
                      ),
                    if (duplicate)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: ProblemBanner('有重复签文：每张签仍独立占一份机会，保存不会合并。'),
                      ),
                    for (var i = 0; i < _items.length; i++)
                      Padding(
                        key: ObjectKey(_items[i]),
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('签 ${i + 1}')),
                                    IconButton(
                                      tooltip: '移除签 ${i + 1}',
                                      onPressed: _saving
                                          ? null
                                          : () => setState(() {
                                              _removed.add(_items.removeAt(i));
                                            }),
                                      icon: const Icon(Icons.close, size: 20),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  key: ValueKey('ticket-text-${i + 1}'),
                                  controller: _items[i],
                                  enabled: !_saving,
                                  minLines: 2,
                                  maxLines: null,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: '签文',
                                  ),
                                  validator: (s) =>
                                      s == null || s.trim().isEmpty
                                      ? '请输入签文或移除该签'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _items.add(TextEditingController());
                            }),
                      icon: const DesignIcon('plus'),
                      label: const Text('添加签项'),
                    ),
                    Text('共 ${_items.length} 项；空签池可以保存，添加签项后才能抽签。'),
                    if (_error != null) ProblemBanner(_error!),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? '保存中…' : '保存到本机'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
