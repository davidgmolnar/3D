import 'measurement.dart';

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
  // etc
} 