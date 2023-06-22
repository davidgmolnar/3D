import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../data/signal_container.dart';
import 'chart_logic/chart_controller.dart';
import 'cursor_displays.dart';

const double cursorDisplayHeight = 25;

// TODO ez már legyen chartarea méretre skálázva, és a Chartcontroller is tudjon méretről, ChartController::scalingFor is úgy számoljon
class ScalingInfo{
  final int duration;
  final double spanY;
  final double offsetY;

  ScalingInfo({
    required this.duration,
    required this.spanY,
    required this.offsetY
  });
}

class _PlotContext{
  ScalingInfo scalingInfo;
  SignalContainer signalContainer;
  bool hadChange;

  _PlotContext({
    required this.scalingInfo,
    required this.signalContainer,
    required this.hadChange
  });
}

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
  Map<String, Map<String, _PlotContext>> dataSeen = {};
  // listen to TraceSettingProvider changes
  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update);
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void update(){
    // reset hadchange
    dataSeen.forEach((key, value) {
      value.forEach((key, value) {
        value.hadChange = false;
      });
    },);
    
    final Map<String, List<String>> visibleSignals = TraceSettingsProvider.visibleSignals;
    // delete thats not visible anymore
    for(String measurement in dataSeen.keys){
      if(!visibleSignals.containsKey(measurement)){
        dataSeen.remove(measurement);
        continue;
      }
      for(String signal in dataSeen[measurement]!.keys){
        if(!visibleSignals[measurement]!.contains(signal)){
          dataSeen[measurement]!.remove(signal);
        }
      }
    }
    // add new data to all in visibleSignals
    for(String measurement in visibleSignals.keys){
      dataSeen[measurement] ??= {};
      for(String signal in visibleSignals[measurement]!){
        if(dataSeen[measurement]!.containsKey(signal)){
          if(dataSeen[measurement]![signal]!.signalContainer.updateSignalContainer(ChartController.shownDurationNotifier.value)){
            dataSeen[measurement]![signal]!.hadChange = true;
          }
          else if(dataSeen[measurement]![signal]!.scalingInfo != ChartController.scalingFor(measurement, signal)){
            dataSeen[measurement]![signal]!.scalingInfo = ChartController.scalingFor(measurement, signal);
            dataSeen[measurement]![signal]!.hadChange = true;
          }
        }
        else{
          dataSeen[measurement]![signal] = _PlotContext(
            scalingInfo: ChartController.scalingFor(measurement, signal),
            signalContainer: SignalContainer.create(ChartController.shownDurationNotifier.value),
            hadChange: true
          );
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if(event is PointerScrollEvent){
          print('onPointerSignal ${event.scrollDelta.dy}');
          ChartController.zoomInTime = event.scrollDelta.dy;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          print('onHorizontalDragUpdate ${details.primaryDelta}');
          ChartController.moveInTime = details.primaryDelta ?? 0;
        },
        onSecondaryTapDown: (details) {
          print('onSecondaryTapDown ${details.localPosition.dx}');
          cursorInfoNotifier.update((cursorInfo) {
            // position to timestamp calc
            cursorInfo.timeStamps.add(details.localPosition.dx.toInt());
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for(String meas in dataSeen.keys)
              for(String signal in dataSeen[meas]!.keys)
                CustomPaint(painter: _ChartLinePainter(plotContext: dataSeen[meas]![signal]!),),
            // time axis
            const CursorOverlay()
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

  final _PlotContext plotContext;

  _ChartLinePainter({
    required this.plotContext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), Paint()..style = PaintingStyle.fill..color = Colors.red);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return plotContext.hadChange;
  }
}