import 'dart:ui';

import '../io/fscache.dart';
import 'data.dart';

abstract class LapData{
  static final Set<double> _lapMarkersMs = {};

  static void add(double lapMarkerMs){
    _lapMarkersMs.add(lapMarkerMs);
    _save();
  }

  static void remove(double lapMarkerMs){
    _lapMarkersMs.remove(lapMarkerMs);
    _save();
  }

  static void clear(){
    _lapMarkersMs.clear();
    _save();
  }

  static void _save(){
    FSCache.write(FSCache.lapdataPath, _lapMarkersMs.toList());
  }

  static void reload(){
    final List<double>? loaded = FSCache.read<List>(FSCache.lapdataPath)?.cast<double>();
    if(loaded != null){
      _lapMarkersMs.clear();
      _lapMarkersMs.addAll(loaded);
    }
  }

  static List<double> lapMarkers(){
    return _lapMarkersMs.toList()..sort();
  }

  static List<Offset> laps(){
    final List<Offset> laps = [];
    final List<double> lapMarkersMs = _lapMarkersMs.toList()..sort();
    for(int i = 0; i < lapMarkersMs.length - 1; i++){
      laps.add(Offset(lapMarkersMs[i], lapMarkersMs[i + 1]));
    }
    return laps;
  }

  static String rep(final Offset lap, final int index){
    return "Lap ${index + 1}: ${msToTimeString(lap.dx, addMs: true)} - ${msToTimeString(lap.dy, addMs: true)}";
  }
}