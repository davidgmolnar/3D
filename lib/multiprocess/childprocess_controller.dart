import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../io/logger.dart';
import '../routes/window_type.dart';
import 'childprocess_api.dart';

const int resendIntervalMS = 200;
const int maxSendAttempt = 10;

class ChildProcessController{
  static final ChildProcessController _instance = ChildProcessController._internal();
  final Map<int,WindowType> _activeChildProcesses = {};
  final Map<int,WindowType> _newConnections = {};
  RawDatagramSocket? _sock;
  final Map<Command,int> _backlog = {};
  Timer? _dispatcher;

  factory ChildProcessController(){
    return _instance;
  }

  ChildProcessController._internal();

  void start() async {
    await _init();
  }

  Future<void> _init() async {
    _sock ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
    _sock!.listen((udp) {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = _sock?.receive()?.data;
        if (udpPayload != null && udpPayload.isNotEmpty) {
          try{
            Response response = Response.decode(udpPayload);
            switch (response.type) {
              case ResponseType.INIT_READY:
                if(_newConnections.containsKey(response.childProcessPort)){
                  _activeChildProcesses[response.childProcessPort] = _newConnections[response.childProcessPort]!;
                  _newConnections.removeWhere((key, value) => key == response.childProcessPort);
                }
                else{
                  localLogger.error("Childprocess on port ${response.childProcessPort} unexpectedly reported INIT_READY");
                }
                break;

              case ResponseType.DATA:
                // ...
                break;

              case ResponseType.STOPPING:
                if(_activeChildProcesses.containsKey(response.childProcessPort)){
                  _activeChildProcesses.removeWhere((key, value) => key == response.childProcessPort);
                }
                else if(_newConnections.containsKey(response.childProcessPort)){
                  _newConnections.removeWhere((key, value) => key == response.childProcessPort);
                }
                else{
                  localLogger.error("Childprocess on port ${response.childProcessPort} reported STOPPING, but this childprocess was not managed by master");
                }
                break;

              default:
                localLogger.error("Childprocess on port ${response.childProcessPort} sent an undefined message");
            }
          }
          catch (exc){
            localLogger.error("Undefined message received");
          }
        }
      }
    });
  }

  int _findFirstAvailablePort(){
    int port = masterSocketPort + 1;
    while(_activeChildProcesses.containsKey(port)){
      port++;
    }
    return port;
  }

  int addConnection(WindowType type){
    int port = _activeChildProcesses.isEmpty ? localSocketPort + 1 : _findFirstAvailablePort();
    // Process run
    _newConnections[port] = type;
    localLogger.info("Started ${type.name}");
    return port;
  }

  void sendTo(Command command){
    if(_activeChildProcesses.containsKey(command.childProcessPort)){
      _sock?.send(command.encode(), InternetAddress.loopbackIPv4, command.childProcessPort);
    }
    else if(_newConnections.containsKey(command.childProcessPort)){
      _backlog[command] = 0;
      _dispatcher ??= Timer.periodic(const Duration(milliseconds: resendIntervalMS), ((timer) {
        _flush();
      }));
    }
    else{
      localLogger.error("Message was attempted to be sent to a port not managed by master");
    }
  }

  void _flush(){
    if(_backlog.isNotEmpty){
      for(Command command in _backlog.keys){
        if(_activeChildProcesses.containsKey(command.childProcessPort)){
          _sock?.send(command.encode(), InternetAddress.loopbackIPv4, command.childProcessPort);
          _backlog.remove(command);
        }
        else{
          _backlog[command] = _backlog[command]! + 1;
        }
        if(_backlog[command]! >= 10){
          _backlog.remove(command);
        }
      }
    }
    else{
      if(_dispatcher != null && _dispatcher!.isActive){
        _dispatcher?.cancel();
        _dispatcher = null;
      }
    }
  }

  void dispose(){
    if(_dispatcher != null && _dispatcher!.isActive){
        _dispatcher?.cancel();
        _dispatcher = null;
    }
    for(int childProcessPort in _activeChildProcesses.keys){
      _sock?.send(Command(childProcessPort, CommandType.KILL, {}).encode(), InternetAddress.loopbackIPv4, childProcessPort);
      _activeChildProcesses.remove(childProcessPort);
    }
    for(int childProcessPort in _newConnections.keys){
      _sock?.send(Command(childProcessPort, CommandType.KILL, {}).encode(), InternetAddress.loopbackIPv4, childProcessPort);
      _newConnections.remove(childProcessPort);
    }
    _sock?.close();
  }
}