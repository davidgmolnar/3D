import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/lapdata.dart';
import '../input_widgets/sliders.dart';
import '../theme/theme.dart';

class LapDataDialog extends StatefulWidget {
  const LapDataDialog({super.key});

  @override
  State<LapDataDialog> createState() => _LapDataDialogState();
}

class _LapDataDialogState extends State<LapDataDialog> {
  List<bool> selectedTempLapMarkers = [];
  List<double> tempLapMarkers = [];
  bool showLaps = false;

  @override
  void initState() {
    LapData.notifier.addListener(onCacheUpdate);
    LapData.reload();
    tempLapMarkers = LapData.tempLapMarkers();
    selectedTempLapMarkers = List.filled(tempLapMarkers.length, false);
    super.initState();
  }

  void onCacheUpdate(){
    LapData.reload();
    tempLapMarkers = LapData.tempLapMarkers();
    selectedTempLapMarkers = List.filled(tempLapMarkers.length, false);
    update();
  }

  void update(){
    setState(() {});
  }

  void moveSelectedToLapData(){
    for(int i = 0; i < selectedTempLapMarkers.length; i++){
      if(selectedTempLapMarkers[i]){
        LapData.add(tempLapMarkers[i]);
      }
    }
    for(int i = selectedTempLapMarkers.length - 1; i >= 0; i--){
      if(selectedTempLapMarkers[i]){
        LapData.removeTemp(tempLapMarkers[i]);
      }
    }
    selectedTempLapMarkers = List.filled(tempLapMarkers.length, false);
    update();
  }

  @override
  Widget build(BuildContext context) {
    final List<double> lapMarkers = LapData.lapMarkers();
    final List<Offset> laps = LapData.laps();
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemExtent: 50,
              itemCount: selectedTempLapMarkers.length,
              cacheExtent: 200,
              itemBuilder: (context, index) {
                return TextButton(
                  onPressed: () {
                    selectedTempLapMarkers[index] = !selectedTempLapMarkers[index];
                    update();
                  },
                  child: Text(
                    "Temp lap marker $index: ${msToTimeString(tempLapMarkers[index], addMs: true)}",
                    style: StyleManager.textStyle.copyWith(
                      color: selectedTempLapMarkers[index] ? StyleManager.globalStyle.primaryColor : StyleManager.globalStyle.secondaryColor
                    ),
                  ),
                );
              },
            )
          ),
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: StyleManager.globalStyle.secondaryColor,
              border: Border.symmetric(vertical: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: moveSelectedToLapData,
                  icon: Icon(Icons.keyboard_arrow_right, color: StyleManager.globalStyle.primaryColor,)
                )
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SlidingSwitch(
                  labels: const ["Lap markers", "Laps"],
                  active: "Lap markers",
                  elementWidth: 150,
                  onChanged: (final String selected){
                    showLaps = selected == "Laps";
                    update();
                  }
                ),
                showLaps ? 
                  Expanded(
                    child: ListView.builder(
                      itemExtent: 50,
                      itemCount: laps.length,
                      cacheExtent: 200,
                      itemBuilder:(context, index) {
                        return TextButton(
                          onPressed: () {
                            LapData.remove(laps[index].dx);
                            LapData.remove(laps[index].dy);
                            update();
                          },
                          child: Text(
                            "Lap $index: ${msToTimeString(laps[index].dx, addMs: true)} - ${msToTimeString(laps[index].dy, addMs: true)}",
                            style: StyleManager.textStyle
                          ),
                        );
                      },
                    ),
                  )
                  :
                  Expanded(
                    child: ListView.builder(
                      itemExtent: 50,
                      itemCount: lapMarkers.length,
                      cacheExtent: 200,
                      itemBuilder:(context, index) {
                        return TextButton(
                          onPressed: () {
                            LapData.remove(lapMarkers[index]);
                            update();
                          },
                          child: Text(
                            "Flag $index: ${msToTimeString(lapMarkers[index], addMs: true)}",
                            style: StyleManager.textStyle
                          ),
                        );
                      },
                    ),
                  )
              ]
            )
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LapData.notifier.removeListener(onCacheUpdate);
    super.dispose();
  }
}