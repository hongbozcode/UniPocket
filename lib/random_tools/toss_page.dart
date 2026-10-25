import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'toss_visuals.dart';

enum TossTool {
  die('掷骰子', Color(0xffe7f5ee)),
  coin('抛硬币', Color(0xfffceff5));

  const TossTool(this.title, this.surface);
  final String title;
  final Color surface;
}

/// Both the pending draw and the result belong only to this route. Disposing
/// it cancels all motion; nothing is written to the planner or local database.
class TossPage extends StatefulWidget {
  const TossPage({required this.tool, this.random, super.key});
  final TossTool tool;
  final Random? random;

  @override
  State<TossPage> createState() => _TossPageState();
}

class _TossPageState extends State<TossPage>
    with SingleTickerProviderStateMixin {
  late final _random = widget.random ?? Random();
  late final AnimationController _feedback;
  int? _result;
  int? _pending;
  bool get _busy => _pending != null;
  bool get _isDie => widget.tool == TossTool.die;

  @override
  void initState() {
    super.initState();
    _feedback =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _isDie ? 1900 : 1800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _result = _pending;
              _pending = null;
            });
          }
        });
  }

  void _toss() {
    if (_busy) return;
    setState(() {
      _pending = _random.nextInt(_isDie ? 6 : 2);
      _result = null;
    });
    _feedback.forward(from: 0);
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _result;
    final resultText = _busy
        ? '投掷中…'
        : value == null
        ? '等待投掷'
        : _isDie
        ? '${value + 1}'
        : value == 0
        ? '正面'
        : '反面';
    final actionText = _busy
        ? '请稍候'
        : _isDie
        ? (value == null ? '掷一下' : '再掷一次')
        : (value == null ? '抛一下' : '再抛一次');
    return Scaffold(
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.tool.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  _isDie ? '一颗骰子，也有一点小惊喜' : '正面还是反面，交给这一抛',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff73819a),
                  ),
                ),
                const SizedBox(height: 30),
                LayoutBuilder(
                  builder: (context, box) {
                    final extraText =
                        MediaQuery.textScalerOf(context).scale(22) - 22;
                    final height =
                        (box.maxWidth * 350 / 353).clamp(320.0, 390.0) +
                        extraText * 2;
                    return RepaintBoundary(
                      key: const ValueKey('toss-scene'),
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: widget.tool.surface,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedBuilder(
                              animation: _feedback,
                              builder: (context, _) {
                                final candidate = _pending ?? _result;
                                return _isDie
                                    ? DieVisual(
                                        points: (candidate ?? 3) + 1,
                                        progress: _feedback.value,
                                        moving: _busy,
                                        announce: !_busy && value != null,
                                      )
                                    : CoinVisual(
                                        heads: candidate != 1,
                                        progress: _feedback.value,
                                        moving: _busy,
                                        announce: !_busy && value != null,
                                      );
                              },
                            ),
                            Positioned(
                              top: 18,
                              left: 12,
                              right: 12,
                              child: Text(
                                _isDie ? '单个六面骰' : '一枚硬币 · 两种可能',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff7b8c85),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              left: 12,
                              right: 12,
                              child: Text(
                                _busy
                                    ? '向上抛起，轻轻落定'
                                    : value == null
                                    ? (_isDie ? '准备好，掷出一点小惊喜' : '星星和月牙，等一枚答案')
                                    : _isDie
                                    ? '已经停稳啦，本次 ${value + 1} 点'
                                    : '硬币落下了，本次为${value == 0 ? '正面' : '反面'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff73887e),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  child: ClipPath(
                    clipper: _ResultPaperClipper(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                      decoration: BoxDecoration(
                        color: _isDie
                            ? const Color(0xffeee8fc)
                            : const Color(0xfffff4d2),
                      ),
                      child: Column(
                        children: [
                          if (!_busy && value != null)
                            Text(
                              _isDie ? '本次点数' : '本次结果',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff73819a),
                              ),
                            ),
                          Text(
                            resultText,
                            key: const ValueKey('toss-result'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: value == null
                                  ? 24
                                  : _isDie
                                  ? 50
                                  : 32,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: _isDie && value != null
                                  ? primaryBlue
                                  : inkColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isDie ? '1–6 等概率' : '两面机会相同',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff73819a),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('random-action'),
                  onPressed: _busy ? null : _toss,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DesignIcon(
                          'shuffle',
                          size: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            actionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isDie ? '点击投掷，等待骰子停稳' : '跳起，翻转，等它轻轻落下',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff73819a),
                  ),
                ),
                if (!_isDie)
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        CoinLegend(heads: true),
                        CoinLegend(heads: false),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                const Text(
                  '结果仅本次展示，不保存历史',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xff73819a)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPaperClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(18, 0)
      ..lineTo(size.width - 18, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 18)
      ..lineTo(size.width, size.height - 4);
    for (var x = size.width; x > 0; x -= 12) {
      path.lineTo(max(0, x - 6), size.height - 1);
      path.lineTo(max(0, x - 12), size.height - 5);
    }
    return path
      ..lineTo(0, 18)
      ..quadraticBezierTo(0, 0, 18, 0)
      ..close();
  }

  @override
  bool shouldReclip(_ResultPaperClipper oldClipper) => false;
}
