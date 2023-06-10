import 'package:flutter/material.dart';

import 'chart_area.dart';

class CursorInfo{
  List<int> timeStamps = [];
  List<num> values = [];
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
    _cursorUpdateNotifier.addListener(() {update();});
    super.initState();
  }

  void update(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Transparent bg, cursor infos
    return Container(height: cursorDisplayHeight, color: Colors.grey,);
  }
}


class CursorTooltip extends StatelessWidget {
  const CursorTooltip({super.key, required this.isDelta});

  final bool isDelta;

  @override
  Widget build(BuildContext context) {
    return Container(width: 50, height: 50, color: Colors.green,);
  }
}

class Cursor extends StatelessWidget {
  const Cursor({super.key});

  @override
  Widget build(BuildContext context) {
    // lehet ez GestureDetector
    return Container(width: 1, height: 1000, color: Colors.brown,);
  }
}