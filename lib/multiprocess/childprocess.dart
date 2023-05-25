import 'dart:io';
import 'dart:typed_data';

import '../io/logger.dart';
import 'childprocess_api.dart';

class ChildProcess{
  static final ChildProcess _instance = ChildProcess._internal();
  RawDatagramSocket? _sock;

  factory ChildProcess(){
    return _instance;
  }

  ChildProcess._internal(){
    _init();
  }

  void _init() async {
    _sock ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
    _sock!.listen((udp) {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = _sock?.receive()?.data;
        if (udpPayload != null && udpPayload.isNotEmpty) {
          try{
            Command command = Command.decode(udpPayload);
            switch (command.type) {
              case CommandType.DATA:
                // ...
                break;

              case CommandType.KILL:
                // ...
                break;

              case CommandType.HIGHLIGHT_TIMESTAMP:
                // ...
                break;

              default:
                localLogger.error("Childprocess on port ${command.childProcessPort} received an undefined message");
            }
          }
          catch (exc){
            localLogger.error("Undefined message received");
          }
        }
      }
    });
  }

  void signalStop(){
    _sock?.send(Response(localSocketPort, ResponseType.STOPPING, {}).encode(), InternetAddress.loopbackIPv4, masterSocketPort);
    _sock?.close();
  }
}