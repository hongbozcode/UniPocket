import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const lotteryDuration = Duration(milliseconds: 1600);
const _sourceCurve = Cubic(.18, .72, .2, 1);

/// Source scene: 850ms bag shake, then a 750ms slip lift through its mouth.
/// The bag is drawn after the slip so the lower paper remains occluded.
class LotteryVisual extends StatelessWidget {
  const LotteryVisual({
    this.progress = const AlwaysStoppedAnimation(0),
    this.pending,
    this.result,
    this.busy = false,
    super.key,
  });
  final Animation<double> progress;
  final String? pending;
  final String? result;
  final bool busy;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('lottery-scene'),
    child: AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final elapsed = progress.value * 1600;
        final reveal =
            !busy && result != null ||
            busy && pending != null && elapsed >= 850;
        final text = busy ? pending : result;
        final short =
            text != null && text.runes.length <= 5 && !text.contains('\n');
        final shake = busy && elapsed < 850;
        final phase = _sourceCurve.transform((elapsed / 850).clamp(0, 1));
        double interpolate(List<double> values, List<double> stops, double t) {
          for (var i = 1; i < stops.length; i++) {
            if (t <= stops[i]) {
              final f = (t - stops[i - 1]) / (stops[i] - stops[i - 1]);
              return values[i - 1] + (values[i] - values[i - 1]) * f;
            }
          }
          return values.last;
        }

        final rotation = shake
            ? interpolate(
                    [0, -9, 8, -5, 3, 0],
                    [0, .18, .38, .6, .8, 1],
                    phase,
                  ) *
                  pi /
                  180
            : 0.0;
        final dx = shake
            ? interpolate([0, -6, 5, 0, 0, 0], [0, .18, .38, .6, .8, 1], phase)
            : 0.0;
        final lift = !busy
            ? 0.0
            : interpolate(
                [154, -7, 0],
                [0, .82, 1],
                _sourceCurve.transform(((elapsed - 850) / 750).clamp(0, 1)),
              );
        return Container(
          height: 328,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xfffff0e5),
            borderRadius: BorderRadius.circular(26),
          ),
          child: LayoutBuilder(
            builder: (context, bounds) => Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 12,
                  right: 12,
                  child: Text(
                    busy
                        ? '摇一摇，等待纸签升起…'
                        : result != null
                        ? '本次抽中 · ${short ? result! : '完整签文见下方'}'
                        : '摇一摇，抽一份小期待',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff92857e),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 44,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.rotate(
                          angle: rotation,
                          alignment: const Alignment(0, .7),
                          child: SizedBox(
                            width: 353,
                            height: 284,
                            child: Stack(
                              children: [
                                if (!reveal)
                                  Positioned(
                                    left: 116,
                                    top: 110,
                                    child: Row(
                                      children: [
                                        for (final angle in [-13.0, 0.0, 14.0])
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              angle == 0 ? -12 : 0,
                                            ),
                                            child: Transform.rotate(
                                              angle: angle * pi / 180,
                                              child: Container(
                                                width: 22,
                                                height: 75,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xfffff6d8,
                                                  ),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                if (reveal)
                                  Positioned(
                                    top: 0,
                                    left: 145.5,
                                    width: 62,
                                    height: 144,
                                    child: Transform.rotate(
                                      angle: -4 * pi / 180,
                                      alignment: Alignment.bottomCenter,
                                      child: ClipRect(
                                        child: OverflowBox(
                                          alignment: Alignment.topCenter,
                                          maxHeight: 240,
                                          child: Transform.translate(
                                            offset: Offset(0, lift),
                                            child: Container(
                                              width: 56,
                                              height: 212,
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    5,
                                                    14,
                                                    5,
                                                    10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xfffff5ca),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xfffffbed,
                                                  ),
                                                  width: 4,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                image: const DecorationImage(
                                                  image: AssetImage(
                                                    'docs/design/resources/materials/paper-grain.png',
                                                  ),
                                                  repeat: ImageRepeat.repeat,
                                                  opacity: .18,
                                                ),
                                              ),
                                              child: Text(
                                                short
                                                    ? text.runes
                                                          .map(
                                                            String.fromCharCode,
                                                          )
                                                          .join('\n')
                                                    : '完整\n签文\n见下方',
                                                textAlign: TextAlign.center,
                                                textScaler:
                                                    TextScaler.noScaling,
                                                style: TextStyle(
                                                  fontSize: short ? 17 : 12,
                                                  height: 1.4,
                                                  color: const Color(
                                                    0xff3e473f,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: -1,
                                  left: 70.5,
                                  child: Image.asset(
                                    'docs/design/resources/illustrations/lottery-bag.png',
                                    width: 212,
                                    height: 212,
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 74,
                                  child: Transform.rotate(
                                    angle: -9 * pi / 180,
                                    child: SvgPicture.asset(
                                      'docs/design/resources/illustrations/spark-yellow.svg',
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 32,
                                  bottom: 110,
                                  child: Transform.rotate(
                                    angle: 9 * pi / 180,
                                    child: SvgPicture.asset(
                                      'docs/design/resources/illustrations/spark-lavender.svg',
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
