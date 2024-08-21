import 'package:flutter/material.dart';

import '../../../data/data.dart';
import '../../../data/settings_classes.dart';
import '../../../data/custom_notifiers.dart';
import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../../routes/window_type.dart';
import '../../dialogs/dialog_base.dart';
import '../../dialogs/dropdown_input_dialog.dart';
import '../../dialogs/string_input_dialog.dart';
import '../chart_area.dart';
import '../../../data/settings.dart';
import '../chart_bottom_overview.dart';
import '../../../ui/notifications/notification_logic.dart' as noti;

const int _scrollMultiplierHorizontal = 1; // setting
const int _dragMultiplierHorizontal = 1; // setting

class ChartShowDuration{
  double timeOffset;
  double timeDuration;

  ChartShowDuration({required this.timeDuration, required this.timeOffset});

  @override
  bool operator ==(covariant ChartShowDuration other){
    return timeOffset == other.timeOffset && timeDuration == other.timeDuration;
  }

  @override
  int get hashCode => timeOffset.hashCode ^ timeDuration.hashCode;
}

enum ChartDrawMode{
  // ignore: constant_identifier_names
  LINE,
  // ignore: constant_identifier_names
  SCATTER,
}

class ChartDrawModes{
  final Map<String, Map<String, ChartDrawMode>> data;

  ChartDrawModes({required this.data});

  ChartDrawMode getMode(String measurement, String signal) {
    if(data.containsKey(measurement) && data[measurement]!.containsKey(signal)){
      return data[measurement]![signal]!;
    }
    return ChartDrawMode.LINE;
  }
}

class MainChartPreset{
  final Map<String, List<TraceSetting>> signals;
  final String? bottomMeas;
  final List<String> bottomSignals;

  MainChartPreset({required this.signals, required this.bottomMeas, required this.bottomSignals});

  void saveToFile(final String name){
    final Map jsonFormattable = {};
    jsonFormattable["traces"] = signals.map((key, value) => MapEntry(key, value.map((e) => e.asJson).toList()));
    if(bottomMeas != null && bottomSignals.isNotEmpty){
      jsonFormattable["bottom_overview"] = {
        "meas": bottomMeas,
        "signals": bottomSignals
      };
    }

    FileSystem.trySaveMapToLocalSync(FileSystem.mainChartPresetDir, name, jsonFormattable);
  }

  static MainChartPreset loadFromFile(final String name){
    final Map preset = FileSystem.tryLoadMapFromLocalSync(FileSystem.mainChartPresetDir, name);

    final Map<String, List<TraceSetting>> signals = {};
    String? bottomMeas;
    final List<String> bottomSignals = [];

    for(final String meas in preset["traces"]!.keys){
      signals[meas] = [];
      for(final Map sigdesc in preset["traces"]![meas]!.cast<Map>()){
        final TraceSetting? setting = TraceSetting.fromJson(sigdesc.cast<String, dynamic>());
        if(setting != null){
          signals[meas]!.add(setting);
        }
      }
    }

    if(preset.containsKey("bottom_overview")){
      bottomMeas = preset["bottom_overview"]!["meas"]!;
      bottomSignals.addAll(preset["bottom_overview"]!["signals"]!.cast<String>());
    }

    return MainChartPreset(signals: signals, bottomMeas: bottomMeas, bottomSignals: bottomSignals);
  }
}

abstract class ChartController{
  static final UpdateableValueNotifier<ChartShowDuration> shownDurationNotifier = UpdateableValueNotifier<ChartShowDuration>(ChartShowDuration(timeOffset: 0, timeDuration: 1000));
  static final UpdateableValueNotifier<ChartDrawModes> drawModesNotifier = UpdateableValueNotifier<ChartDrawModes>(ChartDrawModes(data: {}));

  static double _chartAreaWidth = 0;
  static double get chartWidth => _chartAreaWidth;
  static double _chartAreaHeight = 0;
  static double get chartHeigth => _chartAreaHeight;

  static void setScreenSize(double newWidth, double newHeight){
    shownDurationNotifier.update((value) {});
    _chartAreaHeight = newHeight;
    _chartAreaWidth = newWidth;
  }

  static set zoomInTime(double pointerSignalScrollDelta){
    double delta = (shownDurationNotifier.value.timeDuration * 1e-3 * pointerSignalScrollDelta * _scrollMultiplierHorizontal);

    shownDurationNotifier.update((shown) {
      shown.timeOffset += delta;
      shown.timeDuration -= delta * 2;

      if(shown.timeOffset < 0){
        shown.timeOffset = 0;
      }
    });

    _maybeUpdateChartGrid();
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      final double delta = horizontalDragUpdateDelta / _chartAreaWidth * shown.timeDuration * _dragMultiplierHorizontal;
      shown.timeOffset -= delta;

      if(shown.timeOffset < 0){
        shown.timeOffset = 0;
      }
    });

    _maybeUpdateChartGrid();
  }

  static void _maybeUpdateChartGrid(){
    if(windowType == WindowType.CUSTOM_CHART && customChartWindowType == CustomChartWindowType.GRID && isInSharingGroup){
      ChildProcess.sendCustomChartUpdate(setCustomChartShownDurationPayload(shownDurationNotifier.value));
    }
  }

  static set moveInFullChannelTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      final double delta = horizontalDragUpdateDelta / _chartAreaWidth * TraceSettingsProvider.fullVisibleTime * _dragMultiplierHorizontal;
      shown.timeOffset -= delta;
    });
    
    _maybeUpdateChartGrid();
  }

  static double verticalDragDelta(double delta, double range){
    return delta / _chartAreaHeight * range;
  }

  static double moveInCursonTime(double horizontalDragUpdateDelta){
    final double delta = horizontalDragUpdateDelta / _chartAreaWidth * shownDurationNotifier.value.timeDuration * _dragMultiplierHorizontal;
    return delta;
  }

  static ScalingInfo scalingFor(String measurement, String signal){
    final TraceSetting traceSetting = TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal);
    return ScalingInfo(
      timeScale: _chartAreaWidth / shownDurationNotifier.value.timeDuration,
      timeDuration: shownDurationNotifier.value.timeDuration,
      timeOffset:  shownDurationNotifier.value.timeOffset,
      valueScale: _chartAreaHeight / traceSetting.span.toDouble(),
      valueRange: traceSetting.span.toDouble(),
      valueOffset: traceSetting.offset.toDouble(),
      startIndex: -1,
      measCount: -1
    );
  }

  static double? timeStampToPosition(final double timestamp) {
    if(timestamp > shownDurationNotifier.value.timeOffset && timestamp < shownDurationNotifier.value.timeDuration + shownDurationNotifier.value.timeOffset){
      return (timestamp - shownDurationNotifier.value.timeOffset) / shownDurationNotifier.value.timeDuration * _chartAreaWidth;
    }
    return null;
  }

  static double positionToTimeStamp(final double position){
    return (position / _chartAreaWidth * shownDurationNotifier.value.timeDuration) + shownDurationNotifier.value.timeOffset;
  }

  static void savePreset(final BuildContext context){
    final MainChartPreset preset = MainChartPreset(
      signals: TraceSettingsProvider.visibleSignalsData,
      bottomMeas: ChartBottomOverviewChartLineState.meas,
      bottomSignals: ChartBottomOverviewChartLineState.signals
    );

    showDialog<Widget>(context: context, builder: (BuildContext context){
      return DialogBase(
        title: "Input dialog",
        dialog: StringInputDialog(
          hintText: "Specify preset name",
          onFinished: (presetName) async {
            if(FileSystem.tryListElementsInLocalSync(FileSystem.mainChartPresetDir).any((element) => element.uri.path.endsWith("$presetName.3DCHARTPRESET"))){
              noti.NotificationController.add(noti.Notification.decaying(LogEntry.error("A preset with this name already exists"), 5000));
            }
            else{
              preset.saveToFile("$presetName.3DCHARTPRESET");
              noti.NotificationController.add(noti.Notification.decaying(LogEntry.info("Preset saved"), 5000));
            }
          },
        ),
        minWidth: 400,
        maxHeight: 100,
      );
    });
  }

  static void loadPreset(final BuildContext context){
    final List<String> presetNames = (FileSystem.tryListElementsInLocalSync(FileSystem.mainChartPresetDir)).where((element) => element.uri.path.endsWith(".3DCHARTPRESET")).map((e) => e.uri.path.split('/').last.split('\\').last.split('.').first).toList();             
    if(presetNames.isEmpty){
      noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("No previous Statisitics View presets have been found"), 5000));
      return;
    }

    showDialog<Widget>(context: context, builder: (BuildContext context){
      return DialogBase(
        title: "Input dialog",
        dialog: DropdownInputDialog(
          hintText: "Specify preset name",
          options: presetNames,
          onFinished: (presetName) async {
            if(presetName != null){
              final MainChartPreset preset = MainChartPreset.loadFromFile("$presetName.3DCHARTPRESET");
              for(final String meas in TraceSettingsProvider.traceSettingNotifier.value.keys){
                for(int i = 0; i < TraceSettingsProvider.traceSettingNotifier.value[meas]!.length; i++){
                  TraceSettingsProvider.traceSettingNotifier.value[meas]![i].isVisible = false;
                }
              }
              for(final String meas in preset.signals.keys){
                if(TraceSettingsProvider.traceSettingNotifier.value.containsKey(meas)){
                  for(final TraceSetting sig in preset.signals[meas]!){
                    if(signalData[meas]!.containsKey(sig.signal)){
                      sig.scalingGroup = TraceSettingsProvider.nextScalingGroup;
                      TraceSettingsProvider.traceSettingNotifier.value[meas]!.removeWhere((element) => element.signal == sig.signal);
                      TraceSettingsProvider.traceSettingNotifier.value[meas]!.add(sig);
                    }
                    else{
                      noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Signal ${sig.signal} is not imported, skipping"), 5000));
                    }
                  }
                }
                else{
                  noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Measurement $meas is not imported, skipping"), 5000));
                }
              }

              if(preset.bottomMeas != null && preset.bottomSignals.isNotEmpty){
                ChartBottomOverviewChartLineState.meas = preset.bottomMeas;
                ChartBottomOverviewChartLineState.signals = preset.bottomSignals;
              }

              TraceSettingsProvider.reCalculateVisibleDuration();
              TraceSettingsProvider.traceSettingNotifier.update((value) { });
            }
          }
        ),
        minWidth: 400,
        maxHeight: 100,
      );
    });
  }
}