/*import 'dart:io';

import 'data/data.dart';
import 'data/settings.dart';
import 'data/signal_container.dart';
import 'io/importer.dart';*/
import 'routes/startup.dart';

void main(List<String> args) async {
  if(!await tryStartup(args)){
    return;
  }

  if(args.isEmpty){
    /*SettingsProvider.loadFromDisk();
    String measurementAlias = "test";
    LoadContext result = await Importer.loadLogFile(File("C:\\Users\\Lenovo\\Desktop\\3D_Test\\test.csv"));
    signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
    TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
    TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;*/

    //String measurementAlias2 = "D32";
    //LoadContext result2 = await Importer.loadLogFile(File("C:\\Users\\Lenovo\\Desktop\\3D_Test\\D32.BIN"));
    //signalData[measurementAlias2] = result2.storage as Map<String, SignalContainer>;
    //TraceSettingsProvider.addEntriesFrom(measurementAlias2, signalData[measurementAlias2]!.values.toList());
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
    //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_ECU_Heartbeat";}).isVisible = true;
  }

  runSelectedApp();
}