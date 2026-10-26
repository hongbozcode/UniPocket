import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/design.dart';

const wheelColors = [
  Color(0xffe4f2ff),
  Color(0xffeee4ff),
  Color(0xfffff1bf),
  Color(0xffe1f2e8),
  Color(0xffffe5ec),
  Color(0xffffe7d7),
];

/// The source scene uses six full turns, a 3.1s ease-out, and a fixed top pointer.
const wheelCurve = Cubic(.18, .72, .2, 1);

class WheelVisual extends StatelessWidget {
  const WheelVisual({
    required this.items,
    required this.rotation,
    required this.pointerAngle,
    required this.revealed,
    super.key,
  });
  final List<String> items;
  final double rotation;
  final double pointerAngle;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    // Derive the announcement from the geometry actually drawn under the pointer.
    final index = items.isEmpty
        ? 0
        : ((-rotation / (2 * pi) * items.length).round() % items.length);
    return Semantics(
      label: revealed && items.isNotEmpty
          ? '指针：第${index + 1}项，${items[index]}'
          : '选项转盘',
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Transform.rotate(
                  angle: rotation,
                  child: CustomPaint(
                    painter: _WheelPainter(
                      items,
                      MediaQuery.textScalerOf(context).scale(16) / 16,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Transform.rotate(
                angle: pointerAngle,
                alignment: const Alignment(0, -.8),
                child: const CustomPaint(
                  size: Size(44, 54),
                  painter: _PointerPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.items, this.textScale);
  final List<String> items;
  final double textScale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = min(size.width, size.height) / 360;
    canvas.scale(scale);
    final rim = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 175));
    canvas.drawShadow(rim, const Color(0x307d92c3), 4, false);
    canvas.drawCircle(Offset.zero, 175, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset.zero,
      171,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff629eff), Color(0xffa18bff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTRB(-175, -175, 175, 175)),
    );
    canvas.drawCircle(Offset.zero, 165, Paint()..color = Colors.white);
    if (items.isEmpty) {
      canvas.drawCircle(Offset.zero, 162, Paint()..color = wheelColors.first);
    } else {
      final step = 2 * pi / items.length;
      for (var i = 0; i < items.length; i++) {
        final sector = Path();
        if (items.length == 1) {
          sector.addOval(Rect.fromCircle(center: Offset.zero, radius: 163));
        } else {
          sector
            ..moveTo(0, 0)
            ..arcTo(
              Rect.fromCircle(center: Offset.zero, radius: 163),
              -pi / 2 + i * step - step / 2,
              step,
              false,
            )
            ..close();
        }
        canvas.drawPath(
          sector,
          Paint()..color = wheelColors[i % wheelColors.length],
        );
        canvas.drawPath(
          sector,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.save();
        canvas.rotate(i * step);
        // Rotate text with its sector, so the winning label is upright at the top.
        // Full untruncated text remains available in the legend and result.
        canvas.translate(0, -95);
        final glyphs = items[i].characters.toList();
        final visible = glyphs.length > 6 ? [...glyphs.take(5), '…'] : glyphs;
        final font =
            (items.length > 10 ? 12.0 : 16.0) * textScale.clamp(1, 1.4);
        final availableWidth = items.length == 1
            ? 70.0
            : min(60.0, 210 * sin(step / 2));
        final label = TextPainter(
          text: TextSpan(
            text: visible.join('\n'),
            style: TextStyle(
              fontSize: font,
              height: 1.05,
              fontWeight: FontWeight.w700,
              color: inkColor,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        final fit = min(
          1.0,
          min(availableWidth / max(1, label.width), 84 / max(1, label.height)),
        );
        canvas.scale(fit);
        label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
        canvas.restore();
      }
    }
    canvas.drawCircle(Offset.zero, 39, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset.zero,
      32,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffe7dcff), Color(0xffceccff)],
        ).createShader(const Rect.fromLTRB(-32, -32, 32, 32)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.items != items || old.textScale != textScale;
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(5, 4)
      ..lineTo(39, 4)
      ..lineTo(22, 48)
      ..close();
    canvas.drawShadow(path, const Color(0xff6b7da5), 3, false);
    canvas.drawPath(path, Paint()..color = primaryBlue);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
