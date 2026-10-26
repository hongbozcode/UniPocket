import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'roll_call.dart';

const rollCallDuration = Duration(milliseconds: 1400);
const rollCallCurve = Cubic(.18, .72, .2, 1);

/// Source reel: twenty rows travel upward before the selected member settles.
/// Cycling display rows is decorative and never consumes the random source.
class RollCallVisual extends StatelessWidget {
  const RollCallVisual({
    required this.members,
    required this.progress,
    this.pending,
    this.result,
    this.busy = false,
    super.key,
  });
  final List<RollCallMember> members;
  final RollCallMember? pending;
  final RollCallMember? result;
  final double progress;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final rowHeight = 60 * MediaQuery.textScalerOf(context).scale(1);
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
            Text(
              busy
                  ? '名字滚动中…'
                  : result == null
                  ? '准备好，抽一位同学吧'
                  : '本次抽中',
              style: const TextStyle(color: Color(0xff8c83a3), fontSize: 11),
            ),
            const SizedBox(height: 3),
            if (busy && pending != null && members.isNotEmpty)
              ExcludeSemantics(
                child: SizedBox(
                  height: rowHeight,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: rowHeight * 21,
                      minHeight: rowHeight * 21,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          -20 * rowHeight * rollCallCurve.transform(progress),
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
                                        : members[i % members.length].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SelectableText(
                  result?.name ?? '等待点名',
                  key: const ValueKey('roll-call-result'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            if (busy)
              const Text(
                '正在揭晓这位同学',
                style: TextStyle(color: Color(0xff8c83a3), fontSize: 12),
              )
            else
              SelectableText(
                result?.identification ?? '名单中的每位同学，机会相同',
                key: const ValueKey('roll-call-identification'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff8c83a3), fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
