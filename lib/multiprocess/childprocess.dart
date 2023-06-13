import 'dart:io';
import 'dart:typed_data';

import '../io/logger.dart';
import '../routes/log/log_logic/log_window_action_type.dart';
import '../routes/window_type.dart';
import 'childprocess_api.dart';

// DONT inherit/extend
abstract class ChildProcess{
  static RawDatagramSocket? _sock;

  static Future<void> start() async {
    _sock ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
    _sock!.broadcastEnabled = true;
    _init();
  }

  static void _init() {
    _sock!.listen((udp) async {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = _sock?.receive()?.data;
        if (udpPayload != null && udpPayload.isNotEmpty) {
          try{
            Command command = Command.decode(udpPayload);
            switch (command.type) {
              case CommandType.DATA:
                _handleData(command.data);
                break;

              case CommandType.KILL:
                localLogger.info("Controller killed this childprocess, stopping");
                await localLogger.stop();
                exit(0);
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

  static void _handleData(Map data){
    switch (windowType) {
      case WindowType.LOG:
        logHandleDataReceived(data);
        break;
      default:
        localLogger.error("Data interpretation not implemented");
    }
  }

  static void send(Response response){
    _sock?.send(response.encode(), InternetAddress.loopbackIPv4, masterSocketPort);
  }

  static void signalReady(){
    _sock?.send(Response(localSocketPort, ResponseType.INIT_READY, {}).encode(), InternetAddress.loopbackIPv4, masterSocketPort);
  }

  static void signalStop(){
    _sock?.send(Response(localSocketPort, ResponseType.STOPPING, {}).encode(), InternetAddress.loopbackIPv4, masterSocketPort);
    _sock?.close();
  }

  static void stopWithoutSignaling(){
    _sock?.close();
  }
}