/*import 'dart:io';/

import 'data/data.dart';
import 'data/settings.dart';
import 'data/signal_container.dart';
import 'io/serializer.dart';*/
import 'routes/startup.dart';

void main(List<String> args) async {
  if(!await tryStartup(args)){
    return;
  }

  /*String measurementAlias = "test";
  LoadContext result = await Serializer.loadLogFile(File("C:\\Users\\Lenovo\\Desktop\\3D-Converters\\out\\test.csv"));
  signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
  TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
  TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;*/

  runSelectedApp();
}