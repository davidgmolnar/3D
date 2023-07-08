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

  static ScalingInfo scalingFor(String measurement, String signal){
    return ScalingInfo(
      timeDuration: shownDurationNotifier.value.timeDuration,
      timeOffset:  shownDurationNotifier.value.timeOffset,
      valueRange: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).span.toDouble(),
      valueOffset: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).offset.toDouble()
    );
  }
}