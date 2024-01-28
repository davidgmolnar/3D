import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../data/calibration/calibration_script_execution.dart';
import '../data/calibration/calibration_script_runtime.dart';
import '../data/data.dart';
import '../data/settings.dart';
import '../data/signal_container.dart';
import '../io/file_system.dart';
import '../io/logger.dart';
import '../io/serializer.dart';
import '../routes/startup.dart';
import '../routes/window_type.dart';
import '../ui/charts/chart_logic/chart_controller.dart';
import 'childprocess_api.dart';
import 'protocol.dart';

const int resendIntervalMS = 200;
const int maxSendAttempt = 10;

// DONT inherit/extend
abstract class ChildProcessController{
  static final Map<int,WindowType> _activeChildProcesses = {};
  static final Map<int,WindowType> _newConnections = {};
  static RawDatagramSocket? _sock;
  static final Map<Command,int> _backlog = {};
  static Timer? _dispatcher;

  static final Uint8List _killSignal = Protocol.encode(Command(localSocketPort, CommandType.KILL, {}).encode()).first;

  static Future<void> start() async {
    _sock ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
    _init();
  }

  static void _init() async {
    localLogger.info("ChildProcessController started listening");
    _sock!.listen((udp) {
      if (udp == RawSocketEvent.read) {
        Uint8List? udpPayload = Protocol.decode(_sock?.receive()?.data);
        if (udpPayload != null && udpPayload.isNotEmpty) {
          try{
            Response response = Response.decode(udpPayload);
            switch (response.type) {
              case ResponseType.INIT_READY:
                if(_newConnections.containsKey(response.childProcessPort)){
                  _activeChildProcesses[response.childProcessPort] = _newConnections[response.childProcessPort]!;
                  _newConnections.removeWhere((key, value) => key == response.childProcessPort);
                  localLogger.info("Established connection with childprocess on port ${response.childProcessPort}");
                }
                else{
                  localLogger.error("A process on port ${response.childProcessPort} unexpectedly reported INIT_READY");
                }
                break;

              case ResponseType.DATA:
                // ...
                break;

              case ResponseType.FINISHED:
                _handleFinished(response.childProcessPort, response.data);
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

  static void _handleFinished(int port, Map data) async {
    ResponseFinishable? finishedTask = ResponseFinishable.fromJson(data);
    if(finishedTask == null){
      localLogger.error("Invalid finish message was received from $port: $data");
      return;
    }
    switch (finishedTask.type) {
      case ResponseFinishableType.IMPORT_LOG:
        for(String id in finishedTask.data.keys){
          final String measurementAlias = finishedTask.data[id]["alias"].split('.').first;
          LoadContext result = await Serializer.loadLogFile(File(finishedTask.data[id]["path"]),
            lineProgressIndication: (final double linePercentage, final String? entry) {
              sendTo(Command(port, CommandType.PERIODIC_UPDATE, {
                "type": PeriodicUpdateType.IO_LINE_PERCENTAGE.index,
                "value": linePercentage,
                "status": entry ?? 0
              }));
            }, indicationCount: 100
          );
          signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
          TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
          localLogger.addAll(result.context);
        }
        return; // no kill

      case ResponseFinishableType.TRACE_EDITOR_DATA:
        TraceSettingsProvider.reload(finishedTask.data);
        ChartController.shownDurationNotifier.update((value) {
          value.timeOffset = TraceSettingsProvider.firstVisibleTimestamp;
        });
        break; // kill

      case ResponseFinishableType.RUN_CAL:
        CalibrationOptions? options = CalibrationOptions.fromJson(finishedTask.data["options"]);
        if(options == null){
          final LogEntry entry = LogEntry.error("Internal error when serializing calibration options: ${finishedTask.data["options"]}");
          sendTo(Command(port, CommandType.PERIODIC_UPDATE, {
            "type": PeriodicUpdateType.IO_LINE_PERCENTAGE.index,
            "value": 0,
            "status": entry.asString("CALIBRATION")
          }));
          return;
        }

        for(String path in finishedTask.data["script_paths"]){
          CalibrationScriptRuntime.run(File(path), options,
            progressIndication: (final double linePercentage, final String? entry) {
              sendTo(Command(port, CommandType.PERIODIC_UPDATE, {
                "type": PeriodicUpdateType.IO_LINE_PERCENTAGE.index,
                "value": linePercentage,
                "status": entry ?? 0
              }));
            }, indicationCount: 100
          );
        }
        return; // no kill
        
      default:
        localLogger.error("Finished task ${finishedTask.type.name} handling not implemented");
    }
    sendTo(Command(port, CommandType.KILL, {}));
  }

  static int _findFirstAvailablePort(){
    int port = masterSocketPort + 1;
    while(_activeChildProcesses.containsKey(port) || _newConnections.containsKey(port)){
      port++;
    }
    return port;
  }

  static Future<int> addConnection(WindowType type, WindowSetupInfo windowSetupInfo) async {
    final int port = _activeChildProcesses.isEmpty ? localSocketPort + 1 : _findFirstAvailablePort();
    String? dir = await FileSystem.getCurrentDirectory;
    if(dir == null){
      return -1;
    }
    await FileSystem.trySaveMapToLocalAsync("", "${port}_setup.3D", windowSetupInfo.asJson);
    Process.run("${dir}log_analyser.exe", [type.name , port.toString(), "${port}_setup.3D"],);
    _newConnections[port] = type;
    localLogger.info("Started ${type.name}");
    return port;
  }

  static void sendTo(Command command) async {
    if(_activeChildProcesses.containsKey(command.childProcessPort)){
      for(Uint8List fragment in Protocol.encode(command.encode())){
        await Future.delayed(const Duration(milliseconds: 10));
        _sock?.send(fragment, InternetAddress.loopbackIPv4, command.childProcessPort);
      }
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

  static void _flush() async {
    if(_backlog.isNotEmpty){
      List<Command> toRemove = [];
      for(Command command in _backlog.keys){
        if(_activeChildProcesses.containsKey(command.childProcessPort)){
          try{
            for(Uint8List fragment in Protocol.encode(command.encode())){
              await Future.delayed(const Duration(milliseconds: 10));
              _sock?.send(fragment, InternetAddress.loopbackIPv4, command.childProcessPort);
            }
            toRemove.add(command);
          }catch(ex){
            _backlog[command] = _backlog[command]! + 1;
            if(_backlog[command]! >= 10){
              toRemove.add(command);
              localLogger.error("Error when attempting to send message to process at port ${command.childProcessPort}");
            }
          }
        }
        else{
          _backlog[command] = _backlog[command]! + 1;
          if(_backlog[command]! >= 10){
            toRemove.add(command);
            localLogger.error("Message was attempted to be sent to a new connection that failed to signal ready");
          }
        }
      }
      for(int i = 0; i < toRemove.length; i++) {
        _backlog.remove(toRemove[i]);
      }
    }
    else{
      if(_dispatcher != null && _dispatcher!.isActive){
        _dispatcher?.cancel();
        _dispatcher = null;
      }
    }
  }

  static void dispose(){
    localLogger.info("ChildProcessController started to dispose clients");
    if(_dispatcher != null && _dispatcher!.isActive){
        _dispatcher?.cancel();
        _dispatcher = null;
    }
    for(int childProcessPort in _activeChildProcesses.keys){
      _sock?.send(_killSignal, InternetAddress.loopbackIPv4, childProcessPort);
    }
    _activeChildProcesses.clear();
    for(int childProcessPort in _newConnections.keys){
      _sock?.send(_killSignal, InternetAddress.loopbackIPv4, childProcessPort);
    }
    _newConnections.clear();
    _sock?.close();
    localLogger.info("ChildProcessController finished disposing clients");
  }
}