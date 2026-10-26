import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'group_editor.dart';
import 'groups.dart';
import 'groups_visual.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;
  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(vsync: this);
  late final _random = widget.random ?? Random();
  final _amount = TextEditingController(text: '4');
  List<GroupList> _lists = [];
  GroupList? _selected;
  List<List<GroupMember>>? _pending, _result;
  GroupMode _mode = GroupMode.limit;
  bool _loading = true, _working = false;
  int _epoch = 0;
  String? _error, _hint;
  bool get _locked => _loading || _working;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load([int? selectedId]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await widget.planner.loadGroupLists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _selected =
            lists.where((l) => l.id == selectedId).firstOrNull ??
            lists.firstOrNull;
        _loading = false;
        _result = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '无法读取分组名单，请重试。已有数据不会被清空。';
        });
      }
    }
  }

  Future<void> _edit({bool create = false}) async {
    if (_locked) return;
    final saved = await Navigator.push<GroupList>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditor(
          planner: widget.planner,
          list: create ? null : _selected,
        ),
      ),
    );
    if (mounted && saved != null) {
      _hint = null;
      await _load(saved.id);
    }
  }

  Future<void> _choose() async {
    if (_locked) return;
    final choice = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .65,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '我的分组名单',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              for (final list in _lists)
                ListTile(
                  title: Text(list.name),
                  subtitle: Text('${list.members.length}人'),
                  selected: list.id == _selected?.id,
                  onTap: () => Navigator.pop(context, list.id),
                ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, -1),
                icon: const DesignIcon('plus'),
                label: const Text('新建名单'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == -1) {
      await _edit(create: true);
    } else {
      setState(() {
        _selected = _lists.firstWhere((l) => l.id == choice);
        _invalidate();
      });
    }
  }

  void _invalidate() {
    _result = null;
    _hint = null;
    _error = null;
  }

  Future<void> _start() async {
    if (_locked || _selected == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _error = '请输入大于 0 的整数');
      return;
    }
    final epoch = ++_epoch;
    setState(() {
      _working = true;
      _invalidate();
    });
    try {
      final groups = await widget.planner.makeGroups(
        _selected!.id,
        mode: _mode,
        amount: amount,
        random: _random,
      );
      if (!mounted || epoch != _epoch) return;
      _motion.value = 0;
      setState(() => _pending = groups);
      _motion.duration = MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : groupDuration(_selected!.members.length);
      // Wait for real tag positions before flying the cards into their slots.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || epoch != _epoch) return;
      await _motion.forward().orCancel;
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _result = groups;
        _hint = null;
      });
    } on TickerCanceled {
      // Cancellation discards the temporary grouping; lists remain saved.
    } on FormatException catch (e) {
      if (mounted && epoch == _epoch) setState(() => _error = e.message);
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() => _error = '分组未完成，请重新读取名单后重试。');
      }
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() {
          _working = false;
          _pending = null;
        });
      }
    }
  }

  void _cancel() {
    ++_epoch;
    _motion.stop(canceled: true);
    setState(() {
      _working = false;
      _pending = null;
      _result = null;
      _hint = '已取消分组';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _working) _cancel();
  }

  @override
  void dispose() {
    ++_epoch;
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    _amount.dispose();
    super.dispose();
  }

  Widget _quantity() => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, box) {
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '减少数量',
                onPressed: _locked ? null : () => _step(-1),
                style: IconButton.styleFrom(backgroundColor: lavenderSoft),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  key: const ValueKey('group-amount'),
                  controller: _amount,
                  enabled: !_locked,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    isDense: true,
                    semanticCounterText: _mode == GroupMode.limit
                        ? '每组人数上限'
                        : '组数',
                  ),
                  onChanged: (_) => setState(_invalidate),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '增加数量',
                onPressed: _locked ? null : () => _step(1),
                style: IconButton.styleFrom(backgroundColor: lavenderSoft),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 8),
              Text(_mode == GroupMode.limit ? '人' : '组'),
            ],
          );
          final label = Text(
            _mode == GroupMode.limit ? '每组最多' : '分成几组',
            style: const TextStyle(fontWeight: FontWeight.w700),
          );
          return box.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 8), controls],
                )
              : Row(
                  children: [
                    Expanded(child: label),
                    controls,
                  ],
                );
        },
      ),
    ),
  );

  void _step(int delta) {
    final value = int.tryParse(_amount.text) ?? 0;
    setState(() {
      _amount.text = max(1, value + delta).toString();
      _invalidate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _selected;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _working) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '随机分组',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: RoundDesignButton(
              icon: 'back',
              label: '返回工具',
              onPressed: () {
                if (_working) _cancel();
                Navigator.maybePop(context);
              },
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '打散一点，遇见新伙伴',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xff8391a7)),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (list == null) ...[
                      const GroupDeck(count: 0),
                      const SizedBox(height: 20),
                      const Text(
                        '还没有分组名单，先保存一份学习伙伴名单吧。',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _edit(create: true),
                        child: const Text('新建名单'),
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: _locked ? null : _choose,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xffe7f2ff),
                                foregroundColor: inkColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const DesignIcon('users', size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${list.name} · ${list.members.length}人',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.expand_more, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _locked ? null : _edit,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('编辑名单'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xffeaf1f7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            for (final mode in GroupMode.values)
                              Expanded(
                                child: TextButton(
                                  onPressed: _locked
                                      ? null
                                      : () => setState(() {
                                          _mode = mode;
                                          _invalidate();
                                        }),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _mode == mode
                                        ? const Color(0xffd9c2f5)
                                        : Colors.transparent,
                                    foregroundColor: inkColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 6,
                                    ),
                                  ),
                                  child: Text(
                                    mode == GroupMode.count ? '按组数' : '按人数上限',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _quantity(),
                      const SizedBox(height: 16),
                      if (list.members.isEmpty)
                        const ProblemBanner('名单为空，请编辑名单添加成员后再分组。'),
                      if (_result != null)
                        Padding(
                          key: const ValueKey('group-result'),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '分组完成 · ${list.members.length} 人已分配',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xff8291a7)),
                          ),
                        ),
                      if (_pending != null || _result != null)
                        RepaintBoundary(
                          key: const ValueKey('group-scene'),
                          child: GroupsVisual(
                            key: ObjectKey(_pending ?? _result),
                            groups: (_pending ?? _result)!,
                            animation: _pending == null ? null : _motion,
                          ),
                        )
                      else
                        GroupDeck(count: list.members.length),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const ValueKey('group-start'),
                        onPressed: _locked || list.members.isEmpty
                            ? null
                            : _start,
                        icon: const DesignIcon('shuffle', color: Colors.white),
                        label: Text(
                          _working
                              ? '正在分组…'
                              : _result == null
                              ? '开始分组'
                              : '重新分组',
                        ),
                      ),
                      if (_working)
                        TextButton(
                          onPressed: _cancel,
                          child: const Text('取消分组'),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        '人数均衡，每人只出现一次',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff8391a7),
                        ),
                      ),
                    ],
                    if (_hint != null)
                      Text(_hint!, textAlign: TextAlign.center),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      ProblemBanner(_error!),
                      TextButton(
                        onPressed: _locked ? null : () => _load(list?.id),
                        child: const Text('重新读取'),
                      ),
                    ],
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
