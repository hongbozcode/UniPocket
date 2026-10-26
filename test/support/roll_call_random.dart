import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Each pair is (expected candidate count, chosen index).
class RollCallRandom implements Random {
  RollCallRandom(this.choices);
  final List<(int, int)> choices;
  int _next = 0;
  @override
  int nextInt(int max) {
    final choice = choices[_next++];
    expect(max, choice.$1);
    return choice.$2;
  }

  @override
  bool nextBool() => throw UnsupportedError('Use candidate indices');
  @override
  double nextDouble() => throw UnsupportedError('Use candidate indices');
}
