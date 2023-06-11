import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'chart_area.dart';

const double cursorHorizontalDragBuffer = 2; // setting,

class CursorInfo{
  List<int> timeStamps = [100];
  List<num> values = [];
  List<bool> isDelta = [];
}

CursorInfo cursorInfo = CursorInfo();
ValueNotifier _cursorUpdateNotifier = ValueNotifier(cursorInfo);


class CursorDisplay extends StatefulWidget {
  const CursorDisplay({super.key});


  @override
  State<CursorDisplay> createState() => _CursorDisplayState();
}

class _CursorDisplayState extends State<CursorDisplay> {

  @override
  void initState() {
    _cursorUpdateNotifier.addListener(update);
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
    _cursorUpdateNotifier.removeListener(update);
    super.dispose();
  }
}


class CursorTooltip extends StatelessWidget {
  const CursorTooltip({super.key, required this.cursorIndex, required this.gestureAreaUpdater});

  final int cursorIndex;
  final Function gestureAreaUpdater;

  @override
  Widget build(BuildContext context) {
    // hogy ez delta-e az a cursorInfoból jön ki
    // értékek, ha nem delta, egyébként érték különbségek mindenkire,
    // tetején gomb, change to/from delta
    // első kurzor nem lehet delta, többi igen
    // x gomb delete cursor
    return Container(width: 50, height: 50, color: Colors.green,);
  }
}

class Cursor extends StatelessWidget {
  const Cursor({super.key, required this.cursorIndex, required this.gestureAreaUpdater});

  final int cursorIndex;
  final Function gestureAreaUpdater;

  @override
  Widget build(BuildContext context) {
    // ez painteres line ha absolute marker, dotted ha delta marker
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          cursorInfo.timeStamps[cursorIndex] += details.delta.dx.toInt();
          gestureAreaUpdater();
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
    );
  }
}