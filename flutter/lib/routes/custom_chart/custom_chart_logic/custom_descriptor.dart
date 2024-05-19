import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../multiprocess/childprocess_controller.dart';
import '../../startup.dart';
import '../../window_type.dart';
import 'custom_chart_window_type.dart';

abstract class CustomDescriptor{

  void saveChannels();
  void loadChannels();

  @override
  int get hashCode;
  @override
  bool operator==(covariant CustomDescriptor other);
}

class CustomTimeseriesChartDescriptor implements CustomDescriptor{
  final String measurement;
  final List<String> signals;

  const CustomTimeseriesChartDescriptor({required this.measurement, required this.signals});

  static CustomTimeseriesChartDescriptor? from({required final String m, required final List<String> s}){
    return CustomTimeseriesChartDescriptor(measurement: m, signals: s);
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
      localLogger.info("Imported channel file: ${measurement}_$signal.3DCHANNEL");

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

class CustomCharacteristicsDescriptor implements CustomDescriptor{

  final String name;
  final String measurement;
  final String baseSignal;
  final List<String> compSignals;

  const CustomCharacteristicsDescriptor({required this.name, required this.measurement, required this.baseSignal, required this.compSignals});

  @override
  void loadChannels() {
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomCharacteristicsDescriptor.loadChannel was called on a non-main process");
      return;
    }

    final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
      FileSystem.channelDir,
      "${measurement}_$baseSignal.3DCHANNEL",
      deleteWhenDone: false
    );
    if(bytes.isEmpty){
      localLogger.error("Failed to import channel file: ${measurement}_$baseSignal.3DCHANNEL");
    }
    else{
      localLogger.info("Imported channel file: ${measurement}_$baseSignal.3DCHANNEL");
    }

    final SignalContainer sig = SignalContainer.fromBytes(bytes);
    signalData[measurement]![baseSignal] = sig;

    for(final String signal in compSignals){
      final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
        FileSystem.channelDir,
        "${measurement}_$signal.3DCHANNEL",
        deleteWhenDone: false
      );
      if(bytes.isEmpty){
        localLogger.error("Failed to import channel file: ${measurement}_$signal.3DCHANNEL");
        continue;
      }
      localLogger.info("Imported channel file: ${measurement}_$signal.3DCHANNEL");

      final SignalContainer sig = SignalContainer.fromBytes(bytes);
      signalData[measurement]![signal] = sig;
    }
  }

  @override
  void saveChannels() {
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomCharacteristicsDescriptor.saveChannel was called on a non-main process");
      return;
    }

    FileSystem.trySaveBytesToLocalSync(
      FileSystem.channelDir,
      "${measurement}_$baseSignal.3DCHANNEL",
      signalData[measurement]![baseSignal]!.toBytes()
    );
    for(final String signal in compSignals){
      FileSystem.trySaveBytesToLocalSync(
        FileSystem.channelDir,
        "${measurement}_$signal.3DCHANNEL",
        signalData[measurement]![signal]!.toBytes()
      );
    }
  }

  Map toJson(){
    return {
      "meas": measurement,
      "base_signal": baseSignal,
      "comp_signals": compSignals,
    };
  }

  static CustomCharacteristicsDescriptor? fromJson(final Map json, final String name){
    if(!json.containsKey("meas") || json["meas"] is! String){
      return null;
    }
    if(!json.containsKey("base_signal") || json["base_signal"] is! String){
      return null;
    }
    if(!json.containsKey("comp_signals") || json["comp_signals"] is! List){
      return null;
    }
    if((json["comp_signals"] as List).any((element) => element is! String)){
      return null;
    }
    final CustomCharacteristicsDescriptor char = CustomCharacteristicsDescriptor(name: name, measurement: json["meas"], baseSignal: json["base_signal"], compSignals: json["comp_signals"]);
    return char;
  }

  void save(){
    FileSystem.trySaveMapToLocalSync(FileSystem.customTimeSeriesGroupDir, "$name.3DCTCG", toJson());
  }

  static Future<CustomCharacteristicsDescriptor?> load(final String name) async {
    final Map json = await FileSystem.tryLoadMapFromLocalAsync(FileSystem.customTimeSeriesGroupDir, "$name.3DCTCG", deleteWhenDone: false);
    return fromJson(json, name);
  }

  Future<void> launch() async {    
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomCharacteristicsDescriptor.launch was called on a non-main process");
      return;
    }
    
    save();
    saveChannels();
    
    final int port = await ChildProcessController.addConnection(
      WindowType.CUSTOM_CHART,
      WindowSetupInfo(name,
                      const Size(1000,700),
                      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.center(Offset.zero) - const Size(1000,700).center(Offset.zero)
      )
    );
    ChildProcessController.sendTo(Command(
      port,
      CommandType.DATA,
      setCustomChartWindowTypePayload(CustomChartWindowType.CHARACTERISTICS)
    ));
    ChildProcessController.sendTo(Command(
      port,
      CommandType.DATA,
      setCustomChartDescriptorPayload(
        name,
        -1
      )
    ));
  }
  
  @override
  int get hashCode => measurement.hashCode ^ baseSignal.hashCode ^ compSignals.hashCode;

  @override
  bool operator==(covariant CustomCharacteristicsDescriptor other){
    return other.measurement == measurement && other.baseSignal == baseSignal && other.compSignals == compSignals;
  }
}