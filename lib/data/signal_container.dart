import '../ui/charts/chart_logic/chart_controller.dart';

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

  bool updateSignalContainer(ChartShowDuration duration){
    bool wasUpdated = false;
    // ...
    return wasUpdated;
  }

  static SignalContainer create(ChartShowDuration duration) {
    return SignalContainer(dbcName: "", values: [], displayName: "");
  }
} 