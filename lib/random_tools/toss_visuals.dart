import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _degrees = pi / 180;
const _perspective = 900.0;
final _cubeFaces = [
  Matrix4.identity(),
  Matrix4.rotationY(pi / 2),
  Matrix4.rotationX(pi / 2),
  Matrix4.rotationX(-pi / 2),
  Matrix4.rotationY(-pi / 2),
  Matrix4.rotationY(pi),
];

class CoinLegend extends StatelessWidget {
  const CoinLegend({required this.heads, super.key});
  final bool heads;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'docs/design/resources/illustrations/coin-${heads ? 'head' : 'tail'}.svg',
        width: 28,
        height: 28,
        excludeFromSemantics: true,
      ),
      const SizedBox(width: 6),
      Text(
        heads ? '星星正面' : '月牙反面',
        style: const TextStyle(fontSize: 11, color: Color(0xff73819a)),
      ),
    ],
  );
}

/// HTML keyframes: 40% apex, 76% contact, 87% rebound. Only rotation
/// eases; flight and shadow interpolate their keyframes linearly.
class _Flight {
  _Flight(double progress, Size size, bool moving)
    : t = moving ? progress : 1,
      unit = min(size.width / 353, size.height / 350);
  final double t;
  final double unit;

  double get y => _track([0, -94, 20, -10, 0]) * unit;
  double get scaleX => _track([1, 1, 1.06, 1, 1]);
  double get scaleY => _track([1, 1, .9, 1, 1]);
  double get shadowScale => _track([1, .5, 1.12, 1, 1]);
  double get shadowOpacity => _track([.18, .06, .25, .21, .18]);
  double get rotationProgress => const Cubic(.18, .72, .2, 1).transform(t);

  double _track(List<double> values) {
    const times = [0.0, .4, .76, .87, 1.0];
    for (var i = 1; i < times.length; i++) {
      if (t <= times[i]) {
        final fraction = (t - times[i - 1]) / (times[i] - times[i - 1]);
        return values[i - 1] + (values[i] - values[i - 1]) * fraction;
      }
    }
    return values.last;
  }
}

class DieVisual extends StatelessWidget {
  const DieVisual({
    required this.points,
    required this.announce,
    this.progress = 1,
    this.moving = false,
    super.key,
  });
  final int points;
  final bool announce;
  final double progress;
  final bool moving;

  @override
  Widget build(BuildContext context) => Semantics(
    label: announce ? '骰面：$points 点' : null,
    image: announce,
    child: ExcludeSemantics(
      child: CustomPaint(
        painter: _DiePainter(points, progress, moving),
        size: Size.infinite,
      ),
    ),
  );
}

class _DiePainter extends CustomPainter {
  _DiePainter(this.points, this.progress, this.moving);
  final int points;
  final double progress;
  final bool moving;

  // The face arrangement and pip grids match the HTML cube.
  static const _dots = <List<int>>[
    [5],
    [1, 9],
    [1, 5, 9],
    [1, 3, 7, 9],
    [1, 3, 5, 7, 9],
    [1, 3, 4, 6, 7, 9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final flight = _Flight(progress, size, moving);
    _paintGround(canvas, size, flight);
    final side = 122 * flight.unit;
    final half = side / 2;
    final targetX = switch (points) {
      3 => -pi / 2,
      4 => pi / 2,
      _ => 0.0,
    };
    final targetY = switch (points) {
      2 => -pi / 2,
      5 => pi / 2,
      6 => pi,
      _ => 0.0,
    };
    final t = flight.rotationProgress;
    final rotation = Matrix4.rotationX(moving ? 4 * pi * t : 0)
      ..multiply(Matrix4.rotationY(moving ? 6 * pi * t : 0))
      ..multiply(Matrix4.rotationX(-16 * _degrees))
      ..multiply(Matrix4.rotationY(-24 * _degrees))
      ..multiply(
        Matrix4.rotationX(moving ? pi / 2 + (targetX - pi / 2) * t : targetX),
      )
      ..multiply(Matrix4.rotationY(moving ? targetY * t : targetY));
    final visible = <({int number, Matrix4 transform, double depth})>[];
    for (var i = 0; i < _cubeFaces.length; i++) {
      final transform = rotation.clone()..multiply(_cubeFaces[i]);
      // Face normal versus camera: hidden faces cannot show through the cube.
      if (transform.storage[10] * _perspective <= half) continue;
      transform.multiply(Matrix4.translationValues(0, 0, half));
      visible.add((
        number: i + 1,
        transform: transform,
        depth: transform.storage[14],
      ));
    }
    visible.sort((a, b) => a.depth.compareTo(b.depth));
    var minY = double.infinity, maxY = double.negativeInfinity;
    final r = rotation.storage;
    for (final x in [-half, half]) {
      for (final y in [-half, half]) {
        for (final z in [-half, half]) {
          final projectedY =
              (r[1] * x + r[5] * y + r[9] * z) *
              flight.scaleY /
              (1 - (r[2] * x + r[6] * y + r[10] * z) / _perspective);
          minY = min(minY, projectedY);
          maxY = max(maxY, projectedY);
        }
      }
    }
    canvas.save();
    canvas.translate(size.width / 2, _centerY(size, flight, minY, maxY));
    canvas.scale(flight.scaleX, flight.scaleY);
    _paintRoundedBody(canvas, rotation, half);
    for (final face in visible) {
      final matrix = Matrix4.identity()..setEntry(3, 2, -1 / _perspective);
      matrix.multiply(face.transform);
      canvas.save();
      canvas.transform(matrix.storage);
      final rect = Rect.fromLTWH(-half, -half, side, side);
      final light = face.transform.storage[10];
      final colors = [
        Color.lerp(const Color(0xff7395ed), const Color(0xffa8c6ff), light)!,
        Color.lerp(const Color(0xff4263d2), const Color(0xff6386f0), light)!,
      ];
      // The mesh supplies a continuous rounded body. This inset line sits on
      // its flat face, giving the soft blue bevel shown in the user's image.
      final inset = RRect.fromRectAndRadius(
        rect.deflate(side * .075),
        Radius.circular(side * .11),
      );
      canvas.drawRRect(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = colors.last.withValues(alpha: .6),
      );
      canvas.drawRRect(
        inset.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = Colors.white.withValues(alpha: .22),
      );
      for (final dot in _dots[face.number - 1]) {
        final x = ((dot - 1) % 3 - 1) * side * .245;
        final y = ((dot - 1) ~/ 3 - 1) * side * .245;
        final circle = Rect.fromCircle(
          center: Offset(x, y),
          radius: side * .068,
        );
        canvas.drawOval(
          circle,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(.3, .4),
              radius: .9,
              colors: [Colors.white, Color(0xffd6e5ff)],
            ).createShader(circle),
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DiePainter oldDelegate) =>
      points != oldDelegate.points ||
      progress != oldDelegate.progress ||
      moving != oldDelegate.moving;
}

typedef _CubeVertex = ({
  double x,
  double y,
  double z,
  double nx,
  double ny,
  double nz,
});

// A rounded box is an inset cube plus a spherical bevel. Adjacent patches
// share the same boundary positions/normals, so there are no open corner gaps.
final _roundedCube = _buildRoundedCube();
const _meshSteps = 24;
List<_CubeVertex> _buildRoundedCube() {
  const inner = .76, radius = 1 - inner;
  final vertices = <_CubeVertex>[];
  for (final face in _cubeFaces) {
    final m = face.storage;
    for (var row = 0; row <= _meshSteps; row++) {
      for (var column = 0; column <= _meshSteps; column++) {
        final u = -1 + 2 * column / _meshSteps;
        final v = -1 + 2 * row / _meshSteps;
        final cx = u.clamp(-inner, inner), cy = v.clamp(-inner, inner);
        final dx = u - cx, dy = v - cy;
        final length = sqrt(dx * dx + dy * dy + radius * radius);
        final nx = dx / length, ny = dy / length, nz = radius / length;
        final x = cx + radius * nx,
            y = cy + radius * ny,
            z = inner + radius * nz;
        vertices.add((
          x: m[0] * x + m[4] * y + m[8] * z,
          y: m[1] * x + m[5] * y + m[9] * z,
          z: m[2] * x + m[6] * y + m[10] * z,
          nx: m[0] * nx + m[4] * ny + m[8] * nz,
          ny: m[1] * nx + m[5] * ny + m[9] * nz,
          nz: m[2] * nx + m[6] * ny + m[10] * nz,
        ));
      }
    }
  }
  return vertices;
}

void _paintRoundedBody(Canvas canvas, Matrix4 rotation, double half) {
  final m = rotation.storage;
  final positions = Float32List(_roundedCube.length * 2);
  final colors = Int32List(_roundedCube.length);
  final facing = <double>[];
  for (var i = 0; i < _roundedCube.length; i++) {
    final p = _roundedCube[i];
    final x = (m[0] * p.x + m[4] * p.y + m[8] * p.z) * half;
    final y = (m[1] * p.x + m[5] * p.y + m[9] * p.z) * half;
    final z = (m[2] * p.x + m[6] * p.y + m[10] * p.z) * half;
    final nx = m[0] * p.nx + m[4] * p.ny + m[8] * p.nz;
    final ny = m[1] * p.nx + m[5] * p.ny + m[9] * p.nz;
    final nz = m[2] * p.nx + m[6] * p.ny + m[10] * p.nz;
    final perspective = 1 / (1 - z / _perspective);
    positions[i * 2] = x * perspective;
    positions[i * 2 + 1] = y * perspective;
    facing.add(nx * -x + ny * -y + nz * (_perspective - z));
    final diffuse = (-nx * .4 - ny * .55 + nz * .8).clamp(0.0, 1.0);
    final base = Color.lerp(
      const Color(0xff5277e8),
      const Color(0xff92b3ff),
      diffuse,
    )!;
    final rim = pow(1 - nz.abs(), 3).toDouble() * .23;
    colors[i] = Color.lerp(base, const Color(0xffd8e6ff), rim)!.toARGB32();
  }
  final indices = <int>[];
  const stride = _meshSteps + 1, patchSize = stride * stride;
  void triangle(int a, int b, int c) {
    if (facing[a] + facing[b] + facing[c] > 0) indices.addAll([a, b, c]);
  }

  for (var face = 0; face < 6; face++) {
    for (var row = 0; row < _meshSteps; row++) {
      for (var column = 0; column < _meshSteps; column++) {
        final a = face * patchSize + row * stride + column;
        triangle(a, a + 1, a + stride);
        triangle(a + 1, a + stride + 1, a + stride);
      }
    }
  }
  final mesh = ui.Vertices.raw(
    ui.VertexMode.triangles,
    positions,
    colors: colors,
    indices: Uint16List.fromList(indices),
  );
  canvas.drawVertices(mesh, BlendMode.srcOver, Paint());
  mesh.dispose();
}

class CoinVisual extends StatelessWidget {
  const CoinVisual({
    required this.heads,
    required this.announce,
    this.progress = 1,
    this.moving = false,
    super.key,
  });
  final bool heads;
  final bool announce;
  final double progress;
  final bool moving;

  @override
  Widget build(BuildContext context) => Semantics(
    label: announce ? '币面：${heads ? '星星正面' : '月牙反面'}' : null,
    image: announce,
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final flight = _Flight(progress, size, moving);
          final diameter = 154 * flight.unit;
          final radius = (diameter / 2 + 6 * flight.unit) * flight.scaleY;
          final centerY = _centerY(size, flight, -radius, radius);
          final angle = moving
              ? (10 * pi + (heads ? 0 : pi)) * flight.rotationProgress
              : heads
              ? 0.0
              : pi;
          final rotation = Matrix4.rotationX(-12 * _degrees)
            ..multiply(Matrix4.rotationY(angle));
          // Select the outward face. Rotate the back separately so the moon is
          // upright and the two SVGs never show through one another.
          final front = rotation.storage[10] >= 0;
          final surface = rotation.clone()
            ..multiply(front ? Matrix4.identity() : Matrix4.rotationY(pi))
            ..multiply(Matrix4.translationValues(0, 0, 5 * flight.unit));
          final matrix = Matrix4.translationValues(size.width / 2, centerY, 0)
            ..multiply(Matrix4.diagonal3Values(flight.scaleX, flight.scaleY, 1))
            ..multiply(Matrix4.identity()..setEntry(3, 2, -1 / _perspective))
            ..multiply(surface)
            ..multiply(
              Matrix4.translationValues(-diameter / 2, -diameter / 2, 0),
            );
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CoinEdgePainter(rotation, flight, centerY),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: diameter,
                height: diameter,
                child: Transform(
                  transform: matrix,
                  child: SvgPicture.asset(
                    'docs/design/resources/illustrations/coin-${front ? 'head' : 'tail'}.svg',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CoinEdgePainter extends CustomPainter {
  _CoinEdgePainter(this.rotation, this.flight, this.centerY);
  final Matrix4 rotation;
  final _Flight flight;
  final double centerY;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGround(canvas, size, flight);
    final radius = 73.2 * flight.unit;
    final half = 5 * flight.unit;
    final m = rotation.storage;
    Offset project(double x, double y, double z) {
      final rx = m[0] * x + m[4] * y + m[8] * z;
      final ry = m[1] * x + m[5] * y + m[9] * z;
      final rz = m[2] * x + m[6] * y + m[10] * z;
      final perspective = 1 / (1 - rz / _perspective);
      return Offset(
        size.width / 2 + rx * perspective * flight.scaleX,
        centerY + ry * perspective * flight.scaleY,
      );
    }

    // A short cylinder with milled edge strips; thickness survives edge-on views.
    final strips = <({Path path, double depth, double shade})>[];
    for (var i = 0; i < 80; i++) {
      final a = i * 2 * pi / 80;
      final b = (i + 1) * 2 * pi / 80;
      final mid = (a + b) / 2;
      final normalZ = m[2] * cos(mid) + m[6] * sin(mid);
      if (normalZ < 0) continue;
      strips.add((
        path: Path()
          ..addPolygon([
            project(radius * cos(a), radius * sin(a), -half),
            project(radius * cos(b), radius * sin(b), -half),
            project(radius * cos(b), radius * sin(b), half),
            project(radius * cos(a), radius * sin(a), half),
          ], true),
        depth: normalZ,
        shade: i.isEven ? .25 : .65,
      ));
    }
    strips.sort((a, b) => a.depth.compareTo(b.depth));
    for (final strip in strips) {
      canvas.drawPath(
        strip.path,
        Paint()
          ..color = Color.lerp(
            const Color(0xffd79b32),
            const Color(0xffffdc79),
            strip.shade,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinEdgePainter oldDelegate) => true;
}

// Adapt the flight to keep projected corners inside the caption/status region.
double _centerY(Size size, _Flight flight, double minY, double maxY) =>
    (size.height * .54 + flight.y).clamp(44 - minY, size.height - 48 - maxY);

void _paintGround(Canvas canvas, Size size, _Flight flight) {
  canvas.save();
  canvas.translate(size.width / 2, size.height * .47);
  canvas.rotate(-23 * _degrees);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset.zero,
      width: size.width * .9,
      height: size.height * .47,
    ),
    Paint()
      ..color = const Color(0xffb3c8c3).withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  canvas.restore();
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .74),
      width: 138 * flight.unit * flight.shadowScale,
      height: 22 * flight.unit * flight.shadowScale,
    ),
    Paint()
      ..color = const Color(0xff536b84).withValues(alpha: flight.shadowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * flight.unit),
  );
}
