import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../data/signal_container.dart';
import 'chart_logic/chart_controller.dart';
import 'cursor_displays.dart';

const double cursorDisplayHeight = 25;

class ScalingInfo{
  final int timeDuration;
  final int timeOffset;
  final double valueRange;
  final double valueOffset;

  ScalingInfo({
    required this.timeDuration,
    required this.timeOffset,
    required this.valueRange,
    required this.valueOffset
  });

  bool timeDataChanged(ScalingInfo other) => other.timeDuration != timeDuration || other.timeOffset != timeOffset;
  bool valueDataChanged(ScalingInfo other) => other.valueRange != valueRange || other.valueOffset != valueOffset;
  ChartShowDuration get timedata => ChartShowDuration(timeDuration: timeDuration, timeOffset: timeOffset);
}

class _PlotContext{
  ScalingInfo scalingInfo;
  SignalContainer signalContainer;
  bool hadChange;
  List<Offset> scaledChartLine;
  Color color;

  _PlotContext({
    required this.scalingInfo,
    required this.signalContainer,
    required this.hadChange,
    required this.scaledChartLine,
    required this.color
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
          final ScalingInfo actualScalingInfo = ChartController.scalingFor(measurement, signal);
          if(dataSeen[measurement]![signal]!.scalingInfo.timeDataChanged(actualScalingInfo)){
            dataSeen[measurement]![signal]!.signalContainer.updateSignalContainer(actualScalingInfo.timedata, dataSeen[measurement]![signal]!.scalingInfo.timedata);
            // calc points from actualScalingInfo and chart area size
            dataSeen[measurement]![signal]!.scalingInfo = actualScalingInfo;
            dataSeen[measurement]![signal]!.hadChange = true;
          }
          else if(dataSeen[measurement]![signal]!.scalingInfo.valueDataChanged(actualScalingInfo)){
            // calc points from actualScalingInfo and chart area size
            dataSeen[measurement]![signal]!.scalingInfo = actualScalingInfo;
            dataSeen[measurement]![signal]!.hadChange = true;
          }
          dataSeen[measurement]![signal]!.color = TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).color;
        }
        else{
          dataSeen[measurement]![signal] = _PlotContext(
            scalingInfo: ChartController.scalingFor(measurement, signal),
            signalContainer: SignalContainer.create(ChartController.shownDurationNotifier.value),
            hadChange: true,
            scaledChartLine: [],
            color: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).color
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

  static final Paint _chartLinePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;

  _ChartLinePainter({
    required this.plotContext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    bool first = true;
    Path path = Path();
    for(Offset point in plotContext.scaledChartLine){
      if(first){
        canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
        path.moveTo(point.dx, point.dy);
        first = false;
        continue;
      }
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, _chartLinePaint..color = plotContext.color);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return plotContext.hadChange;
  }
}