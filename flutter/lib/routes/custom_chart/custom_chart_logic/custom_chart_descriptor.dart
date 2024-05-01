import 'dart:typed_data';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../window_type.dart';

///////
/// Ez csak time-series adat. A karakterisztikák meg gps-trackek a map_chartban lesznek

const String _channelDir = "Channels/";

class CustomChartDescriptor{
  final String measurement;
  final String signal;

  const CustomChartDescriptor({required this.measurement, required this.signal});

  static CustomChartDescriptor? from({required final String m, required final String s}){
    if(signalData.containsKey(m) && signalData[m]!.containsKey(s)){
      return CustomChartDescriptor(measurement: m, signal: s);
    }
    return null;
  }

  void saveChannel(){
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomChartDescriptor.saveChannel was called on a non-main process");
      return;
    }
    FileSystem.trySaveBytesToLocalSync(
      _channelDir,
      "${measurement}_$signal.3DCHANNEL",
      signalData[measurement]![signal]!.toBytes()
    );
  }

  void loadChannel(){
    if(windowType != WindowType.CUSTOM_CHART){
      localLogger.error("CustomChartDescriptor.loadChannel was called on a non-customchart process");
      return;
    }
    final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
      _channelDir,
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
}