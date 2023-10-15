import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/updateable_valuenotifier.dart';
import '../input_widgets/buttons.dart';
import '../theme/theme.dart';
import 'chart_area.dart';
import 'chart_logic/chart_controller.dart';

const double cursorHorizontalDragBuffer = 2; // setting,

class CursorData{
  int timeStamp;
  Map<String, Map<String, num>> values;
  bool isDelta;
  int? deltaTarget;

  CursorData({
    required this.timeStamp,
    required this.values,
    required this.isDelta,
    required this.deltaTarget,
  });

  factory CursorData.fromCurrent(final int timeStamp, final Map<String, Map<String, num>> values){
    return CursorData(timeStamp: timeStamp, values: values, isDelta: false, deltaTarget: null);
  }
}

class CursorInfo{
  final List<CursorData> cursors = [];
  Map<String, List<String>> visibility = {};

  int get countDeltas => cursors.fold(0, (previousValue, cursor) => previousValue + (cursor.isDelta ? 1 : 0));

  int get countAbsolutes => cursors.fold(0, (previousValue, cursor) => previousValue + (cursor.isDelta ? 0 : 1));
}

final UpdateableValueNotifier<CursorInfo> cursorInfoNotifier = UpdateableValueNotifier<CursorInfo>(CursorInfo());


class CursorDisplay extends StatefulWidget {
  const CursorDisplay({super.key});


  @override
  State<CursorDisplay> createState() => _CursorDisplayState();
}

class _CursorDisplayState extends State<CursorDisplay> {

  @override
  void initState() {
    cursorInfoNotifier.addListener(update);
    super.initState();
  }

  void update(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Global cursor data + cursor functions (Peak search/Next Peak etc)
    return Container(height: cursorDisplayHeight, color: Colors.grey,);
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    super.dispose();
  }
}


class CursorTooltip extends StatefulWidget {
  const CursorTooltip({super.key, required this.cursorIndex, required this.pos});

  final int cursorIndex;
  final double? pos;

  @override
  State<CursorTooltip> createState() => _CursorTooltipState();
}

class _CursorTooltipState extends State<CursorTooltip> {
  @override
  Widget build(BuildContext context) {
    // értékek, ha nem delta, egyébként érték különbségek mindenkire,
    // x gomb delete cursor
    if(widget.pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: widget.pos! + cursorHorizontalDragBuffer,
      child: Container(
        width: 200,
        color: StyleManager.globalStyle.secondaryColor.withOpacity(0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("${cursorInfoNotifier.value.cursors[widget.cursorIndex].isDelta ? "D" : "M"}${widget.cursorIndex}"),
                ButtonWithTwoText(
                  key: UniqueKey(),
                  isInitiallyActive: cursorInfoNotifier.value.cursors[widget.cursorIndex].isDelta,
                  textWhenActive: "Delta Marker",
                  textWhenInactive: "Abs Marker",
                  onPressed: (p0) {
                    cursorInfoNotifier.update((value) {
                      if(cursorInfoNotifier.value.cursors[widget.cursorIndex].isDelta){
                        value.cursors[widget.cursorIndex].isDelta = !value.cursors[widget.cursorIndex].isDelta;
                      }
                      else{
                        final bool wouldBeTheLast = cursorInfoNotifier.value.countAbsolutes == 1;
                        if(!wouldBeTheLast){
                          value.cursors[widget.cursorIndex].isDelta = !value.cursors[widget.cursorIndex].isDelta;
                        }
                      }
                    });
                  },
                ),
                IconButton(
                  onPressed: (){
                    cursorInfoNotifier.update((value) {
                      final bool flipOneDelta = cursorInfoNotifier.value.countAbsolutes == 1 && !value.cursors[widget.cursorIndex].isDelta && value.cursors.length > 1;
                      value.cursors.removeAt(widget.cursorIndex);
                      if(flipOneDelta){
                        value.cursors.firstWhere((cursor) => cursor.isDelta).isDelta = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  splashRadius: 20,
                )
              ],
            ),
            Text(cursorInfoNotifier.value.cursors[widget.cursorIndex].values.toString())
            // TODO ha egy meas van akkor nincs, de egyébként ilyen meas headerek alatt legyenek a signalok
            // TODO Textcolor legyen a scalinggroup color
          ]
        ),
      )
    );
  }
}

class Cursor extends StatelessWidget {
  const Cursor({super.key, required this.cursorIndex, required this.pos,});

  final int cursorIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    // ez painteres line ha absolute marker, dotted ha delta marker
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
            cursorInfoNotifier.update((cursorInfo) {
              cursorInfo.cursors[cursorIndex].timeStamp += ChartController.moveInCursonTime(details.delta.dx);
              cursorInfo.cursors[cursorIndex].values = cursorDataAtTimeStamp(cursorInfo.cursors[cursorIndex].timeStamp, cursorInfo.visibility);
            });
          },
          child: SizedBox(
            width: 1 + 2 * cursorHorizontalDragBuffer,
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

class CursorOverlay extends StatefulWidget {
  const CursorOverlay({super.key});

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {

  @override
  void initState() {
    cursorInfoNotifier.addListener(update);
    ChartController.shownDurationNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for(int i = 0; i < cursorInfoNotifier.value.cursors.length; i++)
          Cursor(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.cursors[i].timeStamp),),
        for(int i = 0; i < cursorInfoNotifier.value.cursors.length; i++)
          CursorTooltip(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.cursors[i].timeStamp),),
      ]);
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    ChartController.shownDurationNotifier.removeListener(update);
    super.dispose();
  }
}