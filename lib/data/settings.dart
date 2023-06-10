import 'package:log_analyser/ui/theme.dart';

import 'settings_classes.dart';

final Map<String, List<Setting>> _defaultSettings = {
  "Visual": [
    Setting(identifier: "Theme", type: SettingType.SELECTION, selection: StyleManager.getStyleList(), max: null, min: null, value: StyleManager.getStyleList().indexOf(StyleManager.activeStyle)),
  ]
};

abstract class SettingsProvider{
  static final Map<String, List<Setting>> settings = _defaultSettings;

  static Map<String, List> toJsonFormattable(Map<String,List> map){
    return map.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
  }
}