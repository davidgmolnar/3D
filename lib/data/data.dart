import 'signal_container.dart';

// [measurement][signal] = data
Map<String, Map<String, SignalContainer>> signalData = {};

Map<String, List<String>> get measurementSignalMap => signalData.map((key, value) => MapEntry(key, value.keys.toList()));