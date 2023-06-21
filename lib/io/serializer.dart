import 'dart:convert';
import 'dart:io';

import '../data/calibration_script.dart';
import '../data/signal_container.dart';
import 'logger.dart';

class LoadContext{
  final dynamic storage;
  final List<LogEntry> context;
  final String filePath;

  LoadContext({
    required this.storage,
    required this.context,
    required this.filePath
  });
}

abstract class Serializer {

  static Utf8Decoder utf8Decoder = const Utf8Decoder();

  static JsonDecoder jsonDecoder = const JsonDecoder();

  static Map jsonFromBytes(List<int> bytes) => jsonDecoder.convert(safeUTF8Decode(bytes));

  static Map<String, double> timeUnitToMsMultiplier = {
    "min": 60*1000,
    "s": 1000,
    "ms": 1,
    "us": 0.001
  };

  static String safeUTF8Decode(List<int> bytes){
    List<int> removeIndexes = [];
    for(int i = 0; i < bytes.length; i++){
      if(bytes[i] > 127){
        removeIndexes.add(i);
      }
    }

    for(int i in removeIndexes.reversed){
      bytes.removeAt(i);
    }

    return utf8Decoder.convert(bytes);
  }
  
  static Future<LoadContext> loadLogFile(File file) async {
    try{
      String extension = file.path.split('.').last;
      if(await file.exists()){
        switch (extension) {
          case "csv":
            return await _csvLoader(file);
          case "bin":
            return await _binaryLoader(file);
          //case "txt":
          //  return await _txtLogLoader(file);
          default:
            return LoadContext(storage: null, context: [LogEntry.error("Unrecognized file format ${file.absolute.path} contents not loaded")], filePath: file.absolute.path);
        }
      }
      return LoadContext(storage: null, context: [LogEntry.error("File ${file.absolute.path} does not exist)")], filePath: file.absolute.path);
    }
    catch (exc){
      return LoadContext(storage: null, context: [LogEntry.error("Unknown error when loading ${file.absolute.path}, ${exc.toString()}")], filePath: file.absolute.path);
    }
  }

  static Future<LoadContext> _csvLoader(File file) async {
    Map<String, SignalContainer> storage = {};
    List<LogEntry> context = [LogEntry.info("Started loading csv ${file.absolute.path}")];
    List<String> lines = safeUTF8Decode(await file.readAsBytes()).split('\n');
    if(lines.length < 3){
      context.add(LogEntry.warning("File ${file.absolute.path} has less than 3 lines, cant have meaningful data, skipping"));
    }
    //else if(!lines[0].startsWith('Time,')){
    //  context.add(LogEntry.warning("File ${file.absolute.path} does not start with 'Time' channel declaration, skipping"));
    //}
    else{
      List<String> signals = lines[0].trim().split(',');
      List<String> units = lines[1].trim().split(',');
      if(!signals.contains('Time')){
        context.add(LogEntry.warning("File ${file.absolute.path} does not have 'Time' channel declaration, skipping"));
        return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
      }
      int timeIndex = signals.indexOf('Time');
      double? timeToMsMultiplier = timeUnitToMsMultiplier[units[signals.indexOf('Time')]];
      if(timeToMsMultiplier == null){
        context.add(LogEntry.warning("File ${file.absolute.path} has undefined 'Time' channel unit, skipping"));
        return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
      }
      for(int i = 0; i < signals.length; i++){
        if(i != timeIndex){
          storage[signals[i]] = SignalContainer(dbcName: signals[i], values: [], displayName: signals[i], unit: units[i].isEmpty ? null : units[i]);
        }
      }
      int lineCnt = 3;
      try{
        for(String line in lines.sublist(2)){
          List<String> tokens = line.trim().split(',');
          if(tokens.length != signals.length){
            continue;
          }
          int timeStamp = (double.parse(tokens[timeIndex]) * timeToMsMultiplier).toInt();
          for(int i = 0; i < signals.length; i++){
            if(i != timeIndex){
              storage[signals[i]]!.values.add(Measurement(double.parse(tokens[i]), timeStamp));
            }
          }
          lineCnt++;
        }
      }
      catch (exc){
        context.add(LogEntry.warning("Double.parse() exception when loading file ${file.absolute.path} on line $lineCnt"));
        return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
      }
    }
    context.add(LogEntry.info("Successfully loaded csv ${file.absolute.path}"));
    return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
  }

  static Future<LoadContext> _binaryLoader(File file) async {
    // Map<String, SignalContainer> data = {};
    throw UnimplementedError();
    // ...
    // return data;
  }

  static Future<LoadContext> loadCalfile(File file) async {
    try{
      String extension = file.path.split('.').last;
      if(await file.exists()){
        switch (extension) {
          case "CAL":
            return await _CALLoader(file);
          //case ".3DCAL":
          //  return await _3DCALLoader(file);
          default:
            return LoadContext(storage: null, context: [LogEntry.error("Unrecognized file format ${file.absolute.path} contents not loaded")], filePath: file.absolute.path);
        }
      }
      return LoadContext(storage: null, context: [LogEntry.error("File ${file.absolute.path} does not exist)")], filePath: file.absolute.path);
    }
    catch (exc){
      return LoadContext(storage: null, context: [LogEntry.error("Unknown error when loading ${file.absolute.path}, ${exc.toString()}")], filePath: file.absolute.path);
    }
  }

  // ignore: non_constant_identifier_names
  static Future<LoadContext> _CALLoader(File file) async {
    List<int> bytes = await file.readAsBytes().then((value) => value.toList());
    int originalLength = bytes.length;
    String lines = safeUTF8Decode(bytes);
    List<LogEntry> context = [LogEntry.info("Started loading Calfile ${file.absolute.path}")];

    if(lines.length != originalLength){
      context.add(LogEntry.warning("Removed ${originalLength - lines.length} non UTF-8 decodeable characters when loading ${file.absolute.path}"));
    }

    CalibrationScript script = CalibrationScript(lines.split('\n').map((line) => ScriptInstruction(line)).toList(), file.absolute.path);
    script.instructions.removeWhere((instruction) => instruction.line.isEmpty);
    context.add(LogEntry.info("Finished loading Calfile with ${script.instructions.length} instructions"));

    return LoadContext(storage: script, context: context, filePath: file.absolute.path);
  }

  // Future<vmi> loadUIfile(File file) async {}
}