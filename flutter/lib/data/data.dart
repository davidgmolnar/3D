import 'dart:typed_data';

import 'signal_container.dart';
import 'typed_data_list_container.dart';

// [measurement][signal] = data
Map<String, Map<String, SignalContainer>> signalData = {};

Map<String, List<String>> get measurementSignalMap => signalData.map((key, value) => MapEntry(key, value.keys.toList()));

Map<String, Map<String, num>> cursorDataAtTimeStamp(final int timeStamp, Map<String, List<String>> visibility) {
  Map<String, Map<String, num>> dataAtTimeStamp = {};
  for(String meas in visibility.keys){
    for(String signal in visibility[meas]!){
      final num? val = _binarySearchValueAtTimeStamp(signalData[meas]![signal]!.values, signalData[meas]![signal]!.timestamps, timeStamp);
      if(val != null){
        if(!dataAtTimeStamp.keys.contains(meas)){
          dataAtTimeStamp[meas] = {};
        }
        dataAtTimeStamp[meas]![signal] = val;
      }
    }
  }
  return dataAtTimeStamp;
}

num signalIntegral(final String meas, final String signal, final int ref, final int stop){
  final int inc = ref < stop ? 1 : -1;
  int? currIndex = _binarySearchIndexAtTimeStamp(signalData[meas]![signal]!.values, signalData[meas]![signal]!.timestamps, ref);
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
      sum += ((currVal + nextVal) / 2) * (currTs - nextTs).abs() / 1000.0; // ms to s
      currIndex = currIndex! + inc;
      currVal = signalData[meas]![signal]!.values[currIndex];
      currTs = signalData[meas]![signal]!.timestamps[currIndex];
      nextVal = signalData[meas]![signal]!.values[currIndex + inc];
      nextTs = signalData[meas]![signal]!.timestamps[currIndex + inc];
    }
    return sum;
  }
}

num? _binarySearchValueAtTimeStamp(final TypedDataListContainer<TypedData> values, final TypedDataListContainer<TypedData> timeStamps, final int timeStamp){
  if(timeStamp > timeStamps.last || timeStamp < timeStamps.first){
    return null;
  }
  int partStart = 0;
  int partEnd = values.size - 1;
  int searchIndex = -1;
  while(partStart <= partEnd){
    searchIndex = ((partStart + partEnd) / 2).floor();
    if(timeStamps[searchIndex] < timeStamp){
      partStart = searchIndex + 1;
    }
    else if(timeStamps[searchIndex] > timeStamp){
      partEnd = searchIndex - 1;
    }
    else{
      // direkt találat
      return values[searchIndex];
    }
  }
  // legközelebbi találat
  return values[searchIndex];
}

int? _binarySearchIndexAtTimeStamp(final TypedDataListContainer<TypedData> values, final TypedDataListContainer<TypedData> timeStamps, final int timeStamp){
  if(timeStamp > timeStamps.last || timeStamp < timeStamps.first){
    return null;
  }
  int partStart = 0;
  int partEnd = values.size - 1;
  int searchIndex = -1;
  while(partStart <= partEnd){
    searchIndex = ((partStart + partEnd) / 2).floor();
    if(timeStamps[searchIndex] < timeStamp){
      partStart = searchIndex + 1;
    }
    else if(timeStamps[searchIndex] > timeStamp){
      partEnd = searchIndex - 1;
    }
    else{
      // direkt találat
      return searchIndex;
    }
  }
  // legközelebbi találat
  return searchIndex;
}

int timestampAtMax(final String meas, final String signal, final int start, final int stop){
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
  return signalData[meas]![signal]!.timestamps[minIndex!].toInt();
}

int timestampAtMin(final String meas, final String signal, final int start, final int stop){
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
  return signalData[meas]![signal]!.timestamps[maxIndex!].toInt();
}

String representNumber(String ret, {int maxDigit = 10}){
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