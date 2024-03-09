/*import 'dart:io';

import 'data/data.dart';
import 'data/settings.dart';
import 'data/signal_container.dart';
import 'io/serializer.dart';*/
import 'routes/startup.dart';

void main(List<String> args) async {
  if(!await tryStartup(args)){
    return;
  }

  if(args.isEmpty){
    /*Future.delayed(const Duration(seconds: 5), () async {
      print("start");
      SettingsProvider.loadFromDisk();
      String measurementAlias = "test";
      LoadContext result = await Serializer.loadLogFile(File("C:\\Users\\Lenovo\\Desktop\\3D\\test\\D32.BIN"),
        indicationCount: 100,
        lineProgressIndication: (p0, p1) {
          print("$p0${p1 != null ? ' - $p1' : ''}");
        },
      );
      signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
      TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
      TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
      //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_Cell_ID";}).isVisible = true;
      //TraceSettingsProvider.traceSettingNotifier.value[measurementAlias]!.firstWhere((element) {return element.signal == "HV_ECU_Heartbeat";}).isVisible = true;
    });*/
  }

  // TODO előbb a close handshake pusholva, majd a signalcontainer storage rework

  runSelectedApp();
}