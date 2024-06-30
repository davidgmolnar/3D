import 'dart:ui';
import 'dart:math' as math;

import '../../../data/data.dart';
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
    "KDE bw": bw
  };
  
  @override
  void set(String path, num value) {
    if(path == "KDE bw"){
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
    "KDE bw": bw
  };
  
  @override
  void set(String path, num value) {
    if(path == "KDE bw"){
      bw = value.toDouble();
    }
  }
}

class HistogramBin{
  final num start;
  final num stop;
  num value;

  HistogramBin({required this.start, required this.stop, required this.value});
}

abstract class Plot{
  void recalc(final String meas, final String signal, final PlotConfig config);
}

class Histogram extends Plot{
  final List<HistogramBin> bins;

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
    bins.addAll(List<HistogramBin>.generate(conf.binCount, (index) => HistogramBin(start: index * binSpan, stop: (index + 1) * binSpan, value: 0)));
    for(final num value in values.iterable){
      bins[math.min((value - min) ~/ binSpan, conf.binCount - 1)].value++;
    }
  }
}

class PDF extends Plot{
  final List<Offset> line;

  PDF({required this.line});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    line.clear();
    final PDFConfig conf = config as PDFConfig;
    
  }
}

class CDF extends Plot{
  final List<Offset> line;

  CDF({required this.line});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    line.clear();
    final CDFConfig conf = config as CDFConfig;
    
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