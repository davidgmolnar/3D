import 'dart:typed_data';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../window_type.dart';

///////
/// Ez csak time-series adat. A karakterisztikák meg gps-trackek a map_chartban lesznek

abstract class CustomDescriptor{

  void saveChannels();
  void loadChannels();

  @override
  int get hashCode;
  @override
  bool operator==(covariant CustomTimeseriesChartDescriptor other);
}

class CustomTimeseriesChartDescriptor implements CustomDescriptor{
  final String measurement;
  final List<String> signals;

  const CustomTimeseriesChartDescriptor({required this.measurement, required this.signals});

  static CustomTimeseriesChartDescriptor? from({required final String m, required final List<String> s}){
    if(signalData.containsKey(m) && s.every((signal) => signalData[m]!.containsKey(signal))){
      return CustomTimeseriesChartDescriptor(measurement: m, signals: s);
    }
    return null;
  }

  @override
  void saveChannels(){
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomTimeseriesChartDescriptor.saveChannel was called on a non-main process");
      return;
    }
    for(final String signal in signals){
      FileSystem.trySaveBytesToLocalSync(
        FileSystem.channelDir,
        "${measurement}_$signal.3DCHANNEL",
        signalData[measurement]![signal]!.toBytes()
      );
    }
  }

  @override
  void loadChannels(){
    if(windowType != WindowType.CUSTOM_CHART){
      localLogger.error("CustomTimeseriesChartDescriptor.loadChannel was called on a non-customchart process");
      return;
    }
    
    for(final String signal in signals){
      final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
        FileSystem.channelDir,
        "${measurement}_$signal.3DCHANNEL",
        deleteWhenDone: false
      );
      if(bytes.isEmpty){
        localLogger.error("Failed to import channel file: ${measurement}_$signal.3DCHANNEL");
        continue;
      }

      final SignalContainer sig = SignalContainer.fromBytes(bytes);
      signalData[measurement]![signal] = sig;
    }
  }

  @override
  int get hashCode => measurement.hashCode ^ signals.hashCode;

  @override
  bool operator==(covariant CustomTimeseriesChartDescriptor other){
    return other.measurement == measurement && other.signals == signals;
  }
}