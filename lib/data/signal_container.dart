import '../ui/charts/chart_area.dart';
import 'calibration/unit.dart';

class Measurement{
  num value;
  /// Timestamp in ms
  int timeStamp;

  Measurement(this.value, this.timeStamp);

  Map<String, num> get asJson => {
    "value": value,
    "timeStamp": timeStamp
  };

  PlotPoint toPlotPoint(final ScalingInfo scaling){
    return PlotPoint(x: (timeStamp - scaling.timeOffset) * scaling.timeScale, y: (value - scaling.valueOffset) * scaling.valueScale);
  }

  num interpAt(final Measurement other, final int ts){
    if(timeStamp <= other.timeStamp){
      if(ts == timeStamp){
        return value;
      }
      else if(ts == other.timeStamp){
        return other.value;
      }
      else{
        return value + (other.value - value) / (other.timeStamp - timeStamp) * (ts - timeStamp);
      }
    }
    else{
      return other.interpAt(this, ts);
    }
  }

  static Measurement fromJson(Map<String, num> map){
    return Measurement(map['value']!, map['timeStamp']! as int);
  }
}

class SignalContainer{
  final List<Measurement> values;
  final String dbcName;
  final Unit? unit;
  String displayName;

  SignalContainer({
    required this.dbcName,
    required this.values,
    required this.displayName,
    this.unit
  });

  Map<String, dynamic> get asJson => {
    "dbcName": dbcName,
    "displayName": displayName,
    "unit": unit ?? "NOT_SET",
    "values": values.asMap().map((key, value) => MapEntry(key, value.asJson))
  };

  static SignalContainer fromJson(Map<String, dynamic> map){
    return SignalContainer(
      dbcName: map['dbcName'],
      displayName: map['displayName'],
      unit: map['unit'] == "NOT_SET" ? null : map['unit'],
      values: map['values'].values.map((element) => element.fromJson(element)).toList()
    );
  }
} 