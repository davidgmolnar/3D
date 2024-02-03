import 'dart:io';
import 'dart:typed_data';

import '../data/settings.dart';
import '../io/logger.dart';
import '../routes/log/log_logic/log_window_action_type.dart';
import '../routes/settings/settings_logic/settings_window_type.dart';
import '../routes/window_type.dart';
import 'childprocess_api.dart';
import 'protocol.dart';

// DONT inherit/extend
abstract class ChildProcess{
  static RawDatagramSocket? _sock;

  static final Uint8List _stopSignal = Protocol.encode(Response(localSocketPort, ResponseType.STOPPING, {}).encode()).first;
  static final Uint8List _readySignal = Protocol.encode(Response(localSocketPort, ResponseType.INIT_READY, {}).encode()).first;
  static final Uint8List _settingsUpdateSignal = Protocol.encode(Response(localSocketPort, ResponseType.UPDATE_SETTINGS, {}).encode()).first;

  static Future<void> start() async {
    _sock ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
    _sock!.broadcastEnabled = true;
    _init();
  }

  static void _init() {
    localLogger.info("ChildProcess started listening");
    _sock!.listen((udp) async {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = Protocol.decode(_sock?.receive()?.data);
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

              case CommandType.PERIODIC_UPDATE:
                _handlePeriodicUpdate(command.data);
                break;

              case CommandType.UPDATE_SETTINGS:
                SettingsProvider.loadFromDisk();
                break;

              default:
                localLogger.error("Childprocess on port ${command.childProcessPort} received an undefined message");
            }
          }
          catch (exc){
            localLogger.error("Undefined message received ${exc.toString()}");
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
      case WindowType.SETTINGS:
        settingsHandleDataReceived(data);
        break;
      default:
        localLogger.error("Data interpretation not implemented for WindowType.${windowType.name}");
    }
  }

  static void _handlePeriodicUpdate(Map data){
    switch (windowType) {
      case WindowType.LOG:
        logHandlePeriodicUpdateReceived(data);
        break;
      default:
        localLogger.error("Periodic update interpretation not implemented for WindowType.${windowType.name}");
    }
  }

  static void send(Response response) async {
    for(Uint8List fragment in Protocol.encode(response.encode())){
      await Future.delayed(const Duration(milliseconds: 10));
      _sock?.send(fragment, InternetAddress.loopbackIPv4, masterSocketPort);
    }
  }

  static void triggerSettingsUpdateInMaster(){
    _sock?.send(_settingsUpdateSignal, InternetAddress.loopbackIPv4, masterSocketPort);
  }

  static void signalReady(){
    _sock?.send(_readySignal, InternetAddress.loopbackIPv4, masterSocketPort);
  }

  static void signalStop(){
    _sock?.send(_stopSignal, InternetAddress.loopbackIPv4, masterSocketPort);
    _sock?.close();
  }

  static void stopWithoutSignaling(){
    _sock?.close();
  }
}