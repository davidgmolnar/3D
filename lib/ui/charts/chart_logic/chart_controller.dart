import '../../../data/updateable_valuenotifier.dart';
import '../chart_area.dart';
import '../../../data/settings.dart';

const int _scrollMultiplierHorizontal = 1; // setting
const int _dragMultiplierHorizontal = 1; // setting

class ChartShowDuration{
  int offset;
  int duration;

  ChartShowDuration({required this.offset, required this.duration});
}

abstract class ChartController{
  static final UpdateableValueNotifier<ChartShowDuration> shownDurationNotifier = UpdateableValueNotifier<ChartShowDuration>(ChartShowDuration(offset: 0, duration: 1000));

  static set zoomInTime(double pointerSignalScrollDelta){
    final int delta = (shownDurationNotifier.value.duration * 0.01 * pointerSignalScrollDelta * _scrollMultiplierHorizontal).toInt();
    shownDurationNotifier.update((shown) {
      shown.offset -= delta;
      shown.duration += delta * 2;
    });
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      shown.offset -= horizontalDragUpdateDelta.toInt() * _dragMultiplierHorizontal;
    });
  }

  static ScalingInfo scalingFor(String measurement, String signal){
    return ScalingInfo(
      duration: shownDurationNotifier.value.duration,
      spanY: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).span.toDouble(),
      offsetY: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).offset.toDouble()
    );
  }
}