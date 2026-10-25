import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// Every index represents one equally likely candidate, not a frequency test.
class CandidateRandom implements Random {
  CandidateRandom(this.candidates, this.range);
  final List<int> candidates;
  final int range;
  var _index = 0;

  @override
  int nextInt(int max) {
    expect(max, range);
    return candidates[_index++];
  }

  @override
  bool nextBool() => throw UnsupportedError('Use the candidate range');
  @override
  double nextDouble() => throw UnsupportedError('Use the candidate range');
}
