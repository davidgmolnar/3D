import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ml_linalg/vector.dart';

import '../typed_data_list_container.dart';
import 'distribution.dart';

class KDEResult{
  final Vector x;
  final Vector y;

  const KDEResult({required this.x, required this.y});
}

abstract class KDE{
  static List<Offset> estimatePDF(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first, bw);
    final int inc = max((values.size) ~/ 50000, 1);
    for(int i = 1; i < values.size; i += inc){
      sum += Distribution.univariateNormalDistribution(sampling, values[i], bw);
    }
    
    return List<Offset>.generate(sampling.length, (index) => Offset(sampling[index], sum[index]));
  }

  static List<Offset> estimateCDF(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first, bw);
    final int inc = max((values.size) ~/ 50000, 1);
    for(int i = 1; i < values.size; i += inc){
      sum += Distribution.univariateNormalDistribution(sampling, values[i], bw);
    }

    final List<double> cumsum = sum.toList();
    for(int i = 1; i < cumsum.length; i++){
      cumsum[i] += cumsum[i - 1];
    }
    return List<Offset>.generate(sampling.length, (index) => Offset(sampling[index], cumsum[index]));
  }
}