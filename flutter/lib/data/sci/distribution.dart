import 'dart:math';

import 'package:ml_linalg/vector.dart';

class Bin{
  final num start;
  final num stop;
  num value;

  Bin({required this.start, required this.stop, required this.value});
}

abstract class Distribution{
  static Vector univariateNormalDistribution(final Vector values, final num mean, final num variance){
    return ((values - mean).pow(2) / (-2.0 * variance * variance)).exp() / (sqrt(2 * pi) * variance);
  }
}