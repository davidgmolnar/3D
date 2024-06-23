import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/logger.dart';

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

class HistogramConfig{
  final int binCount;

  const HistogramConfig({required this.binCount});
}

class Histogram{

}

class PDFConfig{

}

class PDF{

}

class CDFConfig{

}

class CDF{

}

abstract class StatisticsProcessor{
  static Stat stat(final String measurement, final String signal){
    if(!signalData.containsKey(measurement)){
      localLogger.warning("No meas $measurement among  ${signalData.keys}", doNoti: false);
      return const Stat(min: 0, max: 0, integral: 0, avg: 0);
    }
    if(!signalData[measurement]!.containsKey(signal)){
      localLogger.warning("No signal $signal among  ${signalData[measurement]!.keys}", doNoti: false);
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