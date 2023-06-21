import 'dart:io';

import 'deserializer.dart';
import 'logger.dart';
import 'serializer.dart';

abstract class FileSystem{

  static String? _currentDirectory;

  static Future<String?> get getCurrentDirectory async {
    if(_currentDirectory != null){
      return _currentDirectory;
    }
    String dir = Platform.resolvedExecutable;
    if(Platform.isWindows){  // Linux nem buzi
      dir = dir.replaceAll(r'\', '/');
    }
    dir = dir.split('/').reversed.toList().sublist(1).reversed.toList().join('/');
    if(Platform.isWindows){
      dir = dir.replaceAll('/', r'\');
      dir = dir + r'\';
      _currentDirectory = dir;
      return dir;
    }
    else if(Platform.isLinux){
      dir = dir + r'/';
      _currentDirectory = dir;
      return dir;
    }
    else{
      return null;
    }
  }

  static Future<void> trySaveMapToLocalAsync(String path, String filename, Map jsonEncodeable) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = await File("${_currentDirectory}Local/$path$filename").create(recursive: true);
    final RandomAccessFile access = await file.open(mode: FileMode.write);
    await access.writeFrom(Deserializer.jsonToBytes(jsonEncodeable));
    await access.close();
  }

  static Future<void> trySaveMapToLocalSync(String path, String filename, Map jsonEncodeable) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = File("${_currentDirectory}Local/$path$filename")..createSync(recursive: true);
    final RandomAccessFile access = file.openSync(mode: FileMode.write);
    access.writeFromSync(Deserializer.jsonToBytes(jsonEncodeable));
    access.closeSync();
  }

  static Future<Map> tryLoadMapFromLocalAsync(String path, String filename, {bool deleteWhenDone = false}) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return {};
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    final RandomAccessFile access = await file.open(mode: FileMode.read);
    List<int> buffer = [];
    await access.readInto(buffer);
    await access.close();
    if(deleteWhenDone){
      await file.delete();
    }
    return Serializer.jsonFromBytes(buffer);
  }

  static Future<Map> tryLoadMapFromLocalSync(String path, String filename, {bool deleteWhenDone = false}) async{
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return {};
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    List<int> buffer = await file.readAsBytes();
    if(deleteWhenDone){
      file.deleteSync();
    }
    return Serializer.jsonFromBytes(buffer);
  }
}