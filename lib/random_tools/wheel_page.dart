import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'wheel_editor.dart';
import 'wheel_list.dart';
import 'wheel_visual.dart';
import 'result_paper.dart';

class WheelPage extends StatefulWidget {
  const WheelPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;
  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _random = widget.random ?? Random();
  late final _motion =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3100),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _pending != null) {
          setState(() {
            _result = _pending;
            _pending = null;
          });
        }
      });
  List<WheelList> _lists = [];
  WheelList? _selected;
  bool _loading = true;
  String? _error;
  int? _pending;
  int? _result;
  double _target = 0;
  bool _cancelled = false;
  bool get _busy => _pending != null;
  List<String> get _items => _selected?.items ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load([WheelList? selected]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await widget.planner.loadWheelLists();
      if (mounted) {
        setState(() {
          _lists = lists;
          _selected = selected ?? (lists.isEmpty ? null : lists.first);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '无法读取转盘列表，请重试。已有数据不会被清空。';
        });
      }
    }
  }

  void _clear() {
    _motion.reset();
    _target = 0;
    _pending = null;
    _result = null;
    _cancelled = false;
  }

  Future<void> _edit({bool create = false}) async {
    if (_busy || _loading) return;
    final saved = await Navigator.push<WheelList>(
      context,
      MaterialPageRoute(
        builder: (_) => WheelEditor(
          planner: widget.planner,
          list: create ? null : _selected,
        ),
      ),
    );
    if (saved != null && mounted) {
      setState(_clear);
      await _load(saved);
    }
  }

  Future<void> _choose() async {
    if (_busy || _loading) return;
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
                '我的转盘',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              for (final list in _lists)
                ListTile(
                  title: Text(list.name),
                  subtitle: Text('${list.items.length}项'),
                  selected: list.id == _selected?.id,
                  trailing: list.id == _selected?.id
                      ? const DesignIcon('check')
                      : null,
                  onTap: () => Navigator.pop(context, list.id),
                ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, -1),
                icon: const DesignIcon('plus'),
                label: const Text('新建转盘'),
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
        _clear();
        _selected = _lists.firstWhere((l) => l.id == choice);
      });
    }
  }

  void _spin() {
    if (_busy || _items.isEmpty || _loading) return;
    final chosen = _random.nextInt(_items.length);
    setState(() {
      _pending = chosen;
      _result = null;
      _cancelled = false;
      _target =
          12 * pi + ((2 * pi - chosen * 2 * pi / _items.length) % (2 * pi));
    });
    _motion.forward(from: 0);
  }

  void _cancel() {
    if (_busy) {
      setState(() {
        _clear();
        _cancelled = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  // The pointer follows the source keyframes under the same ease-out timeline.
  double _pointer(double t) {
    const frames = [
      (0.0, 0.0),
      (.14, -11.0),
      (.3, 9.0),
      (.5, -7.0),
      (.7, 4.0),
      (1.0, 0.0),
    ];
    for (var i = 1; i < frames.length; i++) {
      if (t <= frames[i].$1) {
        final a = frames[i - 1];
        final b = frames[i];
        return (a.$2 + (b.$2 - a.$2) * ((t - a.$1) / (b.$1 - a.$1))) * pi / 180;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff5f8ff),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 433),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  RoundDesignButton(
                    icon: 'back',
                    label: '返回',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '转盘',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                '今天怎么选，让转盘帮你决定',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xff73819a)),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null) ...[
                ProblemBanner(_error!),
                TextButton(onPressed: _load, child: const Text('重试')),
              ] else ...[
                if (_selected == null) ...[
                  const SurfaceCard(child: Text('还没有转盘，先保存一组选项吧。')),
                  TextButton(
                    onPressed: () => _edit(create: true),
                    child: const Text('新建转盘'),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _busy ? null : _choose,
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
                              const DesignIcon('wheel', size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selected!.name} · ${_items.length}项',
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
                        onPressed: _busy ? null : () => _edit(),
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
                          '编辑选项',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                if (_selected != null && _items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '列表还是空的，编辑选项后再转动。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) {
                    final t = wheelCurve.transform(_motion.value);
                    return RepaintBoundary(
                      key: const ValueKey('wheel-scene'),
                      child: WheelVisual(
                        items: _items,
                        rotation: _target * t,
                        pointerAngle: _busy ? _pointer(t) : 0,
                        revealed: _result != null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  child: ClipPath(
                    clipper: ResultPaperClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xffeee8fc),
                        image: DecorationImage(
                          image: AssetImage(
                            'docs/design/resources/materials/paper-grain.png',
                          ),
                          repeat: ImageRepeat.repeat,
                          opacity: .12,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                      child: Column(
                        children: [
                          const Text(
                            '本次选中',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff8c83a3),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _busy
                                ? '转动中…'
                                : _result == null
                                ? '等待转动'
                                : _items[_result!],
                            key: const ValueKey('wheel-result'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '每个选项机会相同',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff8c83a3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('wheel-spin'),
                  onPressed: _busy || _items.isEmpty ? null : _spin,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DesignIcon('shuffle', color: Colors.white),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _busy
                                ? '请稍候'
                                : _result == null
                                ? '转动'
                                : '再转一次',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _cancelled ? '已取消转动，未揭晓结果' : '指针停稳，再揭晓这次选择',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff73819a),
                  ),
                ),
                if (_busy)
                  TextButton(onPressed: _cancel, child: const Text('取消转动')),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '● ',
                              style: TextStyle(
                                color: wheelColors[i % wheelColors.length],
                              ),
                            ),
                            TextSpan(text: '${i + 1}. ${_items[i]}'),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff73819a),
                        ),
                      ),
                  ],
                ),
                if (_items.toSet().length != _items.length)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      '重复文字分别保留，每一项各占一份机会。',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
