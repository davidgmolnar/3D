import 'dart:typed_data';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../window_type.dart';

///////
/// Ez csak time-series adat. A karakterisztikák meg gps-trackek a map_chartban lesznek

abstract class CustomDescriptor{

  void saveChannel();
  void loadChannel();

  @override
  int get hashCode;
  @override
  bool operator==(covariant CustomTimeseriesChartDescriptor other);
}

class CustomTimeseriesChartDescriptor implements CustomDescriptor{
  final String measurement;
  final String signal;

  const CustomTimeseriesChartDescriptor({required this.measurement, required this.signal});

  static CustomTimeseriesChartDescriptor? from({required final String m, required final String s}){
    if(signalData.containsKey(m) && signalData[m]!.containsKey(s)){
      return CustomTimeseriesChartDescriptor(measurement: m, signal: s);
    }
    return null;
  }

  @override
  void saveChannel(){
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomTimeseriesChartDescriptor.saveChannel was called on a non-main process");
      return;
    }
    FileSystem.trySaveBytesToLocalSync(
      FileSystem.channelDir,
      "${measurement}_$signal.3DCHANNEL",
      signalData[measurement]![signal]!.toBytes()
    );
  }

  @override
  void loadChannel(){
    if(windowType != WindowType.CUSTOM_CHART){
      localLogger.error("CustomTimeseriesChartDescriptor.loadChannel was called on a non-customchart process");
      return;
    }
    final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
      FileSystem.channelDir,
      "${measurement}_$signal.3DCHANNEL",
      deleteWhenDone: true
    );
    if(bytes.isEmpty){
      localLogger.error("Failed to import channel file: ${measurement}_$signal.3DCHANNEL");
      return;
    }

    final SignalContainer sig = SignalContainer.fromBytes(bytes);
    signalData[measurement]![signal] = sig;
  }

  @override
  int get hashCode => measurement.hashCode ^ signal.hashCode;

  @override
  bool operator==(covariant CustomTimeseriesChartDescriptor other){
    return other.measurement == measurement && other.signal == signal;
  }
}