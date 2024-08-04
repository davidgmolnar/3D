import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';

import '../data/calculation/constants.dart';
import '../data/lapdata.dart';
import '../data/settings.dart';
import '../io/file_system.dart';
import '../io/fscache.dart';
import '../io/logger.dart';
import '../multiprocess/childprocess.dart';
import '../multiprocess/childprocess_api.dart';
import '../multiprocess/childprocess_controller.dart';
import '../ui/theme/theme.dart';
import 'lap_editor/screen.dart';
import 'log/screen.dart';
import 'main_window/screen.dart';
import 'map_chart/screen.dart';
import 'settings/screen.dart';
import 'custom_chart/screen.dart';
import 'window_type.dart';

Map<WindowType,String> windowTypeTitle = {
  WindowType.INITIAL: "Loading",
  WindowType.MAIN_WINDOW: "3D Log Analyzer",
  WindowType.SETTINGS: "Settings",
  WindowType.CUSTOM_CHART: "Chart",
  WindowType.MAP_CHART: "Map",
  WindowType.LOG: "Log",
  WindowType.LAP_EDITOR: "Lap Editor",
};

class WindowSetupInfo{
  final String title;
  final Size size;
  final Offset position;

  WindowSetupInfo(this.title, this.size, this.position);

  static WindowSetupInfo? fromJson(Map json){
    if(!json.containsKey('title') || json['title'] is! String){
      return null;
    }
    else if(!json.containsKey('size_x') || json['size_x'] is! num){
      return null;
    }
    else if(!json.containsKey('size_y') || json['size_y'] is! num){
      return null;
    }
    else if(!json.containsKey('pos_x') || json['pos_x'] is! num){
      return null;
    }
    else if(!json.containsKey('pos_y') || json['pos_y'] is! num){
      return null;
    }
    else{
      return WindowSetupInfo(json['title'], Size(json['size_x'].toDouble(), json['size_y'].toDouble()), Offset(json['pos_x'].toDouble(), json['pos_y'].toDouble()));
    }
  }

  Map<String, dynamic> get asJson => {
    "title": title,
    "size_x": size.width,
    "size_y": size.height,
    "pos_x": position.dx,
    "pos_y": position.dy
  };
}

WindowSetupInfo? windowSetup;

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
  else if(windowType == WindowType.CUSTOM_CHART){
    runApp(const CustomChartApp());
  }
  else if(windowType == WindowType.SETTINGS){
    runApp(const SettingApp());
  }
  else if(windowType == WindowType.LAP_EDITOR){
    runApp(const LapEditorApp());
  }
  else{
    localLogger.critical("Failed to select app type to start, app type was ${windowType.name}");
    return;
  }
  doWhenWindowReady(() {
    if(windowSetup != null){
      appWindow.title = windowSetup!.title;
      appWindow.size = windowSetup!.size;
      appWindow.position = windowSetup!.position;
    }
    else{
      appWindow.title = windowTypeTitle[windowType]!;
    }
    appWindow.show();
  });
}

Future<bool> tryStartup(List<String> args) async {
  await FileSystem.getCurrentDirectory;
  try{
    if(args.isEmpty){
      localSocketPort = masterSocketPort;
      windowType = WindowType.MAIN_WINDOW;
      localLogger = Logger(mainLogPath, "MASTER");
      localLogger.start();
    }
    else{
      localSocketPort = int.parse(args[1]);
      windowType = windowType.tryParse(args[0])!;
      localLogger = Logger(mainLogPath, "${windowType.name} @$localSocketPort");
      localLogger.start();
      windowSetup = WindowSetupInfo.fromJson(FileSystem.tryLoadMapFromLocalSync("", args[2], deleteWhenDone: true));
      StyleManager.title = windowSetup!.title;
    }
  }
  catch (exc){
    localLogger.stop();
    return false;
  }
  return true;
}

Future<void> postStartup(var root) async {
  await FSCache.init();
  localLogger.start();
  localLogger.info("Starting ${windowType.name}", doNoti: false);
  if(windowType != WindowType.MAIN_WINDOW && windowSetup == null){
    localLogger.error("Failed to load window setup file");
  }
  if(windowType == WindowType.MAIN_WINDOW){
    appWindow.maximize();
    await ChildProcessController.start();
  }
  else{
    await ChildProcess.start().then((_) => ChildProcess.signalReady());
  }
  Const.loadFromDisk();
  SettingsProvider.loadFromDisk();
  LapData.init();
  windowManager.addListener(root);
  windowManager.setPreventClose(true);
  if(windowType == WindowType.LAP_EDITOR){
    windowManager.setResizable(false);
  }
}

Future<void> shutdown() async {
  if(windowType == WindowType.MAIN_WINDOW){
    ChildProcessController.dispose();
    await localLogger.stop();
    exit(0);
  }
  else{
    ChildProcess.signalStop();
  }
}