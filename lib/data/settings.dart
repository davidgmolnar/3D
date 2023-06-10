import 'package:log_analyser/extensions.dart';
import 'package:log_analyser/ui/theme/theme.dart';

import 'settings_classes.dart';

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
  static final Map<String, List<TraceSetting>> _traceSetting = {};

  static Function chartUpdater = (){};

  static Map<String, List> get toJsonFormattable => 
    _traceSetting.map((key, value) => MapEntry(key, value.map((e) => e.asJson).toList()));

  static set update(Map<String, List> newData){
    for(String measurement in newData.keys){
      _traceSetting.update(measurement, (value) => newData[measurement]!.map((e) => TraceSetting.fromJson(e)).toList().removedWhere((element) => element == null) as List<TraceSetting>);
    }
    chartUpdater();
  }

  static Map<int, List<TraceSetting>> get scalingGroups {
    Map<int, List<TraceSetting>> tmp = {};
    for(String measurement in _traceSetting.keys){
      for(int i = 0; i < _traceSetting[measurement]!.length; i++){
        tmp.update(_traceSetting[measurement]![i].scalingGroup, (value) {
          if(_traceSetting[measurement]![i].isVisible){
            return value..add(_traceSetting[measurement]![i]);
          }
            return value;
          });
      }
    }
    return tmp;
  }

}