import '../../../data/settings.dart';
import '../../../io/logger.dart';
import '../../../ui/theme/theme.dart';

enum SettingsWindowType{
  // ignore: constant_identifier_names
  INITIAL,
  // ignore: constant_identifier_names
  SETTINGS,
  // ignore: constant_identifier_names
  TRACE_EDITOR,
  // ignore: constant_identifier_names
  CALCULATION_TESTER,
}

Map setSettingsWindowTypePayload(SettingsWindowType type) => {
  'instruction': SettingsWindowInstruction.SET_TYPE.index,
  'type': type.index
};

Map setSettingsTraceEditorSetupPayload(Map data) => {
  'instruction': SettingsWindowInstruction.TRACE_EDITOR_DATA.index,
  'trace_editor_data': data
};

enum SettingsWindowInstruction{
  // ignore: constant_identifier_names
  SET_TYPE,
  // ignore: constant_identifier_names
  TRACE_EDITOR_DATA
}

SettingsWindowType settingsWindowType = SettingsWindowType.INITIAL;

void settingsHandleDataReceived(Map data){
  localLogger.info("Data received from master", doNoti: false);
  switch (SettingsWindowInstruction.values[data['instruction']]) {
    case SettingsWindowInstruction.SET_TYPE:
      settingsWindowType = SettingsWindowType.values[data['type']];
      localLogger.info("SettingsWindowType changed to ${settingsWindowType.name}", doNoti: false);
      StyleManager.updater();
      break;
    case SettingsWindowInstruction.TRACE_EDITOR_DATA:
      if(data['trace_editor_data']! is Map){
        localLogger.info("Starting to import trace editor data", doNoti: false);
        TraceSettingsProvider.reload(data['trace_editor_data']!);
        localLogger.info("Successfully imported trace editor data", doNoti: false);
        StyleManager.updater();
      }
      else{
        localLogger.error("Unable to interpret payload message received as SettingsWindowInstruction.TRACE_EDITOR_DATA", doNoti: false);
      }
      break;
    default:
      localLogger.error("SettingsWindowInstruction not implemented for SettingsWindowInstruction.${SettingsWindowInstruction.values[data['instruction']].name}", doNoti: false);
  }
}