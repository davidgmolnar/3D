import 'dart:io';

import '../../../data/signal_container.dart';
import '../../../data/updateable_valuenotifier.dart';
import '../../../io/logger.dart';
import '../../../io/serializer.dart';

class LogIOInfo{
  String? processingFile;
  double progressPercentage = 0;
  bool ready = false;
  bool error = false;
  bool sendingToController = false;
  int successulLoads = 0;
  List<LogEntry> context = [];
  Map resultJsonEncodeable = {};
}

class LogIOInfoController{
  static final UpdateableValueNotifier<LogIOInfo> logIOInfoNotifier = UpdateableValueNotifier<LogIOInfo>(LogIOInfo());

  static final List<String> _extensions = [];

  static Future<void> loadFiles(List<File> files) async {
    final List<LoadContext> result = [];
    for(int i = 0; i < files.length; i++){
      logIOInfoNotifier.update((value) {
        value.processingFile = files[i].absolute.path;
      });
      LoadContext loadContext = await Serializer.loadLogFile(files[i]);
      logIOInfoNotifier.update((value) {
        value.progressPercentage = (i + 1) * 100 / files.length;
        value.context.addAll(loadContext.context);
        _extensions.add(files[i].path.split('.').last);
        switch (_extensions[i]) {
          case 'csv':
            if(loadContext.storage !is Map<String, SignalContainer>){
              loadContext.context.add(LogEntry.error("Load return type error when loading ${loadContext.filePath}"));
            }
            break;
          default:
            loadContext.context.add(LogEntry.error("Unimplemented file format ${_extensions[i]}"));
        }
        if(loadContext.context.any((element) => element.level == LogLevel.ERROR && element.level == LogLevel.CRITICAL)){
          value.error = true;
        }
        else{
          result.add(loadContext);
          value.successulLoads++;
        }
      });
    }

    Map<int, Map<String, dynamic>> resultJsonEncodeable = {};
    for(int i = 0; i < result.length; i++){
      resultJsonEncodeable[i] = {};
      switch (_extensions[i]) {
        case 'csv':
          resultJsonEncodeable[i] = (result[i].storage as Map<String, SignalContainer>).map((key, value) => MapEntry(key, value.asJson));
          break;
        default:
      }
    }
    
    localLogger.addAll(logIOInfoNotifier.value.context);

    logIOInfoNotifier.update((value) {
      value.resultJsonEncodeable = resultJsonEncodeable;
      value.ready = true;
    });
  }

  static void reset(){
    _extensions.clear();
    logIOInfoNotifier.update((value) {
      value.processingFile = null;
      value.progressPercentage = 0;
      value.ready = false;
      value.error = false;
      value.successulLoads = 0;
      value.context = [];
    });
  }
}

