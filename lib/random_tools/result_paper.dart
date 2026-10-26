import 'dart:math';

import 'package:flutter/material.dart';

/// Shared rounded paper with the source scene's small torn bottom edge.
class ResultPaperClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(18, 0)
      ..lineTo(size.width - 18, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 18)
      ..lineTo(size.width, size.height - 4);
    for (var x = size.width; x > 0; x -= 12) {
      path
        ..lineTo(max(0, x - 6), size.height - 1)
        ..lineTo(max(0, x - 12), size.height - 5);
    }
    return path
      ..lineTo(0, 18)
      ..quadraticBezierTo(0, 0, 18, 0)
      ..close();
  }

  @override
  bool shouldReclip(ResultPaperClipper oldClipper) => false;
}
