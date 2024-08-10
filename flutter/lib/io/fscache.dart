import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/custom_notifiers.dart';
import '../routes/window_type.dart';
import 'exporter.dart';
import 'file_system.dart';
import 'importer.dart';
import 'logger.dart';

abstract class FSCache{
  static const String _localPath = "Local/.fscache";
  static String _fullPath = "";
  static DateTime _lastModif = DateTime.now();
  static bool _initialized = false;
  static final MappedConditionalNotifier<dynamic> _notifier = MappedConditionalNotifier(value: {});

  static String get importedMeasurementsPath => "main.imported";
  static String get visibleTraceSettingsNamePath => "main.trace.visible_signals";
  static String get allTraceSettingsNamePath => "main.trace.all_signals";
  static String get lapdataPath => "main.lapdata";
  static String get tempLapdataPath => "main.lapdata.temp";

  static Future<void> init() async {
    if(_initialized){
      localLogger.warning("FSCache already initialized", doNoti: false);
      return;
    }
    final String? dir = await FileSystem.getCurrentDirectory;
    if(dir == null){
      localLogger.error("FSCache failed to init due to unknown application dir", doNoti: false);
      return;
    }

    _fullPath = "$dir$_localPath";
    File file = File(_fullPath);
    if(windowType == WindowType.MAIN_WINDOW){
      if(await file.exists()){
        await file.delete();
      }
      await file.create(recursive: true);
    }
    else if(await file.length() != 0){
      _notifier.value.addAll(Importer.jsonFromBytes(await file.readAsBytes()).cast<String, dynamic>());
    }
    _notifier.updateAll();
    _lastModif = await file.lastModified();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkChange();
    });
    
    _initialized = true;
  }

  static void addListener(final VoidCallback listener, final List<String> keysToWatch){
    _notifier.addListener(listener, keysToWatch);
  }

  static void removeListener(final VoidCallback listener){
    _notifier.removeListener(listener);
  }

  static void _checkChange() async {
    try{
      File file = File(_fullPath);
      if(! await file.exists()){
        file.create(recursive: true);
        _lastModif = await file.lastModified();
        return;
      }

      final DateTime mod = await file.lastModified();
      if(_lastModif.isBefore(mod)){
        if(await file.length() != 0){
          final Map<String, dynamic> loadedEntries = Importer.jsonFromBytes(await file.readAsBytes()).cast<String, dynamic>();
          for(final String key in loadedEntries.keys){
            if(_notifier.value.containsKey(key)){
              //if(_notifier.value[key] != loadedEntries[key]){
                _notifier.update(key, loadedEntries[key]!);
              //}
            }
            else{
              _notifier.update(key, loadedEntries[key]!);
            }
          }
        }
        else{
          _notifier.value.clear();
        }
        _lastModif = mod;
      }
    }
    catch(ex){
      localLogger.error("FSCache update exception $ex", doNoti: false);
    }
  }

  static T? read<T>(final String path, {final bool expect = false}){
    if(!_initialized){
      return null;
    }

    if(!_notifier.value.containsKey(path)){
      if(expect){
        localLogger.warning("FSCache did not find path $path", doNoti: false);
      }
      return null;
    }

    if(_notifier.value[path] is T){
      return _notifier.value[path];
    }

    localLogger.warning("FSCache found ${_notifier.value[path].runtimeType}, not $T at $path", doNoti: false);
    return null;
  }

  static void _syncToDisk() async {
    File file = File(_fullPath);
    if(! await file.exists()){
      file.create(recursive: true);
      _lastModif = await file.lastModified();
    }

    try{
      file.writeAsBytes(Exporter.jsonToBytes(_notifier.value));
    }
    catch(ex){
      localLogger.error("FSCache write exception $ex");
    }
  }

  static void write<T>(final String path, final T value, {final bool doNotify = true}){
    if(!_initialized){
      return;
    }
    if(_notifier.value[path] != value){
      if(doNotify){
        _notifier.update(path, value);
      }
      else{
        _notifier.value[path] = value;
      }
      _syncToDisk();
    }
  }
}