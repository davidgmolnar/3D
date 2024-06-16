import 'dart:typed_data';

import '../io/exporter.dart';
import '../io/importer.dart';

const int masterSocketPort = 9999;
int localSocketPort = masterSocketPort;

enum CommandType{
  // ignore: constant_identifier_names
  WINDOW_SETUP,
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  PERIODIC_UPDATE,
  // ignore: constant_identifier_names
  UPDATE_SETTINGS,
  // ignore: constant_identifier_names
  KILL
}

enum PeriodicUpdateType{
  // ignore: constant_identifier_names
  IO_LINE_PERCENTAGE,
  // ignore: constant_identifier_names
  ERROR,
  // ignore: constant_identifier_names
  HIGHLIGHT_TIMESTAMP,
}

// MainWindow -> SubWindow
class Command{
  final int childProcessPort;
  final CommandType type;
  final Map data;

  Command(this.childProcessPort, this.type, this.data);

  static Command decode(Uint8List payload){
    final Map decoded = Importer.jsonFromBytes(payload);
    return Command(decoded["port"], CommandType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Exporter.jsonToBytes(payload);
  }
}

enum ResponseType{
  // ignore: constant_identifier_names
  INIT_READY,
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  CUSTOM_CHART_FORWARD,
  // ignore: constant_identifier_names
  UPDATE_SETTINGS,
  // ignore: constant_identifier_names
  FINISHED,
  // ignore: constant_identifier_names
  STOPPING
}

enum ResponseFinishableType{
  // ignore: constant_identifier_names
  IMPORT_LOG,
    // ignore: constant_identifier_names
  RUN_CAL,
    // ignore: constant_identifier_names
  IMPORT_UI,
  // ignore: constant_identifier_names
  EXPORT,
  // ignore: constant_identifier_names
  SETTING,
  // ignore: constant_identifier_names
  TRACE_EDITOR_DATA,
}

class ResponseFinishable{
  final ResponseFinishableType type;
  final Map data;

  ResponseFinishable(this.type, this.data);

  static ResponseFinishable? fromJson(final Map json){
    if(!json.containsKey('type') || json['type'] is! int){
      return null;
    }
    else if(!json.containsKey('data') || json['data'] is! Map){
      return null;
    }
    else{
      return ResponseFinishable(ResponseFinishableType.values[json['type']], json['data']);
    }
  }

  Map get asJson => {
    "type": type.index,
    "data": data
  };
}

enum ChildRequestType{
  // ignore: constant_identifier_names
  STATISTICS_MEAS_REQ,
}

class ChildRequest{
  final ChildRequestType type;
  final Map context;

  ChildRequest({required this.type, required this.context});

  static fromJson(final Map json){
    if(!json.containsKey('type') || json['type'] is! int){
      return null;
    }
    else if(!json.containsKey('context') || json['context'] is! Map){
      return null;
    }
    else{
      return ChildRequest(type: ChildRequestType.values[json['type']], context: json['context']);
    }
  }

  Map get asJson => {
    "type": type.index,
    "context": context
  };
}

// SubWindow -> MainWindow
class Response{
  final int childProcessPort;
  final ResponseType type;
  final Map data;

  Response(this.childProcessPort, this.type, this.data);

  static Response decode(Uint8List payload){
    final Map decoded = Importer.jsonFromBytes(payload);
    return Response(decoded["port"], ResponseType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Exporter.jsonToBytes(payload);
  }
}