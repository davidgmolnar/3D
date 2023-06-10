import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../io/logger.dart';
import '../multiprocess/childprocess.dart';
import '../multiprocess/childprocess_api.dart';
import '../multiprocess/childprocess_controller.dart';
import '../ui/theme/theme.dart';
import 'log/screen.dart';
import 'main_window/screen.dart';
import 'map_chart/screen.dart';
import 'settings/screen.dart';
import 'time_series_chart/screen.dart';
import 'window_type.dart';

Map<WindowType,String> windowTypeTitle = {
  WindowType.INITIAL: "Loading",
  WindowType.MAIN_WINDOW: "3D Log Analyser",
  WindowType.SETTINGS: "Settings",
  WindowType.TIME_SERIES_CHART: "Chart",
  WindowType.MAP_CHART: "Map",
  WindowType.LOG: "Log",
};

void runSelectedApp() async {
  if(windowType == WindowType.MAIN_WINDOW){
    runApp(const MainWindowApp());
  }
  else if(windowType == WindowType.LOG){
    runApp(const LogApp());
  }
  else if(windowType == WindowType.MAP_CHART){
    runApp(const MapApp());
  }
  else if(windowType == WindowType.TIME_SERIES_CHART){
    runApp(const ChartApp());
  }
  else if(windowType == WindowType.SETTINGS){
    runApp(const SettingApp());
  }
  else{
    localLogger.critical("Failed to select app type to start, app type was ${windowType.name}");
    return;
  }
  doWhenWindowReady(() {
    appWindow.title = StyleManager.title ?? windowTypeTitle[windowType]!;
    appWindow.show();
  });
}

bool tryStartup(List<String> args){
  try{
    if(args.isEmpty){
      localSocketPort = masterSocketPort;
      windowType = WindowType.MAIN_WINDOW;
      localLogger = Logger(mainLogPath, "Master Logger");
    }
    else{
      localSocketPort = int.parse(args[1]);
      windowType = windowType.tryParse(args[0])!;
      localLogger = Logger(mainLogPath, "${windowType.name} Logger @$localSocketPort");
    }
  }
  catch (exc){
    return false;
  }
  return true;
}

Future<void> postStartup() async {
  localLogger.start();
  localLogger.info("Starting ${windowType.name}");
  if(windowType == WindowType.MAIN_WINDOW){
    await ChildProcessController.start();
  }
  else{
    await ChildProcess.start().then((_) => ChildProcess.signalReady());
  }
}

Future<void> shutdown() async {
  await localLogger.stop();
  if(windowType == WindowType.MAIN_WINDOW){
    ChildProcessController.dispose();
  }
  else{
    ChildProcess.signalStop();
  }
  exit(0);
}