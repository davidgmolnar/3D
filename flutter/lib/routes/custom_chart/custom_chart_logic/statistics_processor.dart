import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;

import 'package:ml_linalg/vector.dart';

import '../../../data/data.dart';
import '../../../data/sci/distribution.dart';
import '../../../data/sci/kde.dart';
import '../../../data/signal_container.dart';
import '../../../data/typed_data_list_container.dart';
import 'statistics_view_controller.dart';

enum StatType{
  // ignore: constant_identifier_names
  MIN,
  // ignore: constant_identifier_names
  MAX,
  // ignore: constant_identifier_names
  AVG,
  // ignore: constant_identifier_names
  INT
}

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

  num get(final StatType type){
    switch (type) {
      case StatType.MIN:
        return min;
      case StatType.MAX:
        return max;
      case StatType.AVG:
        return avg;
      case StatType.INT:
        return integral;
    }
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

    final SignalContainer? channel = signalData[meas]?[signal];
    if(channel == null){
      return;
    }

    final List meta = StatisticsProcessor.calcPlotMeta(channel);

    final double binSpan = (meta[1] - meta[0]) / conf.binCount;
    bins.addAll(List<Bin>.generate(conf.binCount, (index) => Bin(start: meta[0] + index * binSpan, stop: meta[0] + (index + 1) * binSpan, value: 0)));

    for(int i = 0; i < channel.values.size; i++){
      if(meta[2] == null || (meta[2] <= channel.timestamps[i] && channel.timestamps[i] <= meta[3])){
        bins[math.min((channel.values[i] - meta[0]) ~/ binSpan, conf.binCount - 1)].value++;
      }
    }
  }
}

class PDF extends Plot{
  KDEResult line;

  PDF({required this.line});

  @override
  void recalc(final String meas, final String signal, final PlotConfig config){
    final PDFConfig conf = config as PDFConfig;
        
    final SignalContainer? channel = signalData[meas]?[signal];
    if(channel == null){
      return;
    }

    final List meta = StatisticsProcessor.calcPlotMeta(channel);

    final num trueRange = meta[1] - meta[0];
    meta[0] = meta[0] - trueRange * 0.1;
    meta[1] = meta[1] + trueRange * 0.1;

    const int resolution = 300; // TODO pdfconf
    final double cellDist = (meta[1] - meta[0]) / resolution;

    TypedDataListContainer<Float32List> values = TypedDataListContainer(list: Float32List(0));

    for(int i = 0; i < channel.values.size; i++){
      if(meta[2] == null || (meta[2] <= channel.timestamps[i] && channel.timestamps[i] <= meta[3])){
        values.pushBack(channel.values[i]);
      }
    }
    values.shrinkToFit();

    line = KDE.estimatePDFBinning(
      values,
      Vector.fromList(List<num>.generate(resolution, (index) => meta[0] + index * cellDist)),
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
        
    final SignalContainer? channel = signalData[meas]?[signal];
    if(channel == null){
      return;
    }

    final List meta = StatisticsProcessor.calcPlotMeta(channel);

    final num trueRange = meta[1] - meta[0];
    meta[0] = meta[0] - trueRange * 0.1;
    meta[1] = meta[1] + trueRange * 0.1;

    const int resolution = 300; // TODO pdfconf
    final double cellDist = (meta[1] - meta[0]) / resolution;

    TypedDataListContainer<Float32List> values = TypedDataListContainer(list: Float32List(0));

    for(int i = 0; i < channel.values.size; i++){
      if(meta[2] == null || (meta[2] <= channel.timestamps[i] && channel.timestamps[i] <= meta[3])){
        values.pushBack(channel.values[i]);
      }
    }
    values.shrinkToFit();

    line = KDE.estimateCDFBinning(
      values,
      Vector.fromList(List<num>.generate(resolution, (index) => meta[0] + index * cellDist)),
      math.pow(10, conf.bw).toDouble()
    );
  }
}

abstract class StatisticsProcessor{
  static List<Stat> stat(final String measurement, final String signal){
    if(!signalData.containsKey(measurement)){
      return const [Stat(min: 0, max: 0, integral: 0, avg: 0)];
    }
    if(!signalData[measurement]!.containsKey(signal)){
      return const [Stat(min: 0, max: 0, integral: 0, avg: 0)];
    }

    final SignalContainer channel = signalData[measurement]![signal]!;

    final List<Stat> lapStats = [];
    if(StatisticsViewController.notifier.value["laps.selected"].isEmpty){
      final List meta = calcMeta(channel, -1);

      num integral = signalIntegral(measurement, signal, meta[2] ?? channel.timestamps.first.toDouble(), meta[3] ?? channel.timestamps.last.toDouble());
      num avg = integral / ((meta[3] ?? channel.timestamps.last) - (meta[2] ?? channel.timestamps.first)) * 1000; // ms to s
      lapStats.add(Stat(min: meta[0], max: meta[1], integral: integral, avg: avg));
    }

    for(final int lapIndex in StatisticsViewController.notifier.value["laps.selected"]){
      final List meta = calcMeta(channel, lapIndex);

      num integral = signalIntegral(measurement, signal, meta[2] ?? channel.timestamps.first.toDouble(), meta[3] ?? channel.timestamps.last.toDouble());
      num avg = integral / ((meta[3] ?? channel.timestamps.last) - (meta[2] ?? channel.timestamps.first)) * 1000; // ms to s
      lapStats.add(Stat(min: meta[0], max: meta[1], integral: integral, avg: avg));
    }
    return lapStats;
  }

  static List calcMeta(final SignalContainer channel, final int lapIndex){
    double min = double.infinity;
    double max = double.negativeInfinity;

    double? timeStart;
    double? timeStop;
    if(StatisticsViewController.notifier.value["laps.selected"].isNotEmpty){
      timeStart = StatisticsViewController.notifier.value["laps"][lapIndex].dx;
      timeStop = StatisticsViewController.notifier.value["laps"][lapIndex].dy;
    }

    for(int i = 0; i < channel.values.size; i++){
      if(StatisticsViewController.notifier.value["laps.selected"].isEmpty || (timeStart! <= channel.timestamps[i] && channel.timestamps[i] <= timeStop!)){
        if(channel.values[i] > max){
          max = channel.values[i].toDouble();
        }
        if(channel.values[i] < min){
          min = channel.values[i].toDouble();
        }
      }
    }
    return [min, max, timeStart, timeStop];
  }

  static List calcPlotMeta(final SignalContainer channel){
    double min = double.infinity;
    double max = double.negativeInfinity;

    double? timeStart;
    double? timeStop;
    if(StatisticsViewController.notifier.value["laps.plot_selected"] != null){
      timeStart = StatisticsViewController.notifier.value["laps"][StatisticsViewController.notifier.value["laps.plot_selected"]].dx;
      timeStop = StatisticsViewController.notifier.value["laps"][StatisticsViewController.notifier.value["laps.plot_selected"]].dy;
    }

    for(int i = 0; i < channel.values.size; i++){
      if(StatisticsViewController.notifier.value["laps.plot_selected"] == null || (timeStart! <= channel.timestamps[i] && channel.timestamps[i] <= timeStop!)){
        if(channel.values[i] > max){
          max = channel.values[i].toDouble();
        }
        if(channel.values[i] < min){
          min = channel.values[i].toDouble();
        }
      }
    }
    return [min, max, timeStart, timeStop];
  }
}