import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../data/calculation/calculation_script_execution.dart';
import '../data/calculation/calculation_script_runtime.dart';
import '../data/data.dart';
import '../data/settings.dart';
import '../data/signal_container.dart';
import '../io/file_system.dart';
import '../io/fscache.dart';
import '../io/logger.dart';
import '../io/importer.dart';
import '../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../routes/custom_chart/custom_chart_logic/statistics_view_logic.dart';
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
    localLogger.info("ChildProcessController started listening", doNoti: false);
    _sock!.listen((udp) async {
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
                  localLogger.info("Established connection with childprocess on port ${response.childProcessPort}", doNoti: false);
                }
                else{
                  localLogger.error("A process on port ${response.childProcessPort} unexpectedly reported INIT_READY", doNoti: false);
                }
                break;

              case ResponseType.DATA:
                _handleData(response.data, response.childProcessPort);
                break;

              case ResponseType.FINISHED:
                _handleFinished(response.childProcessPort, response.data);
                break;

              case ResponseType.CUSTOM_CHART_FORWARD:
                _sendToCustomChartsExcept(response.data, response.childProcessPort);
                break;

              case ResponseType.UPDATE_SETTINGS:
                SettingsProvider.loadFromDisk();
                for(final int port in _activeChildProcesses.keys){
                  if(port == response.childProcessPort){
                    continue;
                  }
                  final Command command = Command(port, CommandType.UPDATE_SETTINGS, {});
                  sendTo(command);
                  await Future.delayed(const Duration(milliseconds: 10));
                }
                break;

              case ResponseType.STOPPING:
                if(_activeChildProcesses.containsKey(response.childProcessPort)){
                  _activeChildProcesses.removeWhere((key, value) => key == response.childProcessPort);
                  localLogger.info("Childprocess on port ${response.childProcessPort} reported STOPPING", doNoti: false);
                  _sock?.send(_killSignal, InternetAddress.loopbackIPv4, response.childProcessPort);
                }
                else if(_newConnections.containsKey(response.childProcessPort)){
                  _newConnections.removeWhere((key, value) => key == response.childProcessPort);
                  localLogger.info("Childprocess on port ${response.childProcessPort} reported STOPPING", doNoti: false);
                  _sock?.send(_killSignal, InternetAddress.loopbackIPv4, response.childProcessPort);
                }
                else{
                  localLogger.error("Childprocess on port ${response.childProcessPort} reported STOPPING, but this childprocess was not managed by master", doNoti: false);
                  _sock?.send(_killSignal, InternetAddress.loopbackIPv4, response.childProcessPort);
                }
                break;

              default:
                localLogger.error("Childprocess on port ${response.childProcessPort} sent an undefined message", doNoti: false);
            }
          }
          catch (exc){
            localLogger.error("Undefined message received ${exc is Error ? exc.stackTrace.toString() : ""} $exc", doNoti: false);
          }
        }
      }
    },
    onError: (err) async {
      localLogger.error("Main socket listener got an error, reinitializing ${err.toString()}");
      _sock!.close();
      _sock = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, localSocketPort);
      _init();
    }
    );
  }

  static void _handleData(final Map data, final int port){
    ChildRequest? request = ChildRequest.fromJson(data);
    if(request == null){
      localLogger.error("Invalid request message was received from $port: $data", doNoti: false);
      return;
    }
    switch (request.type) {
      case ChildRequestType.STATISTICS_MEAS_REQ:
        if(request.context.containsKey("meas") && request.context["meas"] is String && request.context.containsKey("signals") && request.context["signals"] is List){
          StatisticsViewLoadHelper.saveVisible(request.context["meas"], request.context["signals"].cast<String>());
          sendTo(Command(port, CommandType.DATA, setStatisticsReloadPayload(request.context["meas"])));
        }
        else{
          localLogger.error("The STATISTICS_MEAS_REQ request must provide meas in context");
        }
        break;
      default:
    }
  }

  static void _handleFinished(int port, Map data) async {
    ResponseFinishable? finishedTask = ResponseFinishable.fromJson(data);
    if(finishedTask == null){
      localLogger.error("Invalid finish message was received from $port: $data", doNoti: false);
      return;
    }
    switch (finishedTask.type) {
      case ResponseFinishableType.IMPORT_LOG:
        for(String id in finishedTask.data.keys){
          final String measurementAlias = finishedTask.data[id]["alias"].split('.').first;
          try{
            LoadContext result = await Importer.loadLogFile(File(finishedTask.data[id]["path"]),
              lineProgressIndication: (final double linePercentage, final String? entry) {
                sendTo(Command(port, CommandType.PERIODIC_UPDATE, {
                  "type": PeriodicUpdateType.IO_LINE_PERCENTAGE.index,
                  "value": linePercentage,
                  "status": entry ?? 0
                }));
              }, indicationCount: 100
            );
            if(result.storage != null){
              signalData[measurementAlias] = result.storage as Map<String, SignalContainer>;
              TraceSettingsProvider.addEntriesFrom(measurementAlias, signalData[measurementAlias]!.values.toList());
            }
            localLogger.addAll(result.context);
            
          }catch(exc){
            localLogger.error("Error when importing measurement $measurementAlias: ${exc.toString()}");
          }
        }
        FSCache.write<List<String>>(FSCache.importedMeasurementsPath, signalData.keys.toList());
        return; // no kill

      case ResponseFinishableType.TRACE_EDITOR_DATA:
        TraceSettingsProvider.reload(finishedTask.data);
        ChartController.shownDurationNotifier.update((value) {
          value.timeOffset = TraceSettingsProvider.firstVisibleTimestamp;
        });
        break; // kill

      case ResponseFinishableType.RUN_CAL:
        CalculationOptions? options = CalculationOptions.fromJson(finishedTask.data["options"]);
        if(options == null){
          final LogEntry entry = LogEntry.error("Internal error when serializing calculation options: ${finishedTask.data["options"]}");
          sendTo(Command(port, CommandType.PERIODIC_UPDATE, {
            "type": PeriodicUpdateType.IO_LINE_PERCENTAGE.index,
            "value": 0,
            "status": entry.asString("CALCULATION")
          }));
          return;
        }

        for(String path in finishedTask.data["script_paths"]){
          CalculationScriptRuntime.run(File(path), options,
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
        localLogger.error("Finished task ${finishedTask.type.name} handling not implemented", doNoti: false);
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
    final int port = _findFirstAvailablePort();
    String? dir = await FileSystem.getCurrentDirectory;
    if(dir == null){
      return -1;
    }
    await FileSystem.trySaveMapToLocalAsync("", "${port}_setup.3D", windowSetupInfo.asJson);
    Process.run("${dir}log_analyser.exe", [type.name , port.toString(), "${port}_setup.3D"],);
    _newConnections[port] = type;
    localLogger.info("Started ${type.name} on $port", doNoti: false);
    return port;
  }

  static void triggerSettingsUpdateInChildProcesses(){
    for(final int port in _activeChildProcesses.keys){
      final Command command = Command(port, CommandType.UPDATE_SETTINGS, {});
      sendTo(command);
    }
  }

  static void _sendToCustomChartsExcept(final Map payload, final int exceptPort){
    for(final int port in _activeChildProcesses.keys.where((port) => _activeChildProcesses[port]! == WindowType.CUSTOM_CHART && port != exceptPort)){
      final Command command = Command(port, CommandType.DATA, payload);
      sendTo(command);
    }
  }

  static void sendTo(Command command) async {
    if(_activeChildProcesses.containsKey(command.childProcessPort)){
      for(Uint8List fragment in Protocol.encode(command.encode())){
        await Future.delayed(const Duration(milliseconds: 10));
        if(_activeChildProcesses.containsKey(command.childProcessPort)){
          _sock?.send(fragment, InternetAddress.loopbackIPv4, command.childProcessPort);
        }
      }
    }
    else if(_newConnections.containsKey(command.childProcessPort)){
      _backlog[command] = 0;
      _dispatcher ??= Timer.periodic(const Duration(milliseconds: resendIntervalMS), ((timer) {
        _flush();
      }));
    }
    else{
      localLogger.error("Message was attempted to be sent to a port not managed by master", doNoti: false);
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
              if(_activeChildProcesses.containsKey(command.childProcessPort)){
                _sock?.send(fragment, InternetAddress.loopbackIPv4, command.childProcessPort);
              }
            }
            toRemove.add(command);
          }catch(ex){
            _backlog[command] = _backlog[command]! + 1;
            if(_backlog[command]! >= 10){
              toRemove.add(command);
              localLogger.error("Error when attempting to send message to process at port ${command.childProcessPort}", doNoti: false);
            }
          }
        }
        else{
          _backlog[command] = _backlog[command]! + 1;
          if(_backlog[command]! >= 10){
            toRemove.add(command);
            localLogger.error("Message was attempted to be sent to a new connection that failed to signal ready", doNoti: false);
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
    localLogger.info("ChildProcessController started to dispose clients", doNoti: false);
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
    localLogger.info("ChildProcessController finished disposing clients", doNoti: false);
  }
}