import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'wheel_list.dart';

class WheelEditor extends StatefulWidget {
  const WheelEditor({required this.planner, this.list, super.key});
  final SemesterPlanner planner;
  final WheelList? list;
  @override
  State<WheelEditor> createState() => _WheelEditorState();
}

class _WheelEditorState extends State<WheelEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.list?.name ?? '');
  late final _items = TextEditingController(
    text: widget.list?.items.join('\n') ?? '',
  );
  var _saving = false;
  String? _error;
  List<String> get _entries => _items.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _name.dispose();
    _items.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.planner.saveWheelList(
        id: widget.list?.id,
        name: _name.text,
        items: _entries,
      );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，原列表未改变。请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final duplicate = entries.toSet().length != entries.length;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.list == null ? '新建转盘' : '编辑选项'),
          leading: IconButton(
            tooltip: '取消编辑',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const DesignIcon('back'),
          ),
        ),
        body: Center(
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
                    decoration: const InputDecoration(labelText: '列表名称'),
                    validator: (s) =>
                        s == null || s.trim().isEmpty ? '请为转盘列表命名' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _items,
                    enabled: !_saving,
                    minLines: 7,
                    maxLines: 14,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: '选项（每行一项）',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('共 ${entries.length} 项；空行不作为选项。空列表可保存，添加选项后才能转动。'),
                  if (duplicate)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: ProblemBanner('有重复文字：每一行仍是独立选项，会分别占一份机会。保存不会合并。'),
                    ),
                  const SizedBox(height: 12),
                  const Text('只保存到转盘工具，不与其他工具共享。修改后清除本次结果。'),
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
    );
  }
}
