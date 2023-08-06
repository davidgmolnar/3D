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
  static final UpdateableValueNotifier<ChartShowDuration> shownDurationNotifier = UpdateableValueNotifier<ChartShowDuration>(ChartShowDuration(timeOffset: 0, timeDuration: 1000));

  static double chartAreaWidth = 0;
  static double chartAreaHeight = 0;

  static set zoomInTime(double pointerSignalScrollDelta){
    final int delta = (shownDurationNotifier.value.timeDuration * 0.01 * pointerSignalScrollDelta * _scrollMultiplierHorizontal).toInt();
    shownDurationNotifier.update((shown) {
      shown.timeOffset -= delta;
      shown.timeDuration += delta * 2;
    });
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      shown.timeOffset -= horizontalDragUpdateDelta.toInt() * _dragMultiplierHorizontal;
    });
  }

  static double durationToScale<T>(double screenDimension, T duration){
    if(duration is num){
      return screenDimension / duration;
    }
    throw Exception("Duration was not num in ChartController.durationToScale");
  }

  static ScalingInfo scalingFor(String measurement, String signal){
    final TraceSetting traceSetting = TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal);
    return ScalingInfo(
      timeScale: chartAreaWidth / shownDurationNotifier.value.timeDuration,
      timeDuration: shownDurationNotifier.value.timeDuration,
      timeOffset:  shownDurationNotifier.value.timeOffset,
      valueScale: chartAreaHeight / traceSetting.span.toDouble(),
      valueRange: traceSetting.span.toDouble(),
      valueOffset: traceSetting.offset.toDouble(),
      startIndex: -1,
      measCount: -1
    );
  }
}