import 'dart:ui';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';

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

class HistogramBin{
  final num start;
  final num stop;
  final num value;

  HistogramBin({required this.start, required this.stop, required this.value});
}

class Histogram{
  final List<HistogramBin> bins;

  Histogram({required this.bins});
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

class PDF{
  final List<Offset> line;

  PDF({required this.line});
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

class CDF{
  final List<Offset> line;

  CDF({required this.line});
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

  /*static Histogram hist(final String measurement, final String signal, final HistogramConfig config){

  }

  static PDF pdf(final String measurement, final String signal, final PDFConfig config){
    
  }

  static CDF cdf(final String measurement, final String signal, final CDFConfig config){
    
  }*/
}