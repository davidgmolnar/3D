import 'package:flutter/material.dart';

import '../io/logger.dart';
import '../multiprocess/childprocess.dart';
import '../multiprocess/childprocess_api.dart';
import '../multiprocess/childprocess_controller.dart';
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

void runSelectedApp(){
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
  }
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

  localLogger.start();
  if(windowType == WindowType.MAIN_WINDOW){
    ChildProcessController().start();
  }
  else{
    ChildProcess().start();
    ChildProcess().signalReady();
  }
  return true;
}

void shutdown(){
  localLogger.stop();
  if(windowType == WindowType.MAIN_WINDOW){
    ChildProcessController().dispose();
  }
  else{
    ChildProcess().signalStop();
  }
}