import 'dart:async';
import 'dart:io';

const String mainLogPath = "./Logs/3D.log";
Logger localLogger = Logger(mainLogPath, "Initial Logger");

enum LogLevel{
  // ignore: constant_identifier_names
  INFO,
  // ignore: constant_identifier_names
  WARNING,
  // ignore: constant_identifier_names
  ERROR,
  // ignore: constant_identifier_names
  CRITICAL
}

class LogEntry{
  final String message;
  final LogLevel level;
  final DateTime timeStamp;

  LogEntry(this.message, this.level, this.timeStamp);

  static LogEntry info(String message){
    return LogEntry(message, LogLevel.INFO, DateTime.now());
  }

  static LogEntry warning(String message){
    return LogEntry(message, LogLevel.WARNING, DateTime.now());
  }

  static LogEntry error(String message){
    return LogEntry(message, LogLevel.ERROR, DateTime.now());
  }

  static LogEntry critical(String message){
    return LogEntry(message, LogLevel.CRITICAL, DateTime.now());
  }

  String asString(String loggerName) => "[$timeStamp] [$loggerName - ${level.name.toUpperCase()}] $message";
}

class Logger{
  List<LogEntry> _buffer = [];
  bool _isActive = false;
  Timer? timer;
  int loggerFlushIntervalMS = 1000;
  final String logPath;
  final String loggerName;

  Logger(this.logPath, this.loggerName);

  void start(){
    if(_isActive){
      return;
    }
    _isActive = true;
    timer = Timer.periodic(Duration(milliseconds: loggerFlushIntervalMS), ((timer) async {
      await _flush();
    }));
  }

  Future<void> stop() async {
    if(!_isActive){
      return;
    }
    _isActive = false;
    timer?.cancel();
    await _flush();
  }

  void info(String message){
    if(!_isActive){
      return;
    }
    _buffer.add(LogEntry(message, LogLevel.INFO, DateTime.now()));
  }

  void warning(String message){
    if(!_isActive){
      return;
    }
    _buffer.add(LogEntry(message, LogLevel.WARNING, DateTime.now()));
  }

  void error(String message){
    if(!_isActive){
      return;
    }
    _buffer.add(LogEntry(message, LogLevel.ERROR, DateTime.now()));
  }

  void critical(String message){
    if(!_isActive){
      return;
    }
    _buffer.add(LogEntry(message, LogLevel.CRITICAL, DateTime.now()));
  }

  void addAll(List<LogEntry> entries){
    _buffer.addAll(entries);
  }

  void add(LogEntry entry){
    _buffer.add(entry);
  }

  Future<void> _flush() async {
    if(_buffer.isEmpty){
      return;
    }

    File logFile = File(logPath);
    if(!await logFile.exists()){
      await logFile.create(recursive: true);
    }
    RandomAccessFile access = await logFile.open(mode: FileMode.append);
    List<LogEntry> copy = _buffer;
    await access.writeString(contentsToString(copy));
    _buffer = _buffer.skip(copy.length).toList();
    await access.close();
  }

  String contentsToString(List<LogEntry> data){
    String str = "";
    for(LogEntry line in data){
      str = "$str[${line.timeStamp}] [$loggerName - ${line.level.name.toUpperCase()}] ${line.message}\n";
    }
    return str;
  }

  List<String> contentsToStringList(){
    return _buffer.map((entry) => entry.asString(loggerName)).toList();
  }
}