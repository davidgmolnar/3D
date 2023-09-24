import 'package:flutter/material.dart';

import '../../data/updateable_valuenotifier.dart';
import '../theme/theme.dart';
import 'chart_area.dart';
import 'chart_logic/chart_controller.dart';

const double cursorHorizontalDragBuffer = 2; // setting,

class CursorInfo{
  final List<int> timeStamps = [];
  final Map<String, num> values = {};
  final List<bool> isDelta = [];
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
    // Transparent bg, cursor infos, signal selector hogy melyiken mutatja
    return Container(height: cursorDisplayHeight, color: Colors.grey,);
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    super.dispose();
  }
}


class CursorTooltip extends StatelessWidget {
  const CursorTooltip({super.key, required this.cursorIndex, required this.pos});

  final int cursorIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    // hogy ez delta-e az a cursorInfoból jön ki
    // értékek, ha nem delta, egyébként érték különbségek mindenkire,
    // tetején gomb, change to/from delta
    // első kurzor nem lehet delta, többi igen
    // x gomb delete cursor
    if(pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: pos! + cursorHorizontalDragBuffer,
      child: Container(width: 50, height: 50, color: Colors.green,)
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
              cursorInfo.timeStamps[cursorIndex] += ChartController.moveInCursonTime(details.delta.dx);
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
        // Timestamp to position calc
        for(int i = 0; i < cursorInfoNotifier.value.timeStamps.length; i++)
          Cursor(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.timeStamps[i]),),
        for(int i = 0; i < cursorInfoNotifier.value.timeStamps.length; i++)
          CursorTooltip(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.timeStamps[i]),),
      ]);
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    ChartController.shownDurationNotifier.removeListener(update);
    super.dispose();
  }
}