import 'dart:ui';

import 'package:ml_linalg/vector.dart';

import 'distribution.dart';

abstract class KDE{
  static List<Offset> estimatePDF(final Iterable<num> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first.toDouble(), bw);
    for(final num value in values.skip(1)){
      sum += Distribution.univariateNormalDistribution(sampling, value.toDouble(), bw);
    }
    //sum /= sum.sum();
    return List<Offset>.generate(sampling.length, (index) => Offset(sampling[index], sum[index]));
  }

  static List<Offset> estimateCDF(final Iterable<num> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first.toDouble(), bw);
    for(final num value in values.skip(1)){
      sum += Distribution.univariateNormalDistribution(sampling, value.toDouble(), bw);
    }

    final List<double> cumsum = sum.toList();
    for(int i = 1; i < cumsum.length; i++){
      cumsum[i] += cumsum[i - 1];
    }
    return List<Offset>.generate(sampling.length, (index) => Offset(sampling[index], cumsum[index]));
  }
}