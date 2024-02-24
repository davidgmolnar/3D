import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/settings.dart';
import '../theme/theme.dart';
import 'chart_logic/axis_data.dart';
import 'chart_logic/chart_controller.dart';
import 'chart_scaler.dart';
import 'cursor_displays.dart';
import 'top_cursor_panel.dart';

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
    final bool updateTime = newInfo.timeDataChanged(oldInfo);
    final bool updateValue = newInfo.valueDataChanged(oldInfo);

    final double timeMult = newInfo.timeScale / oldInfo.timeScale;
    final double timeOffset = (oldInfo.timeOffset - newInfo.timeOffset) * newInfo.timeScale;
    final double valueMult = newInfo.valueScale / oldInfo.valueScale;
    final double valueOffset = (oldInfo.valueOffset - newInfo.valueOffset) * newInfo.valueScale;
    for(int i = 0; i < scaledChartLine.length; i++){
      if(updateTime){
        //scaledChartLine[i].x = (scaledChartLine[i].x / oldInfo.timeScale + oldInfo.timeOffset - newInfo.timeOffset) * newInfo.timeScale;
        scaledChartLine[i].x = scaledChartLine[i].x * timeMult + timeOffset;
        //scaledChartLine[i].x *= timeMult;
        //scaledChartLine[i].x += timeOffset;
      }
      if(updateValue){
        //scaledChartLine[i].y = (scaledChartLine[i].y / oldInfo.valueScale + oldInfo.valueOffset - newInfo.valueOffset) * newInfo.valueScale;
        scaledChartLine[i].y = scaledChartLine[i].y * valueMult + valueOffset;
        //scaledChartLine[i].y *= valueMult;
        //scaledChartLine[i].y += valueOffset;
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
    return const Column(
      children: [
        TopCursorDisplay(),
        Expanded(
          child: Row(
            children: [
              ChartScalerContainer(),
              Expanded(child: _ChartGestureArea()),
            ],
          ),
        ),
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
  late ValueAxisData valueAxisData;
  
  @override
  void initState() {
    valueAxisData = ValueAxisData.from(ChartController.shownDurationNotifier.value.timeOffset, ChartController.shownDurationNotifier.value.timeDuration, ChartController.chartWidth, null);
    ChartController.shownDurationNotifier.addListener(update);
    ChartController.shownDurationNotifier.addListener(updateTimeAxis);
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void updateTimeAxis(){
    valueAxisData = ValueAxisData.from(ChartController.shownDurationNotifier.value.timeOffset, ChartController.shownDurationNotifier.value.timeDuration, ChartController.chartWidth, null);
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
    cursorInfoNotifier.value.visibility = dataSeen.map((key, value) => MapEntry(key, value.keys.toList()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        onSecondaryTapDown: (details) async {
          final Map<String, List<String>> visibility = dataSeen.map((key, value) => MapEntry(key, value.keys.toList()));
          final int timeStamp = ChartController.positionToTimeStamp(details.localPosition.dx);
          final Map<String, Map<String, num>> values = cursorDataAtTimeStamp(timeStamp, visibility);
          cursorInfoNotifier.update((cursorInfo) {
            cursorInfo.cursors.add(CursorData.fromCurrent(timeStamp, values));
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for(String meas in dataSeen.keys)
              for(String signal in dataSeen[meas]!.keys)
                CustomPaint(painter: _ChartLinePainter(plotContext: dataSeen[meas]![signal]!),),
            Transform.translate(
              offset: Offset(0, ChartController.chartHeigth - 20),
              child: Container(
                height: 20,
                decoration: BoxDecoration(border: Border(top: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))),
                child: CustomPaint(painter: TimeAxisPainter(valueAxisData: valueAxisData),)
              ),
            ),
            const CursorOverlay()
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    ChartController.shownDurationNotifier.removeListener(updateTimeAxis);
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

class TimeAxisPainter extends CustomPainter{

  final ValueAxisData valueAxisData;

  TimeAxisPainter({required this.valueAxisData});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    final TextPainter textPainterBase = TextPainter(
      text: TextSpan(
        text: "DEFAULT TEXT",
        style: StyleManager.textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    final Paint paintBase = Paint()..color = StyleManager.globalStyle.primaryColor;

    int i = 0;
    for(final num label in valueAxisData.majorTickValues){
      final TextPainter tp = textPainterBase..text = TextSpan(
        text: label.toString(),
        style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
      );
      tp.layout();
      final Offset majorPos = Offset(valueAxisData.majorTickPositions[i] - StyleManager.globalStyle.padding, 0);
      tp.paint(canvas, majorPos.translate(-tp.width / 2, 0));
      i++;

      canvas.drawLine(majorPos, majorPos.translate(0, tickLenght.toDouble()), paintBase);
    }

    for(final double tickPos in valueAxisData.tickPositions){
      final Offset pos = Offset(tickPos - StyleManager.globalStyle.padding, 0);
      canvas.drawLine(pos, pos.translate(0, tickLenght.toDouble()), paintBase);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}