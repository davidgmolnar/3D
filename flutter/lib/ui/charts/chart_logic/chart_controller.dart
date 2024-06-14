import '../../../data/settings_classes.dart';
import '../../../data/custom_notifiers.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../../routes/window_type.dart';
import '../chart_area.dart';
import '../../../data/settings.dart';

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
    });

    _maybeUpdateChartGrid();
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      final double delta = horizontalDragUpdateDelta / _chartAreaWidth * shown.timeDuration * _dragMultiplierHorizontal;
      shown.timeOffset -= delta;
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
}