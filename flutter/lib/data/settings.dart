import 'dart:math';

import 'package:flutter/material.dart';

import '../io/file_system.dart';
import '../io/logger.dart';
import '../multiprocess/childprocess.dart';
import '../multiprocess/childprocess_controller.dart';
import '../routes/window_type.dart';
import '../ui/charts/chart_logic/chart_controller.dart';
import '../ui/theme/theme.dart';
import 'data.dart';
import 'settings_classes.dart';
import 'signal_container.dart';
import 'updateable_valuenotifier.dart';

const int _scrollMultiplierVertical = 1; // setting
const int _dragMultiplierVertical = 1; // setting

final Map<String, Setting> __defaultSettings = {
  "visual.theme": Setting(identifier: "visual.theme", type: SettingType.SELECTION, selection: StyleManager.getStyleList(), max: null, min: null, value: StyleManager.getStyleList().indexOf(StyleManager.activeStyle)),
  "dbc.pathlist": Setting(identifier: "dbc.pathlist", type: SettingType.STRLIST, selection: [], max: null, min: null, value: 0)
};

abstract class SettingsProvider{
  static final Map<String, Setting> __setting = __defaultSettings;
  static const String __settingsPath = "Settings/";

  static void __syncToDisk() async {
    await FileSystem.trySaveMapToLocalAsync(__settingsPath, "settings.json", toJsonFormattable);
    if(windowType == WindowType.MAIN_WINDOW){
      ChildProcessController.triggerSettingsUpdateInChildProcesses();
    }
    else{
      ChildProcess.triggerSettingsUpdateInMaster();
    }
  }

  static void loadFromDisk() async {
    Map loaded = await FileSystem.tryLoadMapFromLocalAsync(__settingsPath, "settings.json");
    Map<String, Setting?> loadedEntries = loaded.map((key, value) => MapEntry(key as String, Setting.fromJson(value)));
    loadedEntries.removeWhere((key, value) => value == null);
    __setting.addAll(loadedEntries.cast<String, Setting>());
    localLogger.info("Settings reloaded");
  }

  static Map<String, Map<String, dynamic>> get toJsonFormattable =>
    __setting.map((key, value) => MapEntry(key, value.asJson));

  static set setting(final Map<String, Setting> newData){
    __setting.clear();
    for(String newSetting in newData.keys){
      if(newData[newSetting]!.trySet(newData[newSetting]!.value)){
        __setting[newSetting] = newData[newSetting]!;
      }
    }
    __syncToDisk();
  }

  static bool update(final String settingsPath, final dynamic newValue){
    if(__setting.containsKey(settingsPath)){
      if(newValue is num && __setting[settingsPath]!.type != SettingType.STRLIST){
        final bool success = __setting[settingsPath]!.trySet(newValue);
        __syncToDisk();
        return success;
      }
      else if(newValue is List<String> && __setting[settingsPath]!.type == SettingType.STRLIST){
        __setting[settingsPath] = Setting(identifier: settingsPath, type: SettingType.STRLIST, selection: newValue, max: null, min: null, value: 0);
        __syncToDisk();
        return true;
      }
    }
    return false;
  }

  static Setting? get(final String settingsPath){
    return __setting[settingsPath];
  }
}

abstract class TraceSettingsProvider{
  // TODO legyen egy map a group to measurementsre és egy group to signalidxre, hogy ne keresni kelljen hanem csak indexelni
  static UpdateableValueNotifier<Map<String, List<TraceSetting>>> traceSettingNotifier = UpdateableValueNotifier<Map<String, List<TraceSetting>>>({});

  static int _maxScalingGroup = 0;
  static int _newColorIndex = 0;

  static int firstVisibleTimestamp = ChartController.shownDurationNotifier.value.timeOffset;
  static int lastVisibleTimestamp = ChartController.shownDurationNotifier.value.timeOffset + ChartController.shownDurationNotifier.value.timeDuration;

  static int get fullVisibleTime => lastVisibleTimestamp - firstVisibleTimestamp;

  static List<Color> colorBank = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.brown,
  ];
  

  static Map<String, List> get toJsonFormattable => 
    traceSettingNotifier.value.map((key, value) => MapEntry(key, value.map((e) => e.asJson).toList()));

  static void reload(Map newData){
    for(String measurement in newData.keys){
      traceSettingNotifier.update((value) {
        value[measurement] ??= [];
        value.update(measurement, (value) => newData[measurement]!.map((e) => TraceSetting.fromJson(e)).toList().whereType<TraceSetting>().toList());
        
        _postUpdate(measurement);
        reCalculateVisibleDuration();
      });
    }
  }

  static void _postUpdate(final String measurement){
    if(windowType == WindowType.MAIN_WINDOW){
      for(TraceSetting traceSetting in traceSettingNotifier.value[measurement]!){
        signalData[measurement]![traceSetting.signal]!.displayName = traceSetting.displayName;
      }
    }
  }

  static void reCalculateVisibleDuration(){
    final Map<String, List<String>> vis = visibleSignals;
    int first = double.maxFinite.toInt();
    int last = 0;

    for(final String meas in vis.keys){
      for(final String sig in vis[meas]!){
        final int sigFirst = signalData[meas]![sig]!.timestamps.first.toInt();
        final int sigLast = signalData[meas]![sig]!.timestamps.last.toInt();
        if(sigFirst < first){
          first = sigFirst;
        }
        if(sigLast > last){
          last = sigLast;
        }
      }
    }

    if(last != 0){
      firstVisibleTimestamp = first;
      lastVisibleTimestamp = last;
    }
  }

  static List<int> calculateMeasDuration(){
    int first = double.maxFinite.toInt();
    int last = 0;

    for(final String meas in traceSettingNotifier.value.keys){
      for(final TraceSetting sig in traceSettingNotifier.value[meas]!){
        final int sigFirst = signalData[meas]![sig.signal]!.timestamps.first.toInt();
        final int sigLast = signalData[meas]![sig.signal]!.timestamps.last.toInt();
        if(sigFirst < first){
          first = sigFirst;
        }
        if(sigLast > last){
          last = sigLast;
        }
      }
    }

    return [first, last];
  }

  static void addEntriesFrom(final String measurement, final List<SignalContainer> signalContainers){
    traceSettingNotifier.update((traceSetting) {
      traceSetting[measurement] = signalContainers.map((signalContainer) {
        num minValue = signalContainer.values.iterable.fold(double.maxFinite, (previousValue, element) => min(previousValue, element));
        num maxValue = signalContainer.values.iterable.fold(-double.maxFinite, (previousValue, element) => max(previousValue, element));
        if(minValue == maxValue){
          minValue--;
          maxValue++;
        }
        return TraceSetting(signal: signalContainer.dbcName, color: _nextColor, scalingGroup: _nextScalingGroup, displayName: signalContainer.displayName)
          ..offset = minValue..span = maxValue - minValue;
        }
      ).toList();
      
      _postUpdate(measurement);
      reCalculateVisibleDuration();
    });
  }

  static void updateEntriesFrom(final String measurement, final List<String> signals){
    if(!signalData.containsKey(measurement)){
      return;
    }

    traceSettingNotifier.update((value) {
      if(!traceSettingNotifier.value.containsKey(measurement)){
        value[measurement] = [];
      }
      for(final String sig in signals){
        if(!signalData[measurement]!.containsKey(sig)){
          localLogger.error("Skipping signal $sig from updating as it does not exist in measurement $measurement");
          continue;
        }

        final int sigIdx = value[measurement]!.indexWhere((ts) => ts.signal == sig);
        final num minValue = signalData[measurement]![sig]!.values.iterable.fold(double.maxFinite, (previousValue, element) => min(previousValue, element));
        final num maxValue = signalData[measurement]![sig]!.values.iterable.fold(-double.maxFinite, (previousValue, element) => max(previousValue, element));

        if(sigIdx == -1){
          value[measurement]!.add(TraceSetting(signal: sig, color: _nextColor, scalingGroup: _nextScalingGroup, displayName: sig)
          ..offset = minValue..span = maxValue - minValue
          );
        }
        else{
          value[measurement]![sigIdx].offset = minValue;
          value[measurement]![sigIdx].span = maxValue - minValue;
        }
      }
      
      _postUpdate(measurement);
      reCalculateVisibleDuration();
    });
  }

  static int itemCount(String measurement){
    return traceSettingNotifier.value[measurement]?.length ?? 0;
  }

  static int get _nextScalingGroup => _maxScalingGroup++;

  static Color get _nextColor {
    _newColorIndex = _newColorIndex >= colorBank.length - 2 ? 0 : _newColorIndex + 1;
    return colorBank[_newColorIndex];
  }

  static Map<int, List<TraceSetting>> get scalingGroups {
    Map<int, List<TraceSetting>> tmp = {};
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        tmp.update(traceSettingNotifier.value[measurement]![i].scalingGroup, (value) {
          if(traceSettingNotifier.value[measurement]![i].isVisible){
            return value..add(traceSettingNotifier.value[measurement]![i]);
          }
            return value;
          });
      }
    }
    return tmp;
  }

  static Set<int> get scalingGroupSet {
    Set<int> tmp = {};
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].isVisible){
          tmp.add(traceSettingNotifier.value[measurement]![i].scalingGroup);
        }
      }
    }
    return tmp;
  }

  static Color colorOfScalingGroup(final int group) {
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].scalingGroup == group){
          return traceSettingNotifier.value[measurement]![i].color;
        }
      }
    }
    return Colors.grey;
  }

  static Color colorOfSignal(final String signal) {
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].signal == signal){
          return traceSettingNotifier.value[measurement]![i].color;
        }
      }
    }
    return Colors.grey;
  }

  static Map<String, List<String>> get visibleSignals {
    Map<String, List<String>> tmp = {};
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].isVisible){
          tmp[measurement] ??= [];
          tmp[measurement]!.add(traceSettingNotifier.value[measurement]![i].signal);
        }
      }
    }
    return tmp;
  }

  static Map<String, List<TraceSetting>> get visibleSignalsData{
    Map<String, List<TraceSetting>> tmp = {};
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].isVisible){
          tmp[measurement] ??= [];
          tmp[measurement]!.add(traceSettingNotifier.value[measurement]![i]);
        }
      }
    }
    return tmp;
  }

  static void dragScalingGroup(final int group, final double delta){
    traceSettingNotifier.update((traceSetting) {
      for(String measurement in traceSetting.keys){
        for(int i = 0; i < traceSetting[measurement]!.length; i++){
          if(traceSetting[measurement]![i].scalingGroup == group){
            traceSetting[measurement]![i].offset += ChartController.verticalDragDelta(delta, traceSetting[measurement]![i].span.toDouble()) * _dragMultiplierVertical;
          }
        }
      }
    });
  }

  static void zoomScalingGroup(final int group, final double delta){
    traceSettingNotifier.update((traceSetting) {
      for(String measurement in traceSetting.keys){
        for(int i = 0; i < traceSetting[measurement]!.length; i++){
          if(traceSetting[measurement]![i].scalingGroup == group){
            double diff = (traceSetting[measurement]![i].span * 0.001 * delta * _scrollMultiplierVertical);
            if(diff == 0){
              diff = delta.sign * traceSetting[measurement]![i].span * 0.01;
            }
            traceSetting[measurement]![i].offset -= diff;
            traceSetting[measurement]![i].span += diff * 2;
          }
        }
      }
    });
  }

  static Map<String, dynamic> getValueAxisDataForGroup(final int group){
    for(String measurement in traceSettingNotifier.value.keys){
      for(int i = 0; i < traceSettingNotifier.value[measurement]!.length; i++){
        if(traceSettingNotifier.value[measurement]![i].scalingGroup == group){
          return {
            "span": traceSettingNotifier.value[measurement]![i].span,
            "offset": traceSettingNotifier.value[measurement]![i].offset,
            "unit": signalData[measurement]![traceSettingNotifier.value[measurement]![i].signal]?.unit
          };
        }
      }
    }
    return {};
  }

}