import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/settings.dart';
import 'chart_logic/chart_controller.dart';
import 'cursor_displays.dart';

const double cursorDisplayHeight = 25;

class ScalingInfo{
  final double timeScale;
  final int timeDuration;
  final int timeOffset;
  final double valueScale;
  final double valueRange;
  final double valueOffset;
  int startIndex;
  int measCount;

  ScalingInfo({
    required this.timeScale,
    required this.timeDuration,
    required this.timeOffset,
    required this.valueScale,
    required this.valueRange,
    required this.valueOffset,
    required this.startIndex,
    required this.measCount,
  });

  void fillIndexes(ScalingInfo? old, String measurement, String signal){
    //if(old == null){
    startIndex = signalData[measurement]![signal]!.values.indexWhere((meas) => meas.timeStamp >= timeOffset);
    if(startIndex == -1){
      startIndex = signalData[measurement]![signal]!.values.length;
    }
    // measCount = signalData[measurement]![signal]!.values.skip(startIndex).toList(growable: false).indexWhere((meas) => meas.timeStamp >= timeOffset + timeDuration);
    measCount = signalData[measurement]![signal]!.values.skip(startIndex).takeWhile((meas) => meas.timeStamp <= timeOffset + timeDuration).length;
    return;
    /*} // TODO ez azért kéne
    final int len = signalData[measurement]![signal]!.values.length;

    if(old.timeOffset < timeOffset){
      // startIndex = signalData[measurement]![signal]!.values.skip(old.startIndex).toList(growable: false).indexWhere((meas) => meas.timeStamp >= timeOffset) + old.startIndex;
      startIndex = signalData[measurement]![signal]!.values.skip(old.startIndex).takeWhile((meas) => meas.timeStamp <= timeOffset).length + old.startIndex;
    }
    else if(old.timeOffset > timeOffset){
      startIndex = signalData[measurement]![signal]!.values.reversed.skip(len - old.startIndex).toList(growable: false).reversed.toList(growable: false)
        .indexWhere((meas) => meas.timeStamp >= timeOffset);
    }
    else{
      startIndex = old.startIndex;
    }

    final int oldEnd = old.timeOffset + old.timeDuration;
    final int end = timeOffset + timeDuration;

    if(oldEnd < end){
      // measCount = signalData[measurement]![signal]!.values.skip(old.startIndex).toList(growable: false).indexWhere((meas) => meas.timeStamp >= end);
      measCount = signalData[measurement]![signal]!.values.skip(old.startIndex + old.measCount).takeWhile((meas) => meas.timeStamp <= end).length + old.measCount - startIndex;
    }
    else if(oldEnd > end){
      measCount = signalData[measurement]![signal]!.values.reversed.skip(len - old.startIndex + old.measCount).toList(growable: false).reversed.toList(growable: false)
        .indexWhere((meas) => meas.timeStamp >= end) + old.measCount - startIndex;
    }
    else{
      measCount = old.measCount;
    }
    
    if(startIndex == -1){
      startIndex = signalData[measurement]![signal]!.values.length;
    }
    
    if(measCount == -1){
      measCount = 0;
    }*/
  }

  bool timeDataChanged(ScalingInfo other) => other.timeDuration != timeDuration || other.timeOffset != timeOffset || other.timeScale != timeScale;
  bool valueDataChanged(ScalingInfo other) => other.valueRange != valueRange || other.valueOffset != valueOffset || other.valueScale != valueScale;
  ChartShowDuration get timedata => ChartShowDuration(timeDuration: timeDuration, timeOffset: timeOffset);
}

class PlotPoint{
  double x;
  double y;

  PlotPoint({
    required this.x,
    required this.y
  });
}

class _PlotContext{
  ScalingInfo scalingInfo;
  bool hadChange;
  List<PlotPoint> scaledChartLine = [];
  Color color;

  _PlotContext({
    required this.scalingInfo,
    required this.hadChange,
    required this.color
  });

  void initialScaledPoints(String measurement, String signal){
    scaledChartLine = signalData[measurement]![signal]!.values.map((meas) => meas.toPlotPoint(scalingInfo)).toList();
  }

  void reScalePoints(ScalingInfo newInfo, ScalingInfo oldInfo){
    // TODO https://pub.dev/packages/ml_linalg
    // TODO offset cache
    for(int i = 0; i < scaledChartLine.length; i++){
      if(newInfo.timeDataChanged(oldInfo)){
        scaledChartLine[i].x = (scaledChartLine[i].x / oldInfo.timeScale + oldInfo.timeOffset - newInfo.timeOffset) * newInfo.timeScale;
      }
      if(newInfo.valueDataChanged(oldInfo)){
        scaledChartLine[i].y = (scaledChartLine[i].y / oldInfo.valueScale + oldInfo.valueOffset - newInfo.valueOffset) * newInfo.valueScale;
      }
    }
  }
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
    final List<String> measToRemove = [];
    final Map<String, List<String>> measSignalsToRemove = {};
    for(String measurement in dataSeen.keys){
      if(!visibleSignals.containsKey(measurement)){
        measToRemove.add(measurement);
        continue;
      }
      for(String signal in dataSeen[measurement]!.keys){
        if(!visibleSignals[measurement]!.contains(signal)){
          measSignalsToRemove[measurement] ??= [];
          measSignalsToRemove[measurement]!.add(signal);
        }
      }
    }

    for(String meas in measToRemove){
      dataSeen.remove(meas);
    }

    for(String meas in measSignalsToRemove.keys){
      for(String signal in measSignalsToRemove[meas]!){
        dataSeen[meas]!.remove(signal);
      }
    }

    // add new data to all in visibleSignals
    for(String measurement in visibleSignals.keys){
      dataSeen[measurement] ??= {};
      for(String signal in visibleSignals[measurement]!){
        if(dataSeen[measurement]!.containsKey(signal)){
          final ScalingInfo oldScalingInfo = dataSeen[measurement]![signal]!.scalingInfo;
          final ScalingInfo actualScalingInfo = ChartController.scalingFor(measurement, signal);
          if(oldScalingInfo.timeDataChanged(actualScalingInfo)){
            actualScalingInfo.fillIndexes(oldScalingInfo, measurement, signal);
            dataSeen[measurement]![signal]!.reScalePoints(actualScalingInfo, oldScalingInfo);
            dataSeen[measurement]![signal]!.scalingInfo = actualScalingInfo;
            dataSeen[measurement]![signal]!.hadChange = true;
          }
          if(oldScalingInfo.valueDataChanged(actualScalingInfo)){
            if(dataSeen[measurement]![signal]!.hadChange != true){
              dataSeen[measurement]![signal]!.reScalePoints(actualScalingInfo, oldScalingInfo);
              dataSeen[measurement]![signal]!.scalingInfo = actualScalingInfo..startIndex = oldScalingInfo.startIndex..measCount = oldScalingInfo.measCount;
              dataSeen[measurement]![signal]!.hadChange = true;
            }
          }
          dataSeen[measurement]![signal]!.color = TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).color;
        }
        else{
          dataSeen[measurement]![signal] = _PlotContext(
            scalingInfo: ChartController.scalingFor(measurement, signal)..fillIndexes(null, measurement, signal),
            hadChange: true,
            color: TraceSettingsProvider.traceSettingNotifier.value[measurement]!.firstWhere((element) => element.signal == signal).color
          )..initialScaledPoints(measurement, signal);
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //print(dataSeen['test']!.keys.toList());
    return Listener(
      onPointerSignal: (event) {
        if(event is PointerScrollEvent){
          ChartController.zoomInTime = event.scrollDelta.dy.floorToDouble();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          ChartController.moveInTime = details.primaryDelta ?? 0;
        },
        onSecondaryTapDown: (details) {
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
    Path path = Path();
    final Paint paint = _chartLinePaint..color = plotContext.color;
    final int end = plotContext.scalingInfo.startIndex + plotContext.scalingInfo.measCount;
    for(int i = plotContext.scalingInfo.startIndex; i < end; i++){
      if(i == plotContext.scalingInfo.startIndex){
        canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
        canvas.scale(1,-1); // ezt PlotContext.reScalePoints és initialScaledPointsban kéne csinálni meg a kövit is
        canvas.translate(0, -size.height);
        path.moveTo(plotContext.scaledChartLine[i].x, plotContext.scaledChartLine[i].y);
        continue;
      }
      path.lineTo(plotContext.scaledChartLine[i].x, plotContext.scaledChartLine[i].y);
    }
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}