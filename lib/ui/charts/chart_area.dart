import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/settings.dart';
import 'chart_logic/chart_controller.dart';
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

  // listen to TraceSettingProvider changes
  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update);
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if(event is PointerScrollEvent){
          print('onPointerSignal ${event.scrollDelta.dy}');
          // zoom időben
        }
      },
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          print('onHorizontalDragUpdate ${details.primaryDelta}');
          // húz jobbra balra
        },
        onSecondaryTapDown: (details) {
          // add cursor at position
          // position to timestamp
          print('onSecondaryTapDown ${details.localPosition.dx}');
          cursorInfo.timeStamps.add(details.localPosition.dx.toInt());
          update();
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ChartLinePainter(),),
            // time axis
            for(int i = 0; i < cursorInfo.timeStamps.length; i++)
              Positioned(left: cursorInfo.timeStamps[i].toDouble(), child: Cursor(cursorIndex: i, gestureAreaUpdater: update,)),
            for(int i = 0; i < cursorInfo.timeStamps.length; i++)
              Positioned(left: cursorInfo.timeStamps[i] + cursorHorizontalDragBuffer, child: CursorTooltip(cursorIndex: i, gestureAreaUpdater: update,))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
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