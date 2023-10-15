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