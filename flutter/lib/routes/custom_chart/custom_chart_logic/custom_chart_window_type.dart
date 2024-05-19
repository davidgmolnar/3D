import '../../../data/data.dart';
import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../io/logger.dart';
import '../../../ui/charts/chart_logic/chart_controller.dart';
import '../../../ui/charts/cursor_displays.dart';
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

Map setCustomChartShownDurationPayload(final ChartShowDuration showDuration) => {
  'instruction': CustomChartWindowInstruction.SHARING_GROUP_DATA.index,
  'data': {
    'type': SharingGroupEvent.SHOWN_DURATION_CHANGE.index,
    'sharing_group': customTimeseriesChartGroup!.sharingGroup,
    'offset': showDuration.timeOffset,
    'duration': showDuration.timeDuration
  }
};

Map setCustomChartSMarkerAddPayload(final int atTimestamp) => {
  'instruction': CustomChartWindowInstruction.SHARING_GROUP_DATA.index,
  'data': {
    'type': SharingGroupEvent.MARKER_ADD.index,
    'sharing_group': customTimeseriesChartGroup!.sharingGroup,
    'atTimestamp': atTimestamp
  }
};

Map setCustomChartSMarkerRemovePayload(final int cursorIndex) => {
  'instruction': CustomChartWindowInstruction.SHARING_GROUP_DATA.index,
  'data': {
    'type': SharingGroupEvent.MARKER_DELETE.index,
    'sharing_group': customTimeseriesChartGroup!.sharingGroup,
    'cursorIndex': cursorIndex
  }
};

Map setCustomChartSMarkerMovePayload(final int cursorIndex, final int newTimestamp) => {
  'instruction': CustomChartWindowInstruction.SHARING_GROUP_DATA.index,
  'data': {
    'type': SharingGroupEvent.MARKER_MOVE.index,
    'sharing_group': customTimeseriesChartGroup!.sharingGroup,
    'cursorIndex': cursorIndex,
    'newTimestamp': newTimestamp
  }
};

enum CustomChartWindowInstruction{
  // ignore: constant_identifier_names
  SET_TYPE,
  // ignore: constant_identifier_names
  DESCRIPTOR_FILE,
  // ignore: constant_identifier_names
  SHARING_GROUP_DATA
}

enum SharingGroupEvent{
  // ignore: constant_identifier_names
  SHOWN_DURATION_CHANGE,
  // ignore: constant_identifier_names
  MARKER_ADD,
  // ignore: constant_identifier_names
  MARKER_DELETE,
  // ignore: constant_identifier_names
  MARKER_MOVE,
}

CustomChartWindowType customChartWindowType = CustomChartWindowType.INITIAL;
CustomTimeseriesChartGroup? customTimeseriesChartGroup;
int? customTimeseriesChartGroupIndex;
bool isInSharingGroup = true;

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
    case CustomChartWindowInstruction.SHARING_GROUP_DATA:
      _handleSharingGroupData(data["data"]);
      break;

    default:
      localLogger.error("CustomChartWindowInstruction not implemented for CustomChartWindowInstruction.${CustomChartWindowInstruction.values[data['instruction']].name}");
  }
}

void _handleSharingGroupData(Map data){
  if(!isInSharingGroup){
    return;
  }
  if(data['sharing_group'] != customTimeseriesChartGroup?.sharingGroup){
    return;
  }
  switch(SharingGroupEvent.values[data['type']]){
    case SharingGroupEvent.SHOWN_DURATION_CHANGE:
      ChartController.shownDurationNotifier.update((value) {
        value.timeOffset = data['offset'];
        value.timeDuration = data['duration'];
      });
      break;
    case SharingGroupEvent.MARKER_ADD:
      final int timestamp = data['atTimestamp'];
      final Map<String, Map<String, num>> values = cursorDataAtTimeStamp(timestamp, cursorInfoNotifier.value.visibility);
      cursorInfoNotifier.update((cursorInfo) {
        cursorInfo.cursors.add(CursorData.fromCurrent(timestamp, values));
      });
      break;
    case SharingGroupEvent.MARKER_DELETE:
      cursorInfoNotifier.update((cursorInfo) {
        final bool flipOneDelta = cursorInfoNotifier.value.countAbsolutes == 1 && !cursorInfo.cursors[data['cursorIndex']].isDelta && cursorInfo.cursors.length > 1;
        cursorInfo.cursors.removeAt(data['cursorIndex']);
        
        if(flipOneDelta){
          cursorInfo.cursors.firstWhere((cursor) => cursor.isDelta).isDelta = false;
        }
      });
      break;
    case SharingGroupEvent.MARKER_MOVE:
      cursorInfoNotifier.update((cursorInfo) {
        cursorInfo.cursors[data['cursorIndex']].timeStamp = data['newTimestamp'];
        cursorInfo.cursors[data['cursorIndex']].values = cursorDataAtTimeStamp(data['newTimestamp'], cursorInfo.visibility);
      });
      break;
  }
}