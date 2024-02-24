import 'signal_container.dart';

// [measurement][signal] = data
Map<String, Map<String, SignalContainer>> signalData = {};

Map<String, List<String>> get measurementSignalMap => signalData.map((key, value) => MapEntry(key, value.keys.toList()));

Map<String, Map<String, num>> cursorDataAtTimeStamp(final int timeStamp, Map<String, List<String>> visibility) {
  Map<String, Map<String, num>> dataAtTimeStamp = {};
  for(String meas in visibility.keys){
    for(String signal in visibility[meas]!){
      final num? val = _binarySearchValueAtTimeStamp(signalData[meas]![signal]!.values, timeStamp);
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
  int? currIndex = _binarySearchIndexAtTimeStamp(signalData[meas]![signal]!.values, ref);
  if(currIndex == null){
    return 0;
  }
  else{
    num sum = 0;
    Measurement currVal = signalData[meas]![signal]!.values[currIndex];
    Measurement nextVal = signalData[meas]![signal]!.values[currIndex + inc];
    while(ref < stop ? nextVal.timeStamp <= stop : nextVal.timeStamp >= stop){
      sum += ((currVal.value + nextVal.value) / 2) * (currVal.timeStamp - nextVal.timeStamp).abs() / 1000.0; // ms to s
      currIndex = currIndex! + inc;
      currVal = signalData[meas]![signal]!.values[currIndex];
      nextVal = signalData[meas]![signal]!.values[currIndex + inc];
    }
    return sum;
  }
}

num? _binarySearchValueAtTimeStamp(final List<Measurement> list, final int timeStamp){
  if(timeStamp > list.last.timeStamp || timeStamp < list.first.timeStamp){
    return null;
  }
  int partStart = 0;
  int partEnd = list.length - 1;
  int searchIndex = -1;
  while(partStart <= partEnd){
    searchIndex = ((partStart + partEnd) / 2).floor();
    if(list[searchIndex].timeStamp < timeStamp){
      partStart = searchIndex + 1;
    }
    else if(list[searchIndex].timeStamp > timeStamp){
      partEnd = searchIndex - 1;
    }
    else{
      // direkt találat
      return list[searchIndex].value;
    }
  }
  // legközelebbi találat
  return list[searchIndex].value;
}

int? _binarySearchIndexAtTimeStamp(final List<Measurement> list, final int timeStamp){
  if(timeStamp > list.last.timeStamp || timeStamp < list.first.timeStamp){
    return null;
  }
  int partStart = 0;
  int partEnd = list.length - 1;
  int searchIndex = -1;
  while(partStart <= partEnd){
    searchIndex = ((partStart + partEnd) / 2).floor();
    if(list[searchIndex].timeStamp < timeStamp){
      partStart = searchIndex + 1;
    }
    else if(list[searchIndex].timeStamp > timeStamp){
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
  return signalData[meas]![signal]!.values.skipWhile((value) => value.timeStamp < start).takeWhile((value) => value.timeStamp < stop).fold(Measurement(double.negativeInfinity, 0), (previousValue, element){
    if(previousValue.value < element.value){
      return element;
    }
    return previousValue;
  }).timeStamp;
}

int timestampAtMin(final String meas, final String signal, final int start, final int stop){
  return signalData[meas]![signal]!.values.skipWhile((value) => value.timeStamp < start).takeWhile((value) => value.timeStamp < stop).fold(Measurement(double.infinity, 0), (previousValue, element){
    if(previousValue.value > element.value){
      return element;
    }
    return previousValue;
  }).timeStamp;
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