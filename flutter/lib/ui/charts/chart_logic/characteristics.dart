import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/calculation/unit.dart';
import '../../../data/data.dart';
import '../../../data/typed_data_list_container.dart';
import '../../../io/logger.dart';
import '../../../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../../routes/window_type.dart';
import 'chart_controller.dart';

abstract class CharacteristicsProcessor{
  static num _interpAt(final num y1, final num t1, final num y2, final num t2, final num t){
    if(t1 <= t2){
      if(t == t1){
        return y1;
      }
      else if(t == t2){
        return y2;
      }
      else{
        return y1 + (y2 - y1) / (t2 - t1) * (t - t1);
      }
    }
    else{
      return _interpAt(y2, t2, y1, t1, t);
    }
  }

  static int _commonStartTimeBaseIndex(final String meas, final String base, final String comp){
    final num firstComp = signalData[meas]![comp]!.timestamps.first; 
    return signalData[meas]![base]!.timestamps.toList().indexWhere((element) => element > firstComp);
  }

  static int _commonEndTimeBaseIndex(final String meas, final String base, final String comp){
    final num lastComp = signalData[meas]![comp]!.timestamps.last; 
    return signalData[meas]![base]!.timestamps.toList().lastIndexWhere((element) => element < lastComp);
  }

  static void process(){
    if(windowType != WindowType.CUSTOM_CHART && customChartWindowType != CustomChartWindowType.CHARACTERISTICS){
      localLogger.error("CharacteristicsProcessor.process was called on a non Characteristics window");
      return;
    }

    for(final String sig in customCharacteristics!.compSignals){
      final List<Offset> resampledChannel = [];

      final int firstCommonTimeBaseIndex = _commonStartTimeBaseIndex(customCharacteristics!.measurement, customCharacteristics!.baseSignal, sig);
      final int lastCommonTimeBaseIndex = _commonEndTimeBaseIndex(customCharacteristics!.measurement, customCharacteristics!.baseSignal, sig);

      int compIndex = signalData[customCharacteristics!.measurement]![sig]!.timestamps.toList<int>()
        .lastIndexWhere((point) => point < signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.timestamps[firstCommonTimeBaseIndex]);

      for(int baseIndex = firstCommonTimeBaseIndex; baseIndex < lastCommonTimeBaseIndex; baseIndex++){
        final num baseValue = signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.values[baseIndex];
        final num baseTime = signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.timestamps[baseIndex];

        while(compIndex + 1 < signalData[customCharacteristics!.measurement]![sig]!.values.size || signalData[customCharacteristics!.measurement]![sig]!.timestamps[compIndex + 1] < baseTime){
          compIndex++;
          break;
        }

        if(compIndex + 1 >= signalData[customCharacteristics!.measurement]![sig]!.values.size){
          break;
        }

        final num compValue = _interpAt(
          signalData[customCharacteristics!.measurement]![sig]!.values[compIndex],
          signalData[customCharacteristics!.measurement]![sig]!.timestamps[compIndex],
          signalData[customCharacteristics!.measurement]![sig]!.values[compIndex + 1],
          signalData[customCharacteristics!.measurement]![sig]!.timestamps[compIndex  +1],
          signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.timestamps[baseIndex]
        );

        resampledChannel.add(Offset(
          baseValue.toDouble(),
          compValue.toDouble()
        ));
      }
      // TODO do the same but append base resampled to comp, then sort and everything else is as usual -> the repeating-value-import-optimization can then be re-added
      
      resampledChannel.sort((final Offset a, final Offset b) => a.dx.compareTo(b.dx));

      TypedDataListContainer<Float32List> newValues = TypedDataListContainer<Float32List>(list: Float32List.fromList(resampledChannel.map((e) => e.dy).toList()));
      TypedDataListContainer<Float32List> newTime = TypedDataListContainer<Float32List>(list: Float32List.fromList(resampledChannel.map((e) => e.dx).toList()));

      signalData[customCharacteristics!.measurement]![sig]!.values.clear();
      signalData[customCharacteristics!.measurement]![sig]!.values = newValues;
      signalData[customCharacteristics!.measurement]![sig]!.timestamps.clear();
      signalData[customCharacteristics!.measurement]![sig]!.timestamps = newTime;
      signalData[customCharacteristics!.measurement]![sig]!.unit = unitDiv(
        signalData[customCharacteristics!.measurement]![sig]!.unit,
        signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.unit
      );
    }

    ChartController.drawModesNotifier.update((value) {
      value.data[customCharacteristics!.measurement] = {};
      for(final String sig in customCharacteristics!.compSignals){
        value.data[customCharacteristics!.measurement]![sig] = ChartDrawMode.SCATTER;
      }
    });

    localLogger.info(ChartController.drawModesNotifier.value.data.toString());

    ChartController.shownDurationNotifier.update((value) {
      value.timeOffset = signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.values.first.toDouble();
      value.timeDuration = signalData[customCharacteristics!.measurement]![customCharacteristics!.baseSignal]!.values.last.toDouble();
    });
  }
}