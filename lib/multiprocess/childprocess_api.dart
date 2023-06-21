import 'dart:convert';
import 'dart:typed_data';

import '../io/deserializer.dart';
import '../io/serializer.dart';

const int masterSocketPort = 9999;
int localSocketPort = masterSocketPort;

enum CommandType{
  // ignore: constant_identifier_names
  WINDOW_SETUP,
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  HIGHLIGHT_TIMESTAMP,
  // ignore: constant_identifier_names
  KILL
}

// MainWindow -> SubWindow
class Command{
  final int childProcessPort;
  final CommandType type;
  final Map data;

  Command(this.childProcessPort, this.type, this.data);

  static Command decode(Uint8List payload){
    final Map decoded = Serializer.jsonFromBytes(payload);
    return Command(decoded["port"], CommandType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Deserializer.jsonToBytes(payload);
  }
}

enum ResponseType{
  // ignore: constant_identifier_names
  INIT_READY,
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  FINISHED,
  // ignore: constant_identifier_names
  STOPPING
}

enum ResponseFinishableType{
  // ignore: constant_identifier_names
  IMPORT_LOG,
    // ignore: constant_identifier_names
  IMPORT_CAL,
    // ignore: constant_identifier_names
  IMPORT_UI,
  // ignore: constant_identifier_names
  EXPORT,
  // ignore: constant_identifier_names
  SETTING,
  // ignore: constant_identifier_names
  CALCULATION
}

class ResponseFinishable{
  final ResponseFinishableType type;
  final Map data;

  ResponseFinishable(this.type, this.data);

  static ResponseFinishable? fromJson(Map json){
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

// SubWindow -> MainWindow
class Response{
  final int childProcessPort;
  final ResponseType type;
  final Map data;

  Response(this.childProcessPort, this.type, this.data);

  static Response decode(Uint8List payload){
    final Map decoded = Serializer.jsonFromBytes(payload);
    return Response(decoded["port"], ResponseType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Deserializer.jsonToBytes(payload);
  }
}