import 'dart:math';
import 'dart:typed_data';

import '../../io/logger.dart';
import '../typed_data_list_container.dart';

///////////////////// IF ///////////////////////////

bool __g(final num x, final num y) => x > y;
bool __l(final num x, final num y) => x < y;
bool __geq(final num x, final num y) => x >= y;
bool __leq(final num x, final num y) => x <= y;
bool __eq(final num x, final num y) => x == y;
bool __neq(final num x, final num y) => x != y;

bool Function(num, num)? resolveIfCallback(final String op){
  if(op == ">"){
    return __g;
  }
  else if(op == "<"){
    return __l;
  }
  else if(op == ">="){
    return __geq;
  }
  else if(op == "<="){
    return __leq;
  }
  else if(["!=", "<>"].contains(op)){
    return __eq;
  }
  else if(["=", "=="].contains(op)){
    return __neq;
  }
  return null;
}

////////////////////////////////////////////////////
///
//////////////////////// F /////////////////////////

enum FilterType{
  // ignore: constant_identifier_names
  INVALID,
  // ignore: constant_identifier_names
  AVG,
  // ignore: constant_identifier_names
  MIN,
  // ignore: constant_identifier_names
  MAX
}

extension FromString on FilterType{
  FilterType? tryParse(final String s){
    switch (s.toUpperCase()) {
      case "AVG":
        return FilterType.AVG;
      case "MIN":
        return FilterType.MIN;
      case "MAX":
        return FilterType.MAX;
      default:
        return null;
    }
  }
}

class Filter{
  final FilterType type;
  final bool isTimeWindow;
  final int elemWindowSize;
  final double msWindowSize;

  const Filter({required this.type, required this.isTimeWindow, required this.elemWindowSize, required this.msWindowSize});

  static Filter? tryParse(final String s){
    FilterType _ = FilterType.INVALID;
    final String filterName = s.substring(1).split(RegExp(r'[0-9]'))[0];
    final FilterType? type = _.tryParse(filterName);
    if(type == null){
      return null;
    }

    final String filterData = s.substring(1 + filterName.length).toUpperCase();
    final int? maybeElemWindowSize = int.tryParse(filterData);
    if(maybeElemWindowSize != null){
      if(maybeElemWindowSize == 0){
        return null;
      }
      return Filter(type: type, isTimeWindow: false, elemWindowSize: maybeElemWindowSize, msWindowSize: 0);
    }

    late final String timeWindowSizeStr;
    if(filterData.endsWith('S')){
      timeWindowSizeStr = filterData.substring(0, filterData.length - 1);
    }
    else if(filterData.endsWith('SEC')){
      timeWindowSizeStr = filterData.substring(0, filterData.length - 3);
    }
    else{
      return null;
    }
    
    final double? maybeTimeWindowSize = double.tryParse(timeWindowSizeStr);
    if(maybeTimeWindowSize == null || maybeTimeWindowSize == 0){
      return null;
    }
    return Filter(type: type, isTimeWindow: true, elemWindowSize: 0, msWindowSize: maybeTimeWindowSize * 1000);
  }

  void apply(final TypedDataListContainer<TypedData> values, final TypedDataListContainer<TypedData> timestamps, final void Function(num) onNewValue){
    if(isTimeWindow){
      _applyOnTimeWindow(values, timestamps, onNewValue);
    }
    else{
      _applyOnElemWindow(values, onNewValue);
    }
  }

  num _calcWindow(final List<double> window){
    switch (type) {
      case FilterType.AVG:
        return window.fold(0.0, (p, e) => p + e) / window.length;
      case FilterType.MIN:
        return window.fold(double.infinity, (p, e) => min(p, e));
      case FilterType.MAX:
        return window.fold(double.negativeInfinity, (p, e) => max(p, e));
      default:
        localLogger.error("Not implemented window calculation for FilterType.${type.name}");
        return 0;
    }
  }

  void _applyOnTimeWindow(final TypedDataListContainer<TypedData> values, final TypedDataListContainer<TypedData> timestamps, final void Function(num) onNewValue){
    int start = 0;
    int end = 0;

    for(int i = 0; i < values.size; i++){
      final int currentTime = timestamps[i] as int;
      while(timestamps[start] < currentTime - msWindowSize / 2){
        start++;
      }

      while(timestamps[end] < currentTime + msWindowSize / 2){
        end++;
        if(end >= timestamps.size){
          end--;
          break;
        }
      }

      final List<double> window = [];
      for(int j = start; j < end; j++){
        window.add(values[j].toDouble());
      }
      if(start == end){
        window.add(values[start].toDouble());
      }
      onNewValue(_calcWindow(window));
    }
  }

  void _applyOnElemWindow(final TypedDataListContainer<TypedData> values, final void Function(num) onNewValue){
    for(int i = 0; i < values.size; i++){
      final int start = max(0, i - (elemWindowSize / 2).ceil());
      final int end = min(values.size, i + (elemWindowSize / 2).ceil());
      final List<double> window = [];
      for(int j = start; j < end; j++){
        window.add(values[j].toDouble());
      }
      onNewValue(_calcWindow(window));
    }
  }
}

////////////////////////////////////////////////////