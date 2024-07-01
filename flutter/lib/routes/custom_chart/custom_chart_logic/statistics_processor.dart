import 'dart:ui';
import 'dart:math' as math;

import 'package:ml_linalg/vector.dart';

import '../../../data/data.dart';
import '../../../data/sci/distribution.dart';
import '../../../data/sci/kde.dart';
import '../../../data/signal_container.dart';
import '../../../data/typed_data_list_container.dart';

class Stat{
  final num min;
  final num avg;
  final num max;
  final num integral;

  const Stat({required this.min, required this.max, required this.integral, required this.avg});

  static int numElements = 4;

  Stat copyWith({num? min, num? max, num? integral, num? avg}){
    return Stat(
      min: min ?? this.min,
      max: max ?? this.max,
      integral: integral ?? this.integral,
      avg: avg ?? this.avg,
    );
  }
}

abstract class PlotConfig{
  Offset minmax = const Offset(0, 1);

  Map<String, num> get asMap;
  void set(final String path, final num value);
}

class HistogramConfig implements PlotConfig{
  int binCount;

  @override
  Offset minmax;

  HistogramConfig({required this.binCount, required this.minmax});
  
  @override
  Map<String, num> get asMap => {
    "Bin count": binCount
  };
  
  @override
  void set(String path, num value) {
    if(path == "Bin count"){
      binCount = value.toInt();
    }
  }
}

class PDFConfig implements PlotConfig{
  double bw;

  @override
  Offset minmax;

  PDFConfig({required this.bw, required this.minmax});
  
  @override
  Map<String, num> get asMap => {
    "KDE bw log10": bw
  };
  
  @override
  void set(String path, num value) {
    if(path == "KDE bw log10"){
      bw = value.toDouble();
    }
  }
}

class CDFConfig implements PlotConfig{
  double bw;

  @override
  Offset minmax;

  CDFConfig({required this.bw, required this.minmax});

  @override
  Map<String, num> get asMap => {
    "KDE bw log10": bw
  };
  
  @override
  void set(String path, num value) {
    if(path == "KDE bw log10"){
      bw = value.toDouble();
    }
  }
}

abstract class Plot{
  void recalc(final String meas, final String signal, final PlotConfig config);
}

class Histogram extends Plot{
  final List<Bin> bins;

  Histogram({required this.bins});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    bins.clear();
    final HistogramConfig conf = config as HistogramConfig;

    final TypedDataListContainer? values = signalData[meas]?[signal]?.values;
    if(values == null){
      return;
    }

    num min = double.infinity;
    num max = double.negativeInfinity;
    for(final num value in values.iterable){
      if(value < min){
        min = value;
      }
      if(value > max){
        max = value;
      }
    }

    final double binSpan = (max - min) / conf.binCount;
    bins.addAll(List<Bin>.generate(conf.binCount, (index) => Bin(start: min + index * binSpan, stop: min + (index + 1) * binSpan, value: 0)));
    for(final num value in values.iterable){
      bins[math.min((value - min) ~/ binSpan, conf.binCount - 1)].value++;
    }
  }
}

class PDF extends Plot{
  KDEResult line;

  PDF({required this.line});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    final PDFConfig conf = config as PDFConfig;
        
    final TypedDataListContainer? values = signalData[meas]?[signal]?.values;
    if(values == null){
      return;
    }

    num min = double.infinity;
    num max = double.negativeInfinity;
    for(final num value in values.iterable){
      if(value < min){
        min = value;
      }
      if(value > max){
        max = value;
      }
    }

    final num trueRange = max - min;
    min = min - trueRange * 0.1;
    max = max + trueRange * 0.1;

    const int resolution = 300; // TODO pdfconf
    final double cellDist = (max - min) / resolution;
    line = KDE.estimatePDFBinning(
      values,
      Vector.fromList(List<num>.generate(resolution, (index) => min + index * cellDist)),
      math.pow(10, conf.bw).toDouble()
    );
  }
}

class CDF extends Plot{
  KDEResult line;

  CDF({required this.line});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    final CDFConfig conf = config as CDFConfig;
        
    final TypedDataListContainer? values = signalData[meas]?[signal]?.values;
    if(values == null){
      return;
    }

    num min = double.infinity;
    num max = double.negativeInfinity;
    for(final num value in values.iterable){
      if(value < min){
        min = value;
      }
      if(value > max){
        max = value;
      }
    }

    final num trueRange = max - min;
    min = min - trueRange * 0.1;
    max = max + trueRange * 0.1;

    const int resolution = 300; // TODO pdfconf
    final double cellDist = (max - min) / resolution;
    line = KDE.estimateCDFBinning(
      values,
      Vector.fromList(List<num>.generate(resolution, (index) => min + index * cellDist)),
      math.pow(10, conf.bw).toDouble()
    );
  }
}

abstract class StatisticsProcessor{
  static Stat stat(final String measurement, final String signal){
    if(!signalData.containsKey(measurement)){
      return const Stat(min: 0, max: 0, integral: 0, avg: 0);
    }
    if(!signalData[measurement]!.containsKey(signal)){
      return const Stat(min: 0, max: 0, integral: 0, avg: 0);
    }

    final SignalContainer channel = signalData[measurement]![signal]!;

    num min = double.infinity;
    num max = double.negativeInfinity;
    for(final num value in channel.values.iterable){
      if(value > max){
        max = value;
      }
      if(value < min){
        min = value;
      }
    }

    num integral = signalIntegral(measurement, signal, channel.timestamps.first.toDouble(), channel.timestamps.last.toDouble());
    num avg = integral / (channel.timestamps.last - channel.timestamps.first) * 1000; // ms to s
    return Stat(min: min, max: max, integral: integral, avg: avg);
  }
}