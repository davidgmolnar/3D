import '../ui/charts/chart_logic/chart_controller.dart';

class Measurement{
  final num value;
  /// Timestamp in ms
  final int timeStamp;

  Measurement(this.value, this.timeStamp);
}

class SignalContainer{
  List<Measurement> values;
  final String dbcName;
  final String? unit;
  String displayName;

  SignalContainer({
    required this.dbcName,
    required this.values,
    required this.displayName,
    this.unit
  });

  void updateSignalContainer(ChartShowDuration duration){
    
  }

  static SignalContainer create(ChartShowDuration duration) {
    return SignalContainer(dbcName: "", values: [], displayName: "");
  }
  // etc
} 