import 'dart:io';
import 'dart:typed_data';

import 'exporter.dart';
import 'logger.dart';
import 'importer.dart';

abstract class FileSystem{

  static String? _currentDirectory;

  static String get customTimeSeriesGroupDir => "CustomTimeSeriesGroups/";
  static String get customCharacteristicsGroupDir => "CustomCharacteristicsGroups/";
  static String get channelDir => "Channels/";

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
      localLogger.error("Unsupported operating system, FileSystem.getCurrentDirectory only supports Linux and Windows");
      return null;
    }
  }

  static Future<void> trySaveMapToLocalAsync(final String path, final String filename, final Map jsonEncodeable) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = await File("${_currentDirectory}Local/$path$filename").create(recursive: true);
    final RandomAccessFile access = await file.open(mode: FileMode.write);
    await access.writeFrom(Exporter.jsonToBytes(jsonEncodeable));
    await access.close();
  }

  static void trySaveMapToLocalSync(final String path, final String filename, final Map jsonEncodeable){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = File("${_currentDirectory}Local/$path$filename")..createSync(recursive: true);
    final RandomAccessFile access = file.openSync(mode: FileMode.write);
    access.writeFromSync(Exporter.jsonToBytes(jsonEncodeable));
    access.closeSync();
  }

  static Future<Map> tryLoadMapFromLocalAsync(final String path, final String filename, {final bool deleteWhenDone = false}) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return {};
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(!(await file.exists())){
      return {};
    }
    final RandomAccessFile access = await file.open(mode: FileMode.read);
    List<int> buffer = List.filled(await file.length(), -1);
    await access.readInto(buffer);
    await access.close();
    if(deleteWhenDone){
      await file.delete();
    }
    return Importer.jsonFromBytes(buffer);
  }

  static Map tryLoadMapFromLocalSync(final String path, final String filename, {final bool deleteWhenDone = false}){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return {};
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(!file.existsSync()){
      return {};
    }
    List<int> buffer = file.readAsBytesSync();
    if(deleteWhenDone){
      file.deleteSync();
    }
    return Importer.jsonFromBytes(buffer);
  }

  static Future<void> trySaveBytesToLocalAsync(final String path, final String filename, final Uint8List bytes) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = await File("${_currentDirectory}Local/$path$filename").create(recursive: true);
    final RandomAccessFile access = await file.open(mode: FileMode.write);
    await access.writeFrom(bytes);
    await access.close();
  }

  static void trySaveBytesToLocalSync(final String path, final String filename, final Uint8List bytes){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = File("${_currentDirectory}Local/$path$filename")..createSync(recursive: true);
    final RandomAccessFile access = file.openSync(mode: FileMode.write);
    access.writeFromSync(bytes);
    access.closeSync();
  }

  static Future<Uint8List> tryLoadBytesFromLocalAsync(final String path, final String filename, {final bool deleteWhenDone = false}) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return Uint8List(0);
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(!(await file.exists())){
      return Uint8List(0);
    }
    final RandomAccessFile access = await file.open(mode: FileMode.read);
    Uint8List buffer = Uint8List(await file.length());
    await access.readInto(buffer);
    await access.close();
    if(deleteWhenDone){
      await file.delete();
    }
    return buffer;
  }

  static Uint8List tryLoadBytesFromLocalSync(final String path, final String filename, {final bool deleteWhenDone = false}){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return Uint8List(0);
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(!file.existsSync()){
      return Uint8List(0);
    }
    Uint8List buffer = file.readAsBytesSync();
    if(deleteWhenDone){
      file.deleteSync();
    }
    return buffer;
  }

  static Future<void> tryDeleteFromLocalAsync(final String path, final String filename) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(await file.exists()){
      await file.delete();
      localLogger.info("File ${file.absolute} was successfully removed");
    }
    else{
      localLogger.warning("File ${file.absolute} cannot be removed as it doesnt exist");
    }
  }

  static void tryDeleteFromLocalSync(final String path, final String filename){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return;
    }
    final File file = File("${_currentDirectory}Local/$path$filename");
    if(file.existsSync()){
      file.deleteSync();
      localLogger.info("File ${file.absolute} was successfully removed");
    }
    else{
      localLogger.warning("File ${file.absolute} cannot be removed as it doesnt exist");
    }
  }

  static Future<List<FileSystemEntity>> tryListElementsInLocalAsync(final String path) async {
    if(await getCurrentDirectory == null){
      localLogger.error("Cant determine current directory");
      return [];
    }
    Directory("${_currentDirectory}Local/$path");
    final Directory dir = Directory("${_currentDirectory}Local/$path");
    if(await dir.exists()){
      return dir.list().toList();
    }
    else{
      return [];
    }
  }

  static List<FileSystemEntity> tryListElementsInLocalSync(final String path){
    if(_currentDirectory == null){
      localLogger.error("Cant determine current directory");
      return [];
    }
    final Directory dir = Directory("${_currentDirectory}Local/$path");
    if(dir.existsSync()){
      return dir.listSync();
    }
    else{
      return [];
    }
  }
}