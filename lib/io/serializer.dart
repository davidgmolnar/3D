import 'dart:convert';
import 'dart:io';

import '../data/calibration/calibration_script_parsing.dart';
import '../data/calibration/unit.dart';
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
  
  static Future<LoadContext> loadLogFile(File file, {Function(double, String?)? lineProgressIndication, int? indicationCount}) async {
    try{
      String extension = file.path.split('.').last;
      if(await file.exists()){
        switch (extension) {
          case "csv":
            return await _csvLoader(file, lineProgressIndication: lineProgressIndication, indicationCount: indicationCount);
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

  static Future<LoadContext> _csvLoader(File file, {Function(double, String?)? lineProgressIndication, int? indicationCount}) async {
    // TODO a nagyon nem változó részeken lehet valahogy spórolni kéne, pl bináris/int/double csatornákat külön lehetne kezelni, vagy egyéb módon memóriára optimalizálni
    // TODO a nem változó részek közül az első és utolsó pontot lehet megtartani így a calibrációs interpolálásnál felfutó élek meg a jelleg megmarad
    // TODO ^^ de akkor a kurzor értékeket is interpolálni kell, most ez egy nearest measurement value

    // TODO option interp import vagy zoh import, ezt signaldata[meas]-enként tárolni kell hogy mi volt mert akkor pl a kurzor értékek a kurzoridőhöz képesti legutóbbi értékek nem interp
    Map<String, SignalContainer> storage = {};
    List<LogEntry> context = [];
    final bool doIndication = lineProgressIndication != null && indicationCount != null;
    {
      final LogEntry entry = LogEntry.info("Started loading csv ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
      }
    }
    {
      final LogEntry entry = LogEntry.info("Reading file ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
      }
    }
    await Future.delayed(const Duration(milliseconds: 10));
    List<String> lines = safeUTF8Decode((await file.readAsBytes()).toList()).split('\n');
    {
      final LogEntry entry = LogEntry.info("File read ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
      }
    } 
    await Future.delayed(const Duration(milliseconds: 10));
    if(lines.length < 3){
      final LogEntry entry = LogEntry.error("File ${file.absolute.path} has less than 3 lines, cant have meaningful data, skipping file");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
      }
    }
    else{
      late final int indicationStep;
      if(doIndication){
        indicationStep = lines.length ~/ indicationCount;
      }
      List<String> signals = lines[0].trim().split(',');
      List<String> units = lines[1].trim().split(',');
      if(!signals.contains('Time')){
        final LogEntry entry = LogEntry.error("File ${file.absolute.path} does not have 'Time' channel declaration, skipping file");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(0, entry.asString(localLogger.loggerName));
        }
        return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
      }
      int timeIndex = signals.indexOf('Time');
      double? timeToMsMultiplier = timeUnitToMsMultiplier[units[signals.indexOf('Time')]];
      if(timeToMsMultiplier == null){
        final LogEntry entry = LogEntry.error("File ${file.absolute.path} has undefined 'Time' channel unit, skipping file");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(0, entry.asString(localLogger.loggerName));
        }
        return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
      }
      for(int i = 0; i < signals.length; i++){
        if(i != timeIndex){
          storage[signals[i]] = SignalContainer(dbcName: signals[i], values: [], displayName: signals[i], unit: Unit.tryParse(units[i]));
        }
      }
      int lineCnt = 3;
      try{
        for(String line in lines.sublist(2)){
          List<String> tokens = line.trim().split(',');
          if(tokens.length != signals.length){
            final LogEntry entry = LogEntry.warning("File ${file.absolute.path} had less values than signal declarations in line $lineCnt skipping line");
            context.add(entry);
            if(doIndication){
              lineProgressIndication(0, entry.asString(localLogger.loggerName));
            }
            continue;
          }
          int timeStamp = (double.parse(tokens[timeIndex]) * timeToMsMultiplier).toInt();
          for(int i = 0; i < signals.length; i++){
            if(i != timeIndex){
              storage[signals[i]]!.values.add(Measurement(double.parse(tokens[i]), timeStamp));
            }
          }
          lineCnt++;
          if(doIndication && lineCnt % indicationStep == 0){
            lineProgressIndication(lineCnt / lines.length, null);
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      catch (exc){
        final LogEntry entry = LogEntry.error("Double.parse() exception when loading file ${file.absolute.path} on line $lineCnt skipping file");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(1, entry.asString(localLogger.loggerName));
        }
        return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
      }
    }
    final LogEntry entry = LogEntry.info("Successfully loaded csv ${file.absolute.path}");
    context.add(entry);
    if(doIndication){
      lineProgressIndication(1, entry.asString(localLogger.loggerName));
    }
    return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
  }

  static Future<LoadContext> _binaryLoader(File file) async {
    // Map<String, SignalContainer> data = {};
    throw UnimplementedError();
    // ...
    // return data;
  }

  /*static Future<LoadContext> loadCalfile(File file) async {
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
  }*/

  // ignore: non_constant_identifier_names
  /*static Future<LoadContext> _CALLoader(File file) async {
      
  }*/

  // Future<vmi> loadUIfile(File file) async {}
}