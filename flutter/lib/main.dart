import 'dart:io';

import 'data/data.dart';
import 'data/settings.dart';
import 'data/signal_container.dart';
import 'io/importer.dart';
import 'routes/startup.dart';

void main(List<String> args) async {
  if(!await tryStartup(args)){
    return;
  }

  if(args.isEmpty){
    SettingsProvider.loadFromDisk();
    String measurementAlias = "test";
    LoadContext result = await Importer.loadLogFile(File("C:\\Users\\Lenovo\\Desktop\\3D_Test\\test.csv"));
    signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
    TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_ECU_Heartbeat";}).isVisible = true;
  }

  runSelectedApp();
}