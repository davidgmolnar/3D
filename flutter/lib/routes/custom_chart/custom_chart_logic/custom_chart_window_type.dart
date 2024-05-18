import '../../../data/data.dart';
import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../io/logger.dart';
import '../../../ui/charts/chart_logic/chart_controller.dart';
import '../../../ui/theme/theme.dart';
import 'custom_descriptor.dart';
import 'custom_group.dart';

enum CustomChartWindowType{
  // ignore: constant_identifier_names
  INITIAL,
  // ignore: constant_identifier_names
  ERROR,
  // ignore: constant_identifier_names
  GRID,
  // ignore: constant_identifier_names
  CHARACTERISTICS,
  // ignore: constant_identifier_names
  HISTOGRAM,
}

Map setCustomChartWindowTypePayload(CustomChartWindowType type) => {
  'instruction': CustomChartWindowInstruction.SET_TYPE.index,
  'type': type.index
};

Map setCustomChartDescriptorPayload(final String filename, final int index) => {
  'instruction': CustomChartWindowInstruction.DESCRIPTOR_FILE.index,
  'filename': filename,
  'index': index
};

enum CustomChartWindowInstruction{
  // ignore: constant_identifier_names
  SET_TYPE,
  // ignore: constant_identifier_names
  DESCRIPTOR_FILE
}

CustomChartWindowType customChartWindowType = CustomChartWindowType.INITIAL;
CustomTimeseriesChartGroup? customTimeseriesChartGroup;
int? customTimeseriesChartGroupIndex;

void customChartHandleDataReceived(Map data) async {
  localLogger.info("Data received from master");
  switch (CustomChartWindowInstruction.values[data['instruction']]) {
    case CustomChartWindowInstruction.SET_TYPE:
      customChartWindowType = CustomChartWindowType.values[data['type']];
      localLogger.info("CustomChartWindowType changed to ${customChartWindowType.name}");
      StyleManager.updater();
      break;

    case CustomChartWindowInstruction.DESCRIPTOR_FILE:
      if(customChartWindowType == CustomChartWindowType.GRID){
        customTimeseriesChartGroup = await CustomTimeseriesChartGroup.load(data["filename"]);
        customTimeseriesChartGroupIndex = data["index"];

        if(customTimeseriesChartGroup == null || customTimeseriesChartGroupIndex == null){
          localLogger.error("Failed to load descriptor data");
          customChartWindowType = CustomChartWindowType.ERROR;
          StyleManager.updater();
        }
        else{
          localLogger.info("Loaded descriptor file for ${customTimeseriesChartGroup!.name}");
          CustomTimeseriesChartDescriptor desc = customTimeseriesChartGroup!.elements[customTimeseriesChartGroupIndex!];
          signalData[desc.measurement] = {};
          desc.loadChannels();
          
          TraceSettingsProvider.updateEntriesFrom(desc.measurement, desc.signals);
          for(final TraceSetting element in TraceSettingsProvider.traceSettingNotifier.value[desc.measurement]!){
            element.isVisible = true;
          }
          TraceSettingsProvider.reCalculateVisibleDuration();
          ChartController.shownDurationNotifier.update((value) {
            value.timeOffset = TraceSettingsProvider.firstVisibleTimestamp;
          });
          TraceSettingsProvider.traceSettingNotifier.update((value) { });
        }
      }
      else{
        localLogger.error("Loading descriptor file is not implemented for ${customChartWindowType.name}");
      }
      break;

    default:
      localLogger.error("CustomChartWindowInstruction not implemented for CustomChartWindowInstruction.${CustomChartWindowInstruction.values[data['instruction']].name}");
  }
}