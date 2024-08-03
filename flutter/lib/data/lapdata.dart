import 'package:flutter/material.dart';

import '../io/fscache.dart';
import '../ui/charts/chart_logic/chart_controller.dart';
import '../ui/theme/theme.dart';
import 'custom_notifiers.dart';
import 'data.dart';

final UpdateableValueNotifier<List<double>> placedLapMarkers = UpdateableValueNotifier<List<double>>([]);

const double lapMarkerHorizontalDragBuffer = 2; // setting,

class LapMarkersOverlay extends StatefulWidget {
  const LapMarkersOverlay({super.key});

  @override
  State<LapMarkersOverlay> createState() => _LapMarkersOverlayState();
}

class _LapMarkersOverlayState extends State<LapMarkersOverlay> {

  @override
  void initState() {
    placedLapMarkers.addListener(update);
    ChartController.shownDurationNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for(int i = 0; i < placedLapMarkers.value.length; i++)
          LapMarkerTooltip(lapMarkerIndex: i, pos: ChartController.timeStampToPosition(placedLapMarkers.value[i]),),
        for(int i = 0; i < placedLapMarkers.value.length; i++)
          LapMarker(lapMarkerIndex: i, pos: ChartController.timeStampToPosition(placedLapMarkers.value[i]),),
      ]);
  }

  @override
  void dispose() {
    placedLapMarkers.removeListener(update);
    ChartController.shownDurationNotifier.removeListener(update);
    super.dispose();
  }
}

class LapMarker extends StatelessWidget {
  const LapMarker({super.key, required this.lapMarkerIndex, required this.pos,});

  final int lapMarkerIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    if(pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: pos,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            placedLapMarkers.update((lapMarkers) {
              lapMarkers[lapMarkerIndex] += ChartController.moveInCursonTime(details.delta.dx);
              LapData.updateTemp(lapMarkerIndex, lapMarkers[lapMarkerIndex]);
            });
          },
          child: SizedBox(
            width: 1 + 2 * lapMarkerHorizontalDragBuffer,
            child: Center(
              child: Container(
                width: 1,
                height: 2000, // inkorrekt de ez van
                color: StyleManager.globalStyle.textColor,
              )
            )
          ),
        ),
      ),
    );
  }
}

class LapMarkerTooltip extends StatelessWidget {
  const LapMarkerTooltip({super.key, required this.lapMarkerIndex, required this.pos});

  final int lapMarkerIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    if(pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: pos! + lapMarkerHorizontalDragBuffer,
      child: Column(
        children: [
          Icon(Icons.flag, color: StyleManager.globalStyle.primaryColor,),
          IconButton(onPressed: (){
            placedLapMarkers.update((value) {
              final double removed = value.removeAt(lapMarkerIndex);
              LapData.removeTemp(removed);
            });
          }, icon: Icon(Icons.close, color: StyleManager.globalStyle.primaryColor,))
        ],
      )
    );
  }
}

abstract class LapData{
  static final Set<double> _lapMarkersMs = {};
  static final List<double> _temporaryLapMarkers = [];

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

  static void addTemp(double lapMarkerMs){
    _temporaryLapMarkers.add(lapMarkerMs);
    _save();
  }

  static void removeTemp(double lapMarkerMs){
    _temporaryLapMarkers.remove(lapMarkerMs);
    _save();
  }

  static void clearTemp(){
    _temporaryLapMarkers.clear();
    _save();
  }

  static void updateTemp(final int index, final double newValue){
    _temporaryLapMarkers[index] = newValue;
    _save();
  }

  static void _save(){
    FSCache.write(FSCache.lapdataPath, _lapMarkersMs.toList());
    FSCache.write(FSCache.tempLapdataPath, _temporaryLapMarkers);
  }

  static void reload(){
    final List<double>? loaded = FSCache.read<List>(FSCache.lapdataPath)?.cast<double>();
    final List<double>? loadedTemp = FSCache.read<List>(FSCache.tempLapdataPath)?.cast<double>();
    if(loaded != null){
      _lapMarkersMs.clear();
      _lapMarkersMs.addAll(loaded);
    }
    if(loadedTemp != null){
      _temporaryLapMarkers.clear();
      _temporaryLapMarkers.addAll(loadedTemp);
    }
  }

  static List<double> lapMarkers(){
    return _lapMarkersMs.toList()..sort();
  }

  static List<double> tempLapMarkers(){
    return _temporaryLapMarkers.toList()..sort();
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