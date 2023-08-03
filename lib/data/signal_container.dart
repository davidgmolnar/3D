import '../ui/charts/chart_logic/chart_controller.dart';
import 'data.dart';

class Measurement{
  final num value;
  /// Timestamp in ms
  final int timeStamp;

  Measurement(this.value, this.timeStamp);

  Map<String, num> get asJson => {
    "value": value,
    "timeStamp": timeStamp
  };

  static Measurement fromJson(Map<String, num> map){
    return Measurement(map['value']!, map['timeStamp']! as int);
  }
}

class SignalContainer{
  final List<Measurement> values;
  final String dbcName;
  final String? unit;
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

  void updateSignalContainer(ChartShowDuration duration, ChartShowDuration oldDuration, String measurement){
    /*final int startDifference = duration.timeOffset - oldDuration.timeOffset;
    final int endDifference = duration.timeOffset - oldDuration.timeOffset + duration.timeDuration + oldDuration.timeDuration;
    values.removeWhere((element) => element.timeStamp < duration.timeOffset);
    values.removeWhere((element) => element.timeStamp > duration.timeOffset + duration.timeDuration);
    List<Measurement> left = */
    // return;
  }

  static SignalContainer create(ChartShowDuration duration, String dbcName, String displayName, String measurement) {
    List<Measurement> values = signalData[measurement]![dbcName]!.values.skipWhile((meas) => meas.timeStamp < duration.timeOffset).toList();
    values = values.takeWhile((meas) => meas.timeStamp < duration.timeOffset + duration.timeDuration).toList();
    return SignalContainer(dbcName: dbcName, values: values, displayName: displayName);
  }
} 