import '../../../data/settings_classes.dart';
import '../../../data/updateable_valuenotifier.dart';
import '../chart_area.dart';
import '../../../data/settings.dart';

const int _scrollMultiplierHorizontal = 1; // setting
const int _dragMultiplierHorizontal = 1; // setting

class ChartShowDuration{
  int timeOffset;
  int timeDuration;

  ChartShowDuration({required this.timeDuration, required this.timeOffset});
}

abstract class ChartController{
  static final UpdateableValueNotifier<ChartShowDuration> shownDurationNotifier = UpdateableValueNotifier<ChartShowDuration>(ChartShowDuration(timeOffset: 500000, timeDuration: 200000));

  static double _chartAreaWidth = 0;
  static double _chartAreaHeight = 0;

  static void setScreenSize(double newWidth, double newHeight){
    shownDurationNotifier.update((value) {});
    _chartAreaHeight = newHeight;
    _chartAreaWidth = newWidth;
  }

  static set zoomInTime(double pointerSignalScrollDelta){
    final int delta = (shownDurationNotifier.value.timeDuration * 1e-3 * pointerSignalScrollDelta * _scrollMultiplierHorizontal).toInt();
    shownDurationNotifier.update((shown) {
      shown.timeOffset += delta;
      shown.timeDuration -= delta * 2;
    });
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      shown.timeOffset -= (horizontalDragUpdateDelta / _chartAreaWidth * shown.timeDuration * _dragMultiplierHorizontal).toInt();
    });
  }

  static int moveInCursonTime(double horizontalDragUpdateDelta){
    return (horizontalDragUpdateDelta / _chartAreaWidth * shownDurationNotifier.value.timeDuration).toInt();
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

  static double? timeStampToPosition(final int timestamp) {
    if(timestamp > shownDurationNotifier.value.timeOffset && timestamp < shownDurationNotifier.value.timeDuration + shownDurationNotifier.value.timeOffset){
      return (timestamp - shownDurationNotifier.value.timeOffset) / shownDurationNotifier.value.timeDuration * _chartAreaWidth;
    }
    return null;
  }

  static int positionToTimeStamp(final double position){
    return (position / _chartAreaWidth * shownDurationNotifier.value.timeDuration).toInt() + shownDurationNotifier.value.timeOffset;
  }
}