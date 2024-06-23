import 'dart:typed_data';

import '../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../routes/window_type.dart';
import 'signal_container.dart';
import 'typed_data_list_container.dart';

// [measurement][signal] = data
Map<String, Map<String, SignalContainer>> signalData = {};

Map<String, List<String>> get measurementSignalMap => signalData.map((key, value) => MapEntry(key, value.keys.toList()));

Map<String, Map<String, num>> cursorDataAtTimeStamp(final double timeStamp, Map<String, List<String>> visibility) {
  Map<String, Map<String, num>> dataAtTimeStamp = {};
  for(String meas in visibility.keys){
    for(String signal in visibility[meas]!){
      final num? val = binarySearchValueAtTimeStamp(signalData[meas]![signal]!.values, signalData[meas]![signal]!.timestamps, timeStamp);
      if(val != null){
        if(!dataAtTimeStamp.containsKey(meas)){
          dataAtTimeStamp[meas] = {};
        }
        dataAtTimeStamp[meas]![signal] = val;
      }
    }
  }
  return dataAtTimeStamp;
}

num signalIntegral(final String meas, final String signal, final double ref, final double stop){
  final int inc = ref < stop ? 1 : -1;
  int? currIndex = binarySearchIndexAtTimeStamp(signalData[meas]![signal]!.timestamps, ref);
  if(currIndex == null){
    return 0;
  }
  else{
    num sum = 0;
    num currVal = signalData[meas]![signal]!.values[currIndex];
    num currTs = signalData[meas]![signal]!.timestamps[currIndex];
    num nextVal = signalData[meas]![signal]!.values[currIndex + inc];
    num nextTs = signalData[meas]![signal]!.timestamps[currIndex + inc];
    while(ref < stop ? nextTs <= stop : nextTs >= stop){
      num valueInc = ((currVal + nextVal) / 2) * (currTs - nextTs).abs();
      if(windowType != WindowType.CUSTOM_CHART || customChartWindowType != CustomChartWindowType.CHARACTERISTICS){
        valueInc /= 1000.0; // ms to s
      }
      sum += valueInc;
      currIndex = currIndex! + inc;
      if(currIndex + inc >= signalData[meas]![signal]!.values.size || currIndex < 0){
        break;
      }
      currVal = signalData[meas]![signal]!.values[currIndex];
      currTs = signalData[meas]![signal]!.timestamps[currIndex];
      nextVal = signalData[meas]![signal]!.values[currIndex + inc];
      nextTs = signalData[meas]![signal]!.timestamps[currIndex + inc];
    }
    return sum;
  }
}

num? binarySearchValueAtTimeStamp(final TypedDataListContainer<TypedData> values, final TypedDataListContainer<TypedData> timeStamps, final double timeStamp){
  if(timeStamp > timeStamps.last || timeStamp < timeStamps.first){
    return null;
  }
  int partStart = 0;
  int partEnd = values.size - 1;
  double searchIndex = -1;
  while(partStart < partEnd){
    searchIndex = ((partStart + partEnd) / 2);
    if(timeStamps[searchIndex.toInt()] < timeStamp){
      partStart = searchIndex.ceil();
    }
    else if(timeStamps[searchIndex.toInt()] > timeStamp){
      partEnd = searchIndex.floor();
    }
    else{
      // direkt találat
      return values[searchIndex.toInt()];
    }
  }
  // legközelebbi találat
  return values[searchIndex.toInt()];
}

int? binarySearchIndexAtTimeStamp(final TypedDataListContainer<TypedData> timeStamps, final double timeStamp){
  if(timeStamp > timeStamps.last || timeStamp < timeStamps.first){
    return null;
  }
  int partStart = 0;
  int partEnd = timeStamps.size - 1;
  double searchIndex = -1;
  while(partStart < partEnd){
    searchIndex = ((partStart + partEnd) / 2);
    if(timeStamps[searchIndex.toInt()] < timeStamp){
      partStart = searchIndex.ceil();
    }
    else if(timeStamps[searchIndex.toInt()] > timeStamp){
      partEnd = searchIndex.floor();
    }
    else{
      // direkt találat
      return searchIndex.toInt();
    }
  }
  // legközelebbi találat
  return searchIndex.toInt();
}

double timestampAtMin(final String meas, final String signal, final double start, final double stop){
  int? minIndex;
  for(int i = 0; i < signalData[meas]![signal]!.values.size; i++){
    if(signalData[meas]![signal]!.timestamps[i] < start){
      continue;
    }
    else if(signalData[meas]![signal]!.timestamps[i] > stop){
      break;
    }
    minIndex ??= i;
    if(signalData[meas]![signal]!.values[minIndex] > signalData[meas]![signal]!.values[i]){
      minIndex = i;
    }
  }
  return signalData[meas]![signal]!.timestamps[minIndex!].toDouble();
}

double timestampAtMax(final String meas, final String signal, final double start, final double stop){
  int? maxIndex;
  for(int i = 0; i < signalData[meas]![signal]!.values.size; i++){
    if(signalData[meas]![signal]!.timestamps[i] < start){
      continue;
    }
    else if(signalData[meas]![signal]!.timestamps[i] > stop){
      break;
    }
    maxIndex ??= i;
    if(signalData[meas]![signal]!.values[maxIndex] < signalData[meas]![signal]!.values[i]){
      maxIndex = i;
    }
  }
  return signalData[meas]![signal]!.timestamps[maxIndex!].toDouble();
}

String representNumber(String ret, {final int maxDigit = 10}){
  if(ret.length > maxDigit){
    ret = ret.substring(0, maxDigit);
  }
  if(ret.contains('.')){
    while(ret.endsWith('0') && ret.length >= 2){
      ret = ret.substring(0, ret.length - 1);
    }}
    if(ret.endsWith('.')){
      ret = ret.substring(0, ret.length - 1);
    }
  return ret;
}

String msToTimeString(final num ms, {final bool addMs = false}) {// addMs = true if neighbouring majorTickMs values have diff of less than 1000
  int sec = ms ~/ 1000;
  int min = sec ~/ 60;
  sec = sec - min * 60;
  int remMs = (ms - sec * 1000 - min * 60000).toInt();
  bool neg = false;
  neg |= min < 0;
  neg |= sec < 0;
  neg |= remMs < 0;
  min = min.abs();
  sec = sec.abs();
  remMs = remMs.abs();
  final String pref = neg ? "-" : "";
  if (addMs) {
    return "$pref${min < 10 ? "0$min" : min}:${sec < 10 ? "0$sec" : sec}.${remMs > 100 ? remMs : remMs > 10 ? "0$remMs" : "00$remMs"}";
  }
  return "$pref${min < 10 ? "0$min" : min}:${sec < 10 ? "0$sec" : sec}";
}