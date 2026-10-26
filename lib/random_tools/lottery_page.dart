import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'lottery.dart';
import 'lottery_editor.dart';
import 'lottery_visual.dart';

class LotteryPage extends StatefulWidget {
  const LotteryPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;
  @override
  State<LotteryPage> createState() => _LotteryPageState();
}

class _LotteryPageState extends State<LotteryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: lotteryDuration,
  );
  late final _random = widget.random ?? Random();
  List<LotteryPool> _lists = [];
  LotteryPool? _selected;
  LotteryDraw? _pending;
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
      final lists = await widget.planner.loadLotteryPools();
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
          _error = '无法读取签池，请重试。已有数据不会被清空。';
        });
      }
    }
  }

  void _replace(LotteryPool list) {
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
          '修改签池会重置本轮',
          '保存修改将清除本次结果和本轮已抽记录，开始新一轮。取消编辑不会改变进度。',
          '继续编辑',
        )) {
      return;
    }
    if (!mounted) return;
    final saved = await Navigator.push<LotteryPool>(
      context,
      MaterialPageRoute(
        builder: (_) => LotteryEditor(
          planner: widget.planner,
          pool: create ? null : _selected,
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
                '我的签池',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              for (final l in _lists)
                ListTile(
                  title: Text(l.name),
                  subtitle: Text(
                    '${l.items.length}项 · 第 ${l.round} 轮 · 已抽 ${l.drawn.length} 次',
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
                label: const Text('新建签池'),
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
      '将清除本次结果和本轮 ${list.drawn.length} 次已抽记录，所有签项重新参与。',
      '开始新一轮',
    );
    if (!mounted || !confirmed) return;
    setState(() {
      _working = true;
      _committing = true;
      _error = null;
    });
    try {
      final next = await widget.planner.resetLottery(list.id, repeat: repeat);
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
      final draw = await widget.planner.prepareLottery(
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
          : lotteryDuration;
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
          _error = '本次抽签未完成，请重试或重新读取签池。';
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
      _hint = '已取消抽签，未消耗本轮名额';
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
    final pool = _selected;
    return PopScope(
      canPop: !_committing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _working && !_committing) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            '抽签',
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  const Text(
                    '把一点小期待，交给随机',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xff73819a)),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    ProblemBanner(_error!),
                    TextButton(
                      onPressed: _locked ? null : () => _load(pool?.id),
                      child: const Text('重新读取'),
                    ),
                  ],
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (pool == null) ...[
                    const LotteryVisual(),
                    const SizedBox(height: 20),
                    const Text('还没有签池，先保存自己的签文吧。', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => _edit(create: true),
                      child: const Text('新建签池'),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const DesignIcon('ticket', size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${pool.name} · ${pool.items.length}项',
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xffd9dff0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '编辑签池',
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
                                  backgroundColor: repeat == pool.repeat
                                      ? const Color(0xffd6bdf8)
                                      : Colors.transparent,
                                  foregroundColor: repeat == pool.repeat
                                      ? const Color(0xff574485)
                                      : const Color(0xff73819a),
                                ),
                                child: Semantics(
                                  selected: repeat == pool.repeat,
                                  child: Text(repeat ? '可重复' : '不重复'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LotteryVisual(
                      progress: _motion,
                      pending: _pending?.text,
                      result: pool.last,
                      busy: _working,
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 24,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    pool.repeat
                                        ? '可重复 · 每签机会相同'
                                        : '本轮已抽 ${pool.drawn.length} 签',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    pool.repeat
                                        ? '完整签池 ${pool.items.length} 项'
                                        : '剩余 ${pool.candidates.length} 签',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!pool.repeat)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: pool.items.isEmpty
                                        ? 0
                                        : pool.drawn.length / pool.items.length,
                                    minHeight: 9,
                                    color: const Color(0xff6b85fa),
                                    backgroundColor: const Color(0xffe7edf5),
                                  ),
                                ),
                              ),
                            if (!pool.repeat)
                              Text(
                                '第 ${pool.round} 轮 · 离开后保留本轮进度',
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
                      key: const ValueKey('lottery-draw'),
                      onPressed: _locked || pool.candidates.isEmpty
                          ? null
                          : _draw,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DesignIcon('shuffle', color: Colors.white),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _working
                                  ? '请稍候'
                                  : pool.drawn.isEmpty
                                  ? '抽一签'
                                  : '再抽一签',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _locked ? null : () => _reset(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffd9dff0)),
                        backgroundColor: const Color(0x4dffffff),
                        foregroundColor: const Color(0xff6480c5),
                      ),
                      child: const Text('开始新一轮'),
                    ),
                    if (_working && !_committing)
                      TextButton(onPressed: _cancel, child: const Text('取消抽签')),
                    const SizedBox(height: 13),
                    Text(
                      pool.items.isEmpty
                          ? '签池还是空的，编辑签池后再抽签。'
                          : pool.candidates.isEmpty
                          ? '本轮已抽完，点击“开始新一轮”继续'
                          : _hint ??
                                (pool.repeat
                                    ? '可重复模式，每张签每次机会相同'
                                    : '切换页面保留本轮进度'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff73819a),
                      ),
                    ),
                    if (!_working && pool.last != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: const Color(0xfffff5ca),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '本次抽中',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff73819a),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Semantics(
                                liveRegion: true,
                                child: SelectableText(
                                  pool.last!,
                                  key: const ValueKey('lottery-result'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              pool.repeat ? '完整签池' : '本轮已抽',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!pool.repeat && pool.drawn.isEmpty)
                              const Text(
                                '还没有抽取记录',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff73819a),
                                ),
                              )
                            else
                              for (final index
                                  in pool.repeat
                                      ? List.generate(
                                          pool.items.length,
                                          (i) => i,
                                        )
                                      : pool.drawn)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SelectableText(
                                    '签 ${index + 1} · ${pool.items[index]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: Color(0xff6c80a8),
                                    ),
                                  ),
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
