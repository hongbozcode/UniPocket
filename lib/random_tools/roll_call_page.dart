import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'roll_call.dart';
import 'roll_call_editor.dart';
import 'roll_call_visual.dart';

class RollCallPage extends StatefulWidget {
  const RollCallPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;
  @override
  State<RollCallPage> createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: rollCallDuration,
  );
  late final _random = widget.random ?? Random();
  List<RollCallList> _lists = [];
  RollCallList? _selected;
  RollCallDraw? _pending;
  bool _loading = true, _working = false, _committing = false;
  int _epoch = 0;
  String? _error;
  String? _hint;
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
      final lists = await widget.planner.loadRollCallLists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _selected =
            lists.where((l) => l.id == selectedId).firstOrNull ??
            lists.firstOrNull;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '无法读取名单，请重试。已有数据不会被清空。';
        });
      }
    }
  }

  void _replace(RollCallList list) {
    _selected = list;
    _lists = [
      for (final l in _lists)
        if (l.id == list.id) list else l,
    ];
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('保留进度'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _edit({bool create = false}) async {
    if (_locked) return;
    if (!create &&
        _selected != null &&
        !await _confirm(
          '修改名单会重置本轮',
          '保存修改将清除本次结果和本轮已抽记录，开始新一轮。取消编辑不会改变进度。',
          '继续编辑',
        )) {
      return;
    }
    if (!mounted) return;
    final saved = await Navigator.push<RollCallList>(
      context,
      MaterialPageRoute(
        builder: (_) => RollCallEditor(
          planner: widget.planner,
          list: create ? null : _selected,
        ),
      ),
    );
    if (saved != null && mounted) {
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
                '我的点名名单',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              for (final l in _lists)
                ListTile(
                  title: Text(l.name),
                  subtitle: Text(
                    '${l.members.length}人 · 第 ${l.round} 轮 · 已抽 ${l.drawn.length} 次',
                  ),
                  selected: l.id == _selected?.id,
                  trailing: l.id == _selected?.id
                      ? const DesignIcon('check')
                      : null,
                  onTap: () => Navigator.pop(context, l.id),
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
        _hint = null;
        _error = null;
      });
    }
  }

  Future<void> _reset({bool? repeat}) async {
    if (_locked || _selected == null || repeat == _selected!.repeat) return;
    final list = _selected!;
    final confirmed = await _confirm(
      repeat == null ? '开始新一轮？' : '切换模式并开始新一轮？',
      '将清除本次结果和本轮 ${list.drawn.length} 次已抽记录，所有成员重新参与。',
      '开始新一轮',
    );
    if (!mounted || !confirmed) return;
    setState(() {
      _working = true;
      _committing = true;
      _error = null;
    });
    try {
      final next = await widget.planner.resetRollCall(list.id, repeat: repeat);
      if (mounted) {
        setState(() {
          _replace(next);
          _hint = '已开始第 ${next.round} 轮';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '重置失败，原进度保留。请重试。';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _committing = false;
        });
      }
    }
  }

  Future<void> _draw() async {
    if (_locked || _selected == null || _selected!.candidates.isEmpty) return;
    final epoch = ++_epoch;
    setState(() {
      _working = true;
      _hint = null;
      _error = null;
    });
    try {
      final draw = await widget.planner.prepareRollCall(
        _selected!.id,
        random: _random,
      );
      if (!mounted || epoch != _epoch) {
        draw.cancel();
        return;
      }
      setState(() {
        _pending = draw;
      });
      _motion.duration = MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : rollCallDuration;
      await _motion.forward(from: 0).orCancel;
      if (!mounted || epoch != _epoch) {
        draw.cancel();
        return;
      }
      setState(() {
        _committing = true;
      });
      final next = await draw.complete();
      if (mounted) {
        setState(() {
          _replace(next);
          _hint = '切换页面保留本轮进度';
        });
      }
    } on TickerCanceled {
      // Back, explicit cancel and backgrounding discard provisional feedback.
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() {
          _error = '本次点名未完成，请重试或重新读取名单。';
        });
      }
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() {
          _pending = null;
          _working = false;
          _committing = false;
        });
      }
    }
  }

  void _cancel() {
    if (_committing) return;
    ++_epoch;
    _pending?.cancel();
    _motion.stop(canceled: true);
    setState(() {
      _pending = null;
      _working = false;
      _hint = '已取消点名，未消耗本轮名额';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _working && !_committing) {
      _cancel();
    }
  }

  @override
  void dispose() {
    ++_epoch;
    _pending?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _selected;
    return PopScope(
      canPop: !_committing,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '随机点名',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: RoundDesignButton(
              icon: 'back',
              label: '返回工具',
              onPressed: _committing
                  ? null
                  : () {
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  if (_error != null) ...[
                    ProblemBanner(_error!),
                    TextButton(
                      onPressed: _locked ? null : () => _load(list?.id),
                      child: const Text('重新读取'),
                    ),
                  ],
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (list == null) ...[
                    const RollCallVisual(members: [], progress: 0),
                    const SizedBox(height: 20),
                    const Text(
                      '还没有名单，先保存一份自己的点名名单吧。',
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
                        const SizedBox(width: 9),
                        OutlinedButton(
                          onPressed: _locked ? null : _edit,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xffd9dff0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            '管理名单',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xffeaf0f7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          for (final repeat in [true, false])
                            Expanded(
                              child: TextButton(
                                onPressed: _locked
                                    ? null
                                    : () => _reset(repeat: repeat),
                                style: TextButton.styleFrom(
                                  backgroundColor: repeat == list.repeat
                                      ? const Color(0xffd6bdf8)
                                      : Colors.transparent,
                                  foregroundColor: repeat == list.repeat
                                      ? const Color(0xff574485)
                                      : const Color(0xff73819a),
                                ),
                                child: Semantics(
                                  selected: repeat == list.repeat,
                                  child: Text(repeat ? '可重复' : '不重复'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: !_working,
                      child: AnimatedBuilder(
                        animation: _motion,
                        builder: (context, _) => RollCallVisual(
                          members: list.members,
                          progress: _motion.value,
                          pending: _pending?.member,
                          result: list.last,
                          busy: _pending != null || (_working && !_committing),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 19, 16, 15),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 20,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    '本轮已抽 ${list.drawn.length} ${list.repeat ? '次' : '人'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    list.repeat
                                        ? '完整名单 ${list.members.length} 人'
                                        : '剩余 ${list.candidates.length} 人',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!list.repeat)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 15,
                                  bottom: 7,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: list.members.isEmpty
                                        ? 0
                                        : list.drawn.length /
                                              list.members.length,
                                    minHeight: 9,
                                    backgroundColor: const Color(0xffe7edf5),
                                    color: const Color(0xff6b85fa),
                                  ),
                                ),
                              ),
                            Text(
                              '第 ${list.round} 轮 · 离开后保留本轮进度',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xff73819a),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('roll-call-draw'),
                      onPressed: _locked || list.candidates.isEmpty
                          ? null
                          : _draw,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DesignIcon(
                            'shuffle',
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _working
                                  ? '请稍候'
                                  : list.drawn.isEmpty
                                  ? '开始点名'
                                  : '再抽一位',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _locked ? null : () => _reset(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffe4e8f0)),
                        backgroundColor: const Color(0x4dffffff),
                        foregroundColor: const Color(0xff6480c5),
                      ),
                      child: const Text('开始新一轮'),
                    ),
                    if (_working && !_committing)
                      TextButton(onPressed: _cancel, child: const Text('取消点名')),
                    const SizedBox(height: 13),
                    Text(
                      list.members.isEmpty
                          ? '名单还是空的，管理名单后再点名。'
                          : list.candidates.isEmpty
                          ? '本轮已抽完，点击“开始新一轮”继续'
                          : _hint ??
                                (list.repeat
                                    ? '可重复模式，每位成员每次机会相同'
                                    : '不重复模式，照顾到每一位同学'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff73819a),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '本轮已抽',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (list.drawn.isEmpty)
                              const Text(
                                '还没有抽取记录',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff73819a),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final id in list.drawn)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff0f4fc),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: SelectableText(
                                        '${list.member(id).name} · ${list.member(id).identification}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xff6c80a8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
