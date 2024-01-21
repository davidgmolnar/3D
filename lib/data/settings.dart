import 'dart:math';

import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../routes/window_type.dart';
import '../ui/charts/chart_logic/chart_controller.dart';
import '../ui/theme/theme.dart';
import 'data.dart';
import 'settings_classes.dart';
import 'signal_container.dart';
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
  // TODO legyen egy map a group to measurementsre és egy group to signalidxre, hogy ne keresni kelljen hanem csak indexelni
  static UpdateableValueNotifier<Map<String, List<TraceSetting>>> traceSettingNotifier = UpdateableValueNotifier<Map<String, List<TraceSetting>>>({});

  static int _maxScalingGroup = 0;
  static int _newColorIndex = 0;

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
      });
      _postUpdate(measurement);
    } 
  }

  static void _postUpdate(final String measurement){
    if(windowType == WindowType.MAIN_WINDOW){
      for(TraceSetting traceSetting in traceSettingNotifier.value[measurement]!){
        signalData[measurement]![traceSetting.signal]!.displayName = traceSetting.displayName;
      }
    }
  }

  static void addEntriesFrom(final String measurement, final List<SignalContainer> signalContainers){
    traceSettingNotifier.update((traceSetting) {
      traceSetting[measurement] = signalContainers.map((signalContainer) {
        final num minValue = signalContainer.values.fold(double.maxFinite, (previousValue, element) => min(previousValue, element.value));
        final num maxValue = signalContainer.values.fold(-double.maxFinite, (previousValue, element) => max(previousValue, element.value));
        return TraceSetting(signal: signalContainer.dbcName, color: _nextColor, scalingGroup: _nextScalingGroup, displayName: signalContainer.displayName)
          ..offset = minValue..span = maxValue - minValue;
        }
      ).toList();
    });
    _postUpdate(measurement);
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

  static int get firstVisibleTimestamp {
    int tmp = -1;
    for(String measurement in traceSettingNotifier.value.keys){
      for(TraceSetting traceSetting in traceSettingNotifier.value[measurement]!){
        final int first = signalData[measurement]![traceSetting.signal]!.values.first.timeStamp;
        if(tmp == -1){
          tmp = first;
        }
        else if(first < tmp){
          tmp = first;
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
            traceSetting[measurement]![i].offset += ChartController.verticalDragDelta(delta, traceSetting[measurement]![i].span.toDouble()) * _dragMultiplierVertical;
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

  static Map<String, dynamic> getValueAxisDataForGroup(int group){
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