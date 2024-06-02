import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_dbc_parser/dart_dbc_parser.dart';
import 'package:dart_dbc_parser/signal/dbc_signal.dart';

import '../data/calculation/unit.dart';
import '../data/settings.dart';
import '../data/signal_container.dart';
import '../data/typed_data_list_container.dart';
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

abstract class Importer {

  static Utf8Decoder utf8Decoder = const Utf8Decoder();

  static JsonDecoder jsonDecoder = const JsonDecoder();

  static Map jsonFromBytes(List<int> bytes) => jsonDecoder.convert(safeUTF8Decode(bytes));

  static Map<String, double> timeUnitToMsMultiplier = {
    "min": 60*1000,
    "s": 1000,
    "ms": 1,
    "us": 0.001
  };

  static String safeUTF8Decode(final List<int> bytes) => utf8Decoder.convert(bytes);
  
  static Future<LoadContext> loadLogFile(final File file, {final Function(double, String?)? lineProgressIndication, final int? indicationCount}) async {
    try{
      String extension = file.path.split('.').last;
      if(await file.exists()){
        switch (extension.toLowerCase()) {
          case "csv":
            return await _csvLoader(file, lineProgressIndication: lineProgressIndication, indicationCount: indicationCount);
          case "bin":
            return await _binaryLoader(file, lineProgressIndication: lineProgressIndication, indicationCount: indicationCount);
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

  static Future<LoadContext> _csvLoader(final File file, {final Function(double, String?)? lineProgressIndication, final int? indicationCount}) async {
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
        return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
      }
      int timeIndex = signals.indexOf('Time');
      double? timeToMsMultiplier = timeUnitToMsMultiplier[units[signals.indexOf('Time')]];
      if(timeToMsMultiplier == null){
        final LogEntry entry = LogEntry.error("File ${file.absolute.path} has undefined 'Time' channel unit, skipping file");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(0, entry.asString(localLogger.loggerName));
        }
        return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
      }

      bool dbcFail = false;
      final List<String>? dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
      if(dbcPaths == null || dbcPaths.isEmpty){
        dbcFail = true;
        final LogEntry entry = LogEntry.warning("DBC database was not set, cant efficiently store measurement");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(0, entry.asString(localLogger.loggerName));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
      }

      late final DBCDatabase can;
      if(!dbcFail){
        can = await DBCDatabase.loadFromFile(dbcPaths.map((e) => File(e)).toList());
        if(can.database.isEmpty){
          dbcFail = true;
          final LogEntry entry = LogEntry.warning("Failed to load DBC database, cant efficiently store measurement");
          context.add(entry);
          if(doIndication){
            lineProgressIndication(0, entry.asString(localLogger.loggerName));
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      if(!dbcFail){
        final LogEntry entry = LogEntry.info("Successfully loaded DBC database from files $dbcPaths");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(0, entry.asString(localLogger.loggerName));
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      for(int i = 0; i < signals.length; i++){
        if(i != timeIndex){
          DBCSignal? signal;
          for(final Map<String, DBCSignal> msg in can.database.values){
            if(msg.keys.contains(signals[i])){
              signal = msg[signals[i]];
              break;
            }
          }
          if(dbcFail || signal == null){
            final LogEntry entry = LogEntry.warning("Failed to find signal ${signals[i]} in DBC database, cant efficiently store channel, falling back to float32");
            context.add(entry);
            if(doIndication){
              lineProgressIndication(0, entry.asString(localLogger.loggerName));
              await Future.delayed(const Duration(milliseconds: 10));
            }
            storage[signals[i]] = SignalContainer(dbcName: signals[i], values: TypedDataListContainer<Float32List>(list: Float32List(0)), timestamps: TypedDataListContainer<Uint32List>(list: Uint32List(0)), displayName: signals[i], unit: Unit.tryParse(units[i]));
          }
          else{
            storage[signals[i]] = SignalContainer(dbcName: signals[i], values: TypedDataListContainer.emptyFromDBC(signal), timestamps: TypedDataListContainer<Uint32List>(list: Uint32List(0)), displayName: signals[i], unit: Unit.tryParse(units[i]));
          }
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
              storage[signals[i]]!.values.pushBack(double.parse(tokens[i]));
              storage[signals[i]]!.timestamps.pushBack(timeStamp);
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

    {
      final LogEntry entry = LogEntry.info("Finishing up ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(1, entry.asString(localLogger.loggerName));
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    for(final String name in storage.keys){
      storage[name]!.values.shrinkToFit();
      storage[name]!.timestamps.shrinkToFit();
    }

    final LogEntry entry = LogEntry.info("Successfully loaded csv ${file.absolute.path}");
    context.add(entry);
    if(doIndication){
      lineProgressIndication(1, entry.asString(localLogger.loggerName));
    }
    return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
  }

  static Future<LoadContext> _binaryLoader(final File file, {final Function(double, String?)? lineProgressIndication, final int? indicationCount}) async {
    Map<String, SignalContainer> storage = {};
    List<LogEntry> context = [];

    final bool doIndication = lineProgressIndication != null && indicationCount != null;
    {
      final LogEntry entry = LogEntry.info("Started loading bin ${file.absolute.path}");
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
    Uint8List bytes = await file.readAsBytes();
    {
      final LogEntry entry = LogEntry.info("File read ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
      }
    }

    // ignore: constant_identifier_names
    const int PACKET_LEN_3D_FORMAT = 14;
    // ignore: constant_identifier_names
    const int CAN_LEN_3D_FORMAT = 10;
    late final int indicationStep;
    if(doIndication){
      indicationStep = (bytes.length ~/ PACKET_LEN_3D_FORMAT) ~/ indicationCount;
    }

    final List<String>? dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
    if(dbcPaths == null || dbcPaths.isEmpty){
      final LogEntry entry = LogEntry.error("DBC database was not set, cant decode binary log, skipping file");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(1, entry.asString(localLogger.loggerName));
      }
      return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
    }

    final DBCDatabase can = await DBCDatabase.loadFromFile(dbcPaths.map((e) => File(e)).toList());
    if(can.database.isEmpty){
      final LogEntry entry = LogEntry.error("Failed to load DBC database, cant decode binary log, skipping file");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(1, entry.asString(localLogger.loggerName));
      }
      return LoadContext(storage: {}, context: context, filePath: file.absolute.path);
    }
    {
      final LogEntry entry = LogEntry.info("Successfully loaded DBC database from files $dbcPaths");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString(localLogger.loggerName));
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    Set<int> unknownCANIDs = {};
    int prevTimeStamp = 0;
    int timeStampOffset = 0;
    int packetCnt = 0;
    for(int i = 0; i < bytes.length; i += PACKET_LEN_3D_FORMAT){
      if(doIndication && packetCnt % indicationStep == 0){
        lineProgressIndication(i / bytes.length, null);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      packetCnt++;
      final int canID = bytes.sublist(i, i + 2).buffer.asByteData().getUint16(0);
      if(!can.database.containsKey(canID)){
        if(!unknownCANIDs.contains(canID)){
          final LogEntry entry = LogEntry.warning("Unknown CANID $canID at pos $i skipping packet");
          context.add(entry);
          if(doIndication){
            lineProgressIndication(i / bytes.length, entry.asString(localLogger.loggerName));
            await Future.delayed(const Duration(milliseconds: 10));
          }
          unknownCANIDs.add(canID);
        }
        continue;
      }
      final int timeStampMS = bytes.sublist(i + CAN_LEN_3D_FORMAT, i + PACKET_LEN_3D_FORMAT).buffer.asByteData().getUint32(0);
      if(timeStampMS < prevTimeStamp){
        final LogEntry entry = LogEntry.warning("Packet at pos $i had ${prevTimeStamp - timeStampMS} ms earlier timestamp than the previous one, adjusting time to be continuous");
        context.add(entry);
        /*if(doIndication){
          lineProgressIndication(i / bytes.length, entry.asString(localLogger.loggerName));
          await Future.delayed(const Duration(milliseconds: 10));
        }*/
        timeStampOffset += timeStampMS - prevTimeStamp;
      }
      prevTimeStamp = timeStampMS;

      final Map<String, num> newSignalValues = can.decode(bytes.sublist(i, i + CAN_LEN_3D_FORMAT));
      for(final String signal in newSignalValues.keys){
        if(!storage.containsKey(signal)){
          late final DBCSignal dbcSignal;
          for(final Map<String, DBCSignal> msg in can.database.values){
            if(msg.keys.contains(signal)){
              dbcSignal = msg[signal]!;
              break;
            }
          }
          storage[signal] = SignalContainer(dbcName: signal, values: TypedDataListContainer.emptyFromDBC(dbcSignal), timestamps: TypedDataListContainer<Uint32List>(list: Uint32List(0)), displayName: signal, unit: Unit.tryParse(can.database[canID]![signal]!.unit));
        }

        if(storage[signal]!.values.size > 1 && newSignalValues[signal]! == storage[signal]!.values.last && storage[signal]!.values.last == storage[signal]!.values[storage[signal]!.values.size - 2]){
          storage[signal]!.values.last = newSignalValues[signal]!;
          storage[signal]!.timestamps.last = timeStampMS - timeStampOffset;
        }
        else{
          storage[signal]!.values.pushBack(newSignalValues[signal]!);
          storage[signal]!.timestamps.pushBack(timeStampMS - timeStampOffset);
        }
      }
    }

    {
      final LogEntry entry = LogEntry.info("Finishing up ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(1, entry.asString(localLogger.loggerName));
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    for(final String name in storage.keys){
      storage[name]!.values.shrinkToFit();
      storage[name]!.timestamps.shrinkToFit();
    }
    
    final LogEntry entry = LogEntry.info("Successfully loaded binary ${file.absolute.path}");
    context.add(entry);
    if(doIndication){
      lineProgressIndication(1, entry.asString(localLogger.loggerName));
    }
    return LoadContext(storage: storage, context: context, filePath: file.absolute.path);
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