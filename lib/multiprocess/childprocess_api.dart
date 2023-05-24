import 'dart:convert';
import 'dart:typed_data';

import '../io/deserializer.dart';
import '../io/serializer.dart';

const int masterSocketPort = 9999;
int localSocketPort = masterSocketPort;

enum CommandType{
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  HIGHLIGHT_TIMESTAMP,
  // ignore: constant_identifier_names
  KILL
}

class Command{
  final int childProcessPort;
  final CommandType type;
  final Map data;

  Command(this.childProcessPort, this.type, this.data);

  static Command decode(Uint8List payload){
    final Map<String,dynamic> decoded = jsonDecode(Serializer.safeUTF8Decode(payload));
    return Command(decoded["port"], CommandType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Deserializer.utf8Decoder.convert(jsonEncode(payload));
  }
}

enum ResponseType{
  // ignore: constant_identifier_names
  INIT_READY,
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  STOPPING
}

class Response{
  final int childProcessPort;
  final ResponseType type;
  final Map data;

  Response(this.childProcessPort, this.type, this.data);

  static Response decode(Uint8List payload){
    final Map<String,dynamic> decoded = jsonDecode(Serializer.safeUTF8Decode(payload));
    return Response(decoded["port"], ResponseType.values[decoded["type"]], decoded["data"]);
  }

  Uint8List encode(){
    final Map<String,dynamic> payload = {
      "port": childProcessPort,
      "type": type.index,
      "data": data
    };
    return Deserializer.utf8Decoder.convert(jsonEncode(payload));
  }
}