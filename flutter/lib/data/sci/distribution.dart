import 'dart:math';

import 'package:ml_linalg/vector.dart';

abstract class Distribution{
  static Vector univariateNormalDistribution(final Vector values, final double mean, final double variance){
    return ((values - mean).pow(2) / (-2.0 * variance * variance)).exp() / (sqrt(2 * pi) * variance);
  }
}