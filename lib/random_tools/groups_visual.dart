import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'groups.dart';

double _dealInterval(int count) => count < 2 ? 0 : min(65, 720 / (count - 1));
Duration groupDuration(int count) => Duration(
  milliseconds: (800 + _dealInterval(count) * (count - 1) + 480).ceil(),
);

class GroupDeck extends StatelessWidget {
  const GroupDeck({
    required this.count,
    this.progress = 0,
    this.compact = false,
    super.key,
  });
  final int count;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wave = progress <= .45 ? progress / .45 : (1 - progress) / .55;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: compact ? 130 : 160,
          height: compact ? 64 : 150,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final sign in [-1, 1])
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(sign * 35 * wave, 0),
                    child: Transform.rotate(
                      angle:
                          (sign * (progress == 0 ? 7 : 12 * wave)) * pi / 180,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xffdbe5f5)),
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffdbe5f5)),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12748cb1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!compact)
                        SvgPicture.asset(
                          'docs/design/resources/illustrations/groups.svg',
                          width: 90,
                          height: 78,
                          excludeFromSemantics: true,
                        ),
                      Text(
                        '$count 张姓名牌',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Source motion: 800ms shuffle, then 480ms flights staggered by 65ms.
/// A large roster compresses stagger spacing to keep feedback under two seconds.
class GroupsVisual extends StatefulWidget {
  const GroupsVisual({required this.groups, this.animation, super.key});
  final List<List<GroupMember>> groups;
  final Animation<double>? animation;
  @override
  State<GroupsVisual> createState() => _GroupsVisualState();
}

class _GroupsVisualState extends State<GroupsVisual> {
  final _origin = GlobalKey();
  final _targets = <int, GlobalKey>{};
  final _offsets = <int, Offset>{};
  bool _measureScheduled = false;
  static const _colors = [
    Color(0xffe1f1ff),
    Color(0xffeee2ff),
    Color(0xfffff1bb),
    Color(0xffe5f4eb),
  ];
  static const _accents = [
    Color(0xff387cff),
    Color(0xff9269ff),
    Color(0xffffba39),
    Color(0xff63b99b),
  ];

  void _measure() {
    if (_measureScheduled || widget.animation == null) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final origin = _origin.currentContext?.findRenderObject() as RenderBox?;
      if (origin == null) return;
      final start = origin.localToGlobal(Offset(origin.size.width / 2, 18));
      var changed = false;
      for (final entry in _targets.entries) {
        final box =
            entry.value.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) continue;
        final offset = start - box.localToGlobal(Offset(box.size.width / 2, 0));
        if (_offsets[entry.key] != offset) {
          _offsets[entry.key] = offset;
          changed = true;
        }
      }
      if (changed) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _measure();
    final count = widget.groups.expand((g) => g).length;
    final occurrences = <String, int>{};
    for (final member in widget.groups.expand((g) => g)) {
      occurrences.update(member.name, (n) => n + 1, ifAbsent: () => 1);
    }
    return AnimatedBuilder(
      animation: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, _) {
        final ms =
            (widget.animation?.value ?? 1) *
            groupDuration(count).inMilliseconds;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.animation != null) ...[
              Text(
                ms < 800 ? '先洗洗牌，再认识新的伙伴' : '正在把姓名牌，轻轻送到每一组',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xff939fae)),
              ),
              GroupDeck(
                key: _origin,
                count: count,
                compact: true,
                progress: (ms / 800).clamp(0, 1),
              ),
            ],
            for (var i = 0; i < widget.groups.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage(
                        'docs/design/resources/materials/paper-grain.png',
                      ),
                      repeat: ImageRepeat.repeat,
                      opacity: .12,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _accents[i % 4].withValues(alpha: .72),
                                    _accents[i % 4],
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '第${i + 1}组',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${widget.groups[i].length} 人',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: i % 4 == 2
                                    ? const Color(0xffa67a13)
                                    : _accents[i % 4],
                              ),
                            ),
                            if (MediaQuery.textScalerOf(context).scale(12) <
                                18) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: SvgPicture.asset(
                                        'docs/design/resources/illustrations/spark-yellow.svg',
                                        width: 20,
                                        height: 20,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: SvgPicture.asset(
                                        'docs/design/resources/illustrations/spark-lavender.svg',
                                        width: 16,
                                        height: 16,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, box) {
                            final group = widget.groups[i];
                            final scale =
                                MediaQuery.textScalerOf(context).scale(12) / 12;
                            // Preserve source rows for short names, wrap long labels to full width.
                            final columns = min(
                              group.length,
                              max(1, (box.maxWidth / (62 * scale)).floor()),
                            );
                            final regular =
                                (box.maxWidth - 7 * (columns - 1)) / columns;
                            return Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (var j = 0; j < group.length; j++)
                                  _tag(
                                    group[j],
                                    width:
                                        group[j].name.length > 6 ||
                                            group[j].detail.length > 8
                                        ? box.maxWidth
                                        : regular,
                                    index: j * widget.groups.length + i,
                                    ms: ms,
                                    interval: _dealInterval(count),
                                    showIdentity:
                                        group[j].detail.isNotEmpty ||
                                        occurrences[group[j].name]! > 1,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tag(
    GroupMember member, {
    required double width,
    required int index,
    required double ms,
    required double interval,
    required bool showIdentity,
  }) {
    final t = widget.animation == null
        ? 1.0
        : ((ms - 800 - index * interval) / 480).clamp(0.0, 1.0);
    final eased = const Cubic(.18, .72, .2, 1).transform(t);
    final tag = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xedffffff),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (showIdentity)
              Text(
                member.identification,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xff7d8ca2)),
              ),
          ],
        ),
      ),
    );
    return SizedBox(
      key: _targets.putIfAbsent(member.id, GlobalKey.new),
      width: width,
      child: ExcludeSemantics(
        excluding: t < 1,
        child: Opacity(
          opacity: t == 0 ? 0 : 1,
          child: Transform.translate(
            offset: (_offsets[member.id] ?? Offset.zero) * (1 - eased),
            child: Transform.rotate(angle: -.122173 * (1 - eased), child: tag),
          ),
        ),
      ),
    );
  }
}
