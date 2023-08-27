import '../../../data/settings_classes.dart';
import '../../../data/updateable_valuenotifier.dart';
import '../chart_area.dart';
import '../../../data/settings.dart';

const int _scrollMultiplierHorizontal = 10; // setting
const int _dragMultiplierHorizontal = 100; // setting

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
    final int delta = (shownDurationNotifier.value.timeDuration * 1e-5 * pointerSignalScrollDelta * _scrollMultiplierHorizontal).toInt();
    print(delta);
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
}