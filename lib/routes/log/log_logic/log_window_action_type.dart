import '../../../io/logger.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../ui/theme/theme.dart';
import 'calibration_io_controller.dart';
import 'log_io_controller.dart';

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

void logHandlePeriodicUpdateReceived(Map data){
  localLogger.info("Periodic update received from master");
  switch (PeriodicUpdateType.values[data['type']]) {
    case PeriodicUpdateType.IO_LINE_PERCENTAGE:
      try{
        if(logWindowType != LogWindowType.IMPORT && logWindowType != LogWindowType.EXPORT && logWindowType != LogWindowType.CALCULATION){
          localLogger.warning("PeriodicUpdateType.IO_LINE_PERCENTAGE was received but this window was neither a LogWindowType.IMPORT or LogWindowType.EXPORT");
          return;
        }
        final double linePercentage = data['value'].toDouble();
        final dynamic entry = data['status'];
        if(linePercentage != 0){
          if(logWindowType == LogWindowType.CALCULATION){
            CalibrationIoController.setLinePercentage(linePercentage);
          }
          else{
            LogIOInfoController.setLinePercentage(linePercentage);
          }
        }
        if(entry.runtimeType == String){
          if(logWindowType == LogWindowType.CALCULATION){
            CalibrationIoController.addToContext(entry);
          }
          else{
            LogIOInfoController.addToContext(entry);
          }
        }
      }catch(exc){
        localLogger.error("PeriodicUpdateType.IO_LINE_PERCENTAGE exception $exc");
      }
      break;
    default:
      localLogger.error("LogWindowInstruction not implemented for LogWindowInstruction.${LogWindowInstruction.values[data['instruction']].name}");
  }
}