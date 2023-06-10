import 'package:flutter/material.dart';

import 'cursor_displays.dart';

const double cursorDisplayHeight = 25;

class ChartArea extends StatefulWidget {
  const ChartArea({super.key});

  @override
  State<ChartArea> createState() => _ChartAreaState();
}

class _ChartAreaState extends State<ChartArea> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CursorDisplay(),
        Expanded(child: _ChartGestureArea()),
      ],
    );
  }
}

class _ChartGestureArea extends StatefulWidget {
  const _ChartGestureArea();

  @override
  State<_ChartGestureArea> createState() => __ChartGestureAreaState();
}

class __ChartGestureAreaState extends State<_ChartGestureArea> {

  List<int> cursorPositions = [100, 300];
  bool isDelta = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ChartLinePainter(),),
          for(int timeStamp in cursorPositions)
            Positioned(right: timeStamp.toDouble(), child: const Cursor()),
          for(int timeStamp in cursorPositions)
            Positioned(right: timeStamp.toDouble(), child: CursorTooltip(isDelta: isDelta,))
        ],
      ),
    );
  }
}

class _ChartLinePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), Paint()..style = PaintingStyle.fill..color = Colors.red);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}