import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/updateable_valuenotifier.dart';
import 'exporter.dart';
import 'file_system.dart';
import 'importer.dart';
import 'logger.dart';

abstract class FSCache{
  static const String _localPath = "Local/.fscache";
  static String _fullPath = "";
  static DateTime _lastModif = DateTime.now();
  static bool _initialized = false;
  static final Map<String, dynamic> _storage = {};
  static final UpdateableValueNotifier<bool> _notifier = UpdateableValueNotifier(false);

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
    if(await file.exists()){
      await file.delete();
    }
    await file.create(recursive: true);
    _lastModif = await file.lastModified();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkChange();
    });
    
    _initialized = true;
  }

  static void addListener(VoidCallback listener){
    _notifier.addListener(listener);
  }

  static void removeListener(VoidCallback listener){
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
        _storage.clear();
        _storage.addAll(Importer.jsonFromBytes(await file.readAsBytes()).cast<String, dynamic>());
        _lastModif = mod;
        _notifier.update((value) { });
      }
    }
    catch(ex){
      localLogger.error("FSCache update exception $ex");
    }
  }

  static dynamic _resolve(final String path){
    return path.split('.').fold<Map<String, dynamic>>(_storage, (previousValue, element) => previousValue[element].cast<String, dynamic>());
  }

  static T? read<T>(final String path, {final bool expect = false}){
    if(!_initialized){
      return null;
    }
    try{
      dynamic ret = _resolve(path);
      if(ret is T){
        return ret;
      }
      else{
        localLogger.warning("FSCache found ${ret.runtimeType}, not $T at $path");
      }
    }
    catch(ex){
      if(expect){
        localLogger.warning("FSCache did not find path $path");
      }
      return null;
    }
    return null;
  }

  static void _syncToDisk() async {
    File file = File(_fullPath);
    if(! await file.exists()){
      file.create(recursive: true);
      _lastModif = await file.lastModified();
    }

    try{
      file.writeAsBytes(Exporter.jsonToBytes(_storage));
    }
    catch(ex){
      localLogger.error("FSCache write exception $ex");
    }
  }

  static void write<T>(final String path, final T value){
    if(!_initialized){
      return;
    }
    final List<String> pathElements = path.split('.');
    final Map<String, dynamic> leaf = pathElements.sublist(0, pathElements.length - 1).fold<Map<String, dynamic>>(_storage, (previousValue, element){
      if(!previousValue.containsKey(element)){
        previousValue[element] = {};
      }
      return previousValue[element].cast<String, dynamic>();
    });
    leaf[pathElements.last] = value;
    _notifier.update((value) { });

    _syncToDisk();
  }
}