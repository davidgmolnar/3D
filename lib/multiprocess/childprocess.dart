import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../io/logger.dart';
import '../ui/theme.dart';
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
    _sock!.listen((udp) {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = _sock?.receive()?.data;
        if (udpPayload != null && udpPayload.isNotEmpty) {
          try{
            Command command = Command.decode(udpPayload);
            switch (command.type) {
              case CommandType.WINDOW_SETUP:
                StyleManager.title = command.data["title"];
                appWindow.size = Size(command.data["size_width"], command.data["size_height"]);
                appWindow.position = Offset(command.data["position_dx"], command.data["position_dy"]);
                // appWindow.title = command.data["title"];
                if(StyleManager.updater != null){
                  StyleManager.updater!();
                }
                break;

              case CommandType.DATA:
                // ...
                break;

              case CommandType.KILL:
                localLogger.info("Controller killed this childprocess, stopping");
                localLogger.stop();
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