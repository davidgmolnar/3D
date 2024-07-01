import 'dart:math';
import 'dart:typed_data';

import 'package:ml_linalg/vector.dart';

import '../typed_data_list_container.dart';
import 'distribution.dart';

class KDEResult{
  final Vector x;
  final Vector y;

  const KDEResult({required this.x, required this.y});

  static KDEResult empty(){
    return KDEResult(x: Vector.empty(), y: Vector.empty());
  }
}

abstract class KDE{
  static List<Bin> _binning(final TypedDataListContainer<TypedData> values, final Vector sampling){
    if(sampling.length == 1){
      return [Bin(start: sampling.single, stop: sampling.single, value: values.size)];
    }
    final num binSpan = sampling[1] - sampling[0];
    final List<Bin> bins = sampling.map((e) => Bin(start: e, stop: e, value: 0)).toList();
    for(final num value in values.iterable){
      bins[min((value - sampling.first) ~/ binSpan, sampling.length - 1)].value++;
    }
    return bins;
  }

  static KDEResult estimatePDFBinning(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    final List<Bin> bins = _binning(values, sampling);
    Vector sum = Distribution.univariateNormalDistribution(sampling, bins.first.start, bw) * bins.first.value;
    for(int i = 1; i < bins.length; i++){
      sum += Distribution.univariateNormalDistribution(sampling, bins[i].start, bw) * bins[i].value;
    }
    
    return KDEResult(x: sampling, y: sum);
  }

  static KDEResult estimateCDFBinning(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    final List<Bin> bins = _binning(values, sampling);
    Vector sum = Distribution.univariateNormalDistribution(sampling, bins.first.start, bw) * bins.first.value;
    for(int i = 1; i < bins.length; i++){
      sum += Distribution.univariateNormalDistribution(sampling, bins[i].start, bw) * bins[i].value;
    }

    final List<double> cumsum = sum.toList();
    for(int i = 1; i < cumsum.length; i++){
      cumsum[i] += cumsum[i - 1];
    }
    return KDEResult(x: sampling, y: Vector.fromList(cumsum));
  }

  static KDEResult estimatePDF(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first, bw);
    final int inc = max((values.size) ~/ 50000, 1);
    for(int i = 1; i < values.size; i += inc){
      sum += Distribution.univariateNormalDistribution(sampling, values[i], bw);
    }
    
    return KDEResult(x: sampling, y: sum);
  }

  static KDEResult estimateCDF(final TypedDataListContainer<TypedData> values, final Vector sampling, final double bw){
    Vector sum = Distribution.univariateNormalDistribution(sampling, values.first, bw);
    final int inc = max((values.size) ~/ 50000, 1);
    for(int i = 1; i < values.size; i += inc){
      sum += Distribution.univariateNormalDistribution(sampling, values[i], bw);
    }

    final List<double> cumsum = sum.toList();
    for(int i = 1; i < cumsum.length; i++){
      cumsum[i] += cumsum[i - 1];
    }
    return KDEResult(x: sampling, y: Vector.fromList(cumsum));
  }
}