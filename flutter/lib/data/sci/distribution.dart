import 'dart:math';

import 'package:ml_linalg/vector.dart';

abstract class Distribution{
  static Vector univariateNormalDistribution(final Vector values, final double mean, final double variance){
    final Vector exponent = (values - mean).pow(2) / (-2.0 * variance * variance);
    final double base = 1.0 / (sqrt(2 * pi) * variance);
    return exponent.exp() * base;
  }
}