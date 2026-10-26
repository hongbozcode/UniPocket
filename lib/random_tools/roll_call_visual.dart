import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'roll_call.dart';

const rollCallDuration = Duration(milliseconds: 1400);
const rollCallCurve = Cubic(.18, .72, .2, 1);

/// Twenty rows travel upward before the chosen member settles. Display rows
/// cycle without consuming randomness. All phases reserve the same text space.
class RollCallVisual extends StatelessWidget {
  const RollCallVisual({
    required this.members,
    this.progress = const AlwaysStoppedAnimation(0),
    this.pending,
    this.result,
    this.busy = false,
    super.key,
  });
  final List<RollCallMember> members;
  final RollCallMember? pending;
  final RollCallMember? result;
  final Animation<double> progress;
  final bool busy;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final scaler = MediaQuery.textScalerOf(context);
      final inherited = DefaultTextStyle.of(context).style;
      final nameStyle = inherited.merge(
        const TextStyle(
          fontSize: 36,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      );
      final detailStyle = inherited.merge(
        const TextStyle(fontSize: 12, height: 1.5, color: Color(0xff8c83a3)),
      );
      final captionStyle = inherited.merge(
        const TextStyle(fontSize: 11, height: 1.5, color: Color(0xff8c83a3)),
      );
      double textHeight(Iterable<String> texts, TextStyle style) {
        var height = 0.0;
        for (final text in texts) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textScaler: scaler,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: bounds.maxWidth - 28);
          height = max(height, painter.height.ceilToDouble());
          painter.dispose();
        }
        return height;
      }

      final rowHeight = max(
        60 * scaler.scale(1),
        textHeight([
              '等待点名',
              for (final member in members) member.name,
            ], nameStyle) +
            12,
      );
      final detailHeight = textHeight([
        '名单中的每位同学，机会相同',
        '正在揭晓这位同学',
        for (final member in members) member.identification,
      ], detailStyle);
      final captionHeight = textHeight([
        '名字滚动中…',
        '准备好，抽一位同学吧',
        '本次抽中',
      ], captionStyle);
      return RepaintBoundary(
        key: const ValueKey('roll-call-scene'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 254),
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 22),
          decoration: BoxDecoration(
            color: const Color(0xfff0e9fc),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                'docs/design/resources/illustrations/badge.svg',
                width: 140,
                height: 114,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: captionHeight,
                child: Center(
                  child: Text(
                    busy
                        ? '名字滚动中…'
                        : result == null
                        ? '准备好，抽一位同学吧'
                        : '本次抽中',
                    textAlign: TextAlign.center,
                    style: captionStyle,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: rowHeight,
                child: busy && pending != null && members.isNotEmpty
                    ? ExcludeSemantics(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxHeight: rowHeight * 21,
                            minHeight: rowHeight * 21,
                            child: AnimatedBuilder(
                              animation: progress,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(
                                  0,
                                  -20 *
                                      rowHeight *
                                      rollCallCurve.transform(progress.value),
                                ),
                                child: child,
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i <= 20; i++)
                                    SizedBox(
                                      height: rowHeight,
                                      child: Center(
                                        child: Text(
                                          i == 20
                                              ? pending!.name
                                              : members[i % members.length]
                                                    .name,
                                          textAlign: TextAlign.center,
                                          style: nameStyle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: SelectableText(
                          result?.name ?? '等待点名',
                          key: const ValueKey('roll-call-result'),
                          textAlign: TextAlign.center,
                          style: nameStyle,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: detailHeight,
                child: Center(
                  child: busy
                      ? Text(
                          '正在揭晓这位同学',
                          style: detailStyle,
                          textAlign: TextAlign.center,
                        )
                      : SelectableText(
                          result?.identification ?? '名单中的每位同学，机会相同',
                          key: const ValueKey('roll-call-identification'),
                          textAlign: TextAlign.center,
                          style: detailStyle,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
