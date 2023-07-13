import '../../../io/logger.dart';
import '../../../ui/theme/theme.dart';

enum LogWindowType{
  // ignore: constant_identifier_names
  INITIAL,
  // ignore: constant_identifier_names
  DISPLAY,
  // ignore: constant_identifier_names
  IMPORT,
  // ignore: constant_identifier_names
  EXPORT,
  // ignore: constant_identifier_names
  CALCULATION,
}

Map setLogWindowTypePayload(LogWindowType type) => {
  'instruction': LogWindowInstruction.SET_TYPE.index,
  'type': type.index
};

enum LogWindowInstruction{
  // ignore: constant_identifier_names
  SET_TYPE,
}

LogWindowType logWindowType = LogWindowType.INITIAL;

void logHandleDataReceived(Map data){
  localLogger.info("Data received from master");
  switch (LogWindowInstruction.values[data['instruction']]) {
    case LogWindowInstruction.SET_TYPE:
      logWindowType = LogWindowType.values[data['type']];
      localLogger.info("LogWindowType changed to ${logWindowType.name}");
      StyleManager.updater();
      break;
    default:
      localLogger.error("LogWindowInstruction not implemented for LogWindowInstruction.${LogWindowInstruction.values[data['instruction']].name}");
  }
}