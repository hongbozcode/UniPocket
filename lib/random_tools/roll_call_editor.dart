import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'roll_call.dart';

class RollCallEditor extends StatefulWidget {
  const RollCallEditor({required this.planner, this.list, super.key});
  final SemesterPlanner planner;
  final RollCallList? list;
  @override
  State<RollCallEditor> createState() => _RollCallEditorState();
}

class _MemberFields {
  _MemberFields(RollCallMember member)
    : id = member.id,
      name = TextEditingController(text: member.name),
      detail = TextEditingController(text: member.detail);
  final int id;
  final TextEditingController name;
  final TextEditingController detail;
  void dispose() {
    name.dispose();
    detail.dispose();
  }
}

class _RollCallEditorState extends State<RollCallEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.list?.name ?? '');
  late final _members = [
    for (final m
        in widget.list?.members ?? [const RollCallMember(id: 1, name: '')])
      _MemberFields(m),
  ];
  late int _nextId = _members.fold(0, (int n, m) => m.id > n ? m.id : n) + 1;
  final _removed = <_MemberFields>[];
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final m in [..._members, ..._removed]) {
      m.dispose();
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
      final list = await widget.planner.saveRollCallList(
        id: widget.list?.id,
        name: _name.text,
        members: [
          for (final m in _members)
            RollCallMember(id: m.id, name: m.name.text, detail: m.detail.text),
        ],
      );
      if (mounted) Navigator.pop(context, list);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，原名单与轮次未改变。请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.list == null ? '新建名单' : '管理名单'),
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
                    decoration: const InputDecoration(labelText: '名单名称'),
                    validator: (s) =>
                        s == null || s.trim().isEmpty ? '请为名单命名' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('同名成员分别保留，可填写学号或备注区分。仅用于点名，不与其他工具共享。'),
                  if (widget.list != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: ProblemBanner(
                        '保存修改将清除本次结果与本轮已抽记录，开始新一轮；取消编辑保留原进度。',
                      ),
                    ),
                  for (final m in _members)
                    Padding(
                      key: ValueKey('member-row-${m.id}'),
                      padding: const EdgeInsets.only(top: 18),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '成员 ${m.id.toString().padLeft(4, '0')}',
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: '移除成员 ${m.id}',
                                    onPressed: _saving
                                        ? null
                                        : () => setState(() {
                                            _members.remove(m);
                                            _removed.add(m);
                                          }),
                                    icon: const Icon(Icons.close, size: 20),
                                  ),
                                ],
                              ),
                              TextFormField(
                                key: ValueKey('member-name-${m.id}'),
                                controller: m.name,
                                enabled: !_saving,
                                decoration: const InputDecoration(
                                  labelText: '姓名',
                                ),
                                validator: (s) => s == null || s.trim().isEmpty
                                    ? '请输入姓名或移除该成员'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: ValueKey('member-detail-${m.id}'),
                                controller: m.detail,
                                enabled: !_saving,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  labelText: '学号或备注（可选）',
                                ),
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
                            _members.add(
                              _MemberFields(
                                RollCallMember(id: _nextId++, name: ''),
                              ),
                            );
                          }),
                    icon: const DesignIcon('plus'),
                    label: const Text('添加成员'),
                  ),
                  Text('共 ${_members.length} 人；空名单可以保存，添加成员后才能点名。'),
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
