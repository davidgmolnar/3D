import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/lapdata.dart';
import '../charts/cursor_displays.dart';
import '../input_widgets/sliders.dart';
import '../theme/theme.dart';

class LapDataDialog extends StatefulWidget {
  const LapDataDialog({super.key});

  @override
  State<LapDataDialog> createState() => _LapDataDialogState();
}

class _LapDataDialogState extends State<LapDataDialog> {
  List<bool> selectedCursors = [];
  bool showLaps = false;

  @override
  void initState() {
    selectedCursors = List.filled(cursorInfoNotifier.value.cursors.length, false);
    cursorInfoNotifier.addListener(onCursorUpdate);
    super.initState();
  }

  void onCursorUpdate(){
    selectedCursors = List.filled(cursorInfoNotifier.value.cursors.length, false);
    setState(() {});
  }

  void update(){
    setState(() {});
  }

  void moveSelectedToLapData(){
    for(int i = 0; i < selectedCursors.length; i++){
      if(selectedCursors[i]){
        LapData.add(cursorInfoNotifier.value.cursors[i].timeStamp);
      }
    }
    selectedCursors = List.filled(cursorInfoNotifier.value.cursors.length, false);
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
              itemCount: selectedCursors.length,
              cacheExtent: 200,
              itemBuilder: (context, index) {
                return TextButton(
                  onPressed: () {
                    selectedCursors[index] = !selectedCursors[index];
                    update();
                  },
                  child: Text(
                    cursorInfoNotifier.value.cursors[index].represent(index),
                    style: StyleManager.textStyle.copyWith(
                      color: selectedCursors[index] ? StyleManager.globalStyle.primaryColor : StyleManager.globalStyle.secondaryColor
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
                            style: StyleManager.textStyle.copyWith(
                              color: selectedCursors[index] ? StyleManager.globalStyle.primaryColor : StyleManager.globalStyle.secondaryColor
                            ),
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
    cursorInfoNotifier.removeListener(onCursorUpdate);
    super.dispose();
  }
}