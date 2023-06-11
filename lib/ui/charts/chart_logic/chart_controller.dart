import '../../../data/settings.dart';
import '../../../data/signal_container.dart';
import '../../../data/updateable_valuenotifier.dart';

const int _scrollMultiplier = 1; // setting
const int _moveMultiplier = 1; // setting

class ChartShowDuration{
  int offset;
  int duration;

  ChartShowDuration({required this.offset, required this.duration});
}

abstract class ChartController{
  static final UpdateableValueNotifier<ChartShowDuration> shownDurationNotifier = UpdateableValueNotifier<ChartShowDuration>(ChartShowDuration(offset: 0, duration: 1000));

  static set zoomInTime(double pointerSignalScrollDelta){
    final int delta = (shownDurationNotifier.value.duration * 0.01 * pointerSignalScrollDelta * _scrollMultiplier).toInt();
    shownDurationNotifier.update((shown) {
      shown.offset -= delta;
      shown.duration += delta * 2;
    });
  }

  static set moveInTime(double horizontalDragUpdateDelta){
    shownDurationNotifier.update((shown) {
      shown.offset -= horizontalDragUpdateDelta.toInt() * _moveMultiplier;
    });
  }

  static final Map<String, Map<String, SignalContainer>> _shownData = {};
  static Map<String, Map<String,SignalContainer>> get shownData => _shownData;

  static void reloadShownData(){
    final Map<String, List<String>> visibleSignals = TraceSettingsProvider.visibleSignals;
    // delete thats not visible anymore
    for(String measurement in _shownData.keys){
      if(!visibleSignals.containsKey(measurement)){
        _shownData.remove(measurement);
        continue;
      }
      for(String signal in _shownData[measurement]!.keys){
        if(!visibleSignals[measurement]!.contains(signal)){
          _shownData[measurement]!.remove(signal);
        }
      }
    }
    // add new data to all in visibleSignals
    for(String measurement in visibleSignals.keys){
      _shownData[measurement] ??= {};
      for(String signal in visibleSignals[measurement]!){
        if(_shownData[measurement]!.containsKey(signal)){
          _shownData[measurement]![signal]!.updateSignalContainer(shownDurationNotifier.value);
        }
        else{
          _shownData[measurement]![signal] = SignalContainer.create(shownDurationNotifier.value);
        }
      }
    }
  }
}