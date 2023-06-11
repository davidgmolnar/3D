import 'package:log_analyser/extensions.dart';
import 'package:log_analyser/ui/theme/theme.dart';

import 'settings_classes.dart';
import 'updateable_valuenotifier.dart';

const int _scrollMultiplierVertical = 1; // setting
const int _dragMultiplierVertical = 1; // setting

final Map<String, List<Setting>> _defaultSettings = {
  "Visual": [
    Setting(identifier: "Theme", type: SettingType.SELECTION, selection: StyleManager.getStyleList(), max: null, min: null, value: StyleManager.getStyleList().indexOf(StyleManager.activeStyle)),
  ]
};

abstract class SettingsProvider{
  static final Map<String, List<Setting>> setting = _defaultSettings;

  static Map<String, List> get toJsonFormattable =>
    setting.map((key, value) => MapEntry(key, value.map((e) => e.asJson).toList()));

  static set update(Map<String, List> newData){
    for(String category in newData.keys){
      setting.update(category, (value) => newData[category]!.map((e) => Setting.fromJson(e)).toList().removedWhere((element) => element == null) as List<Setting>);
    }
  }
}

abstract class TraceSettingsProvider{
  static UpdateableValueNotifier<Map<String, List<TraceSetting>>> traceSettingNotifier = UpdateableValueNotifier<Map<String, List<TraceSetting>>>({});

  static Map<String, List> get toJsonFormattable => 
    traceSettingNotifier.value.map((key, value) => MapEntry(key, value.map((e) => e.asJson).toList()));

  static set update(Map<String, List> newData){
    for(String measurement in newData.keys){
      traceSettingNotifier.value.update(measurement, (value) => newData[measurement]!.map((e) => TraceSetting.fromJson(e)).toList().removedWhere((element) => element == null) as List<TraceSetting>);
    }
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

  static void dragScalingGroup(int group, double delta){
    traceSettingNotifier.update((traceSetting) {
      for(String measurement in traceSetting.keys){
        for(int i = 0; i < traceSetting[measurement]!.length; i++){
          if(traceSetting[measurement]![i].scalingGroup == group){
            traceSetting[measurement]![i].offset -= delta.toInt() * _dragMultiplierVertical;
          }
        }
      }
    });
  }

  static void zoomScalingGroup(int group, double delta){
    traceSettingNotifier.update((traceSetting) {
      for(String measurement in traceSetting.keys){
        for(int i = 0; i < traceSetting[measurement]!.length; i++){
          if(traceSetting[measurement]![i].scalingGroup == group){
            final int diff = (traceSetting[measurement]![i].span * 0.01 * delta * _scrollMultiplierVertical).toInt();
            traceSetting[measurement]![i].offset -= diff;
            traceSetting[measurement]![i].span += diff * 2;
          }
        }
      }
    });
  }

}