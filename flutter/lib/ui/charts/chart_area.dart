import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ml_linalg/dtype.dart';
import 'package:ml_linalg/vector.dart';

import '../../data/data.dart';
import '../../data/settings.dart';
import '../../io/logger.dart';
import '../../multiprocess/childprocess.dart';
import '../../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../routes/window_type.dart';
import '../theme/theme.dart';
import 'chart_logic/axis_data.dart';
import 'chart_logic/chart_controller.dart';
import 'chart_scaler.dart';
import 'cursor_displays.dart';
import 'top_cursor_panel.dart';

class ScalingInfo{
  final double timeScale;
  final double timeDuration;
  final double timeOffset;
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

  void fillIndexes(final ScalingInfo? old, final String measurement, final String signal){
    if(signalData[measurement]![signal]!.timestamps.first > timeOffset){
      startIndex = 0;
    }
    else if(signalData[measurement]![signal]!.timestamps.last < timeOffset){
      startIndex = signalData[measurement]![signal]!.timestamps.size;
      measCount = 0;
      return;
    }
    else{
      startIndex = binarySearchIndexAtTimeStamp(signalData[measurement]![signal]!.timestamps, timeOffset)!;
    }

    int endIndex;
    if(signalData[measurement]![signal]!.timestamps.last < timeOffset + timeDuration){
      endIndex = signalData[measurement]![signal]!.timestamps.size; //////////
    }
    else if(signalData[measurement]![signal]!.timestamps.first > timeOffset + timeDuration){
      startIndex = signalData[measurement]![signal]!.timestamps.size;
      measCount = 0;
      return;
    }
    else{
      endIndex = binarySearchIndexAtTimeStamp(signalData[measurement]![signal]!.timestamps, timeOffset + timeDuration)!;
    }
    measCount = endIndex - startIndex;
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
  final String measurement;
  final String signal;
  ScalingInfo scalingInfo;
  bool hadChange;
  Vector y = Vector.empty();
  Vector x = Vector.empty();
  Color color;

  _PlotContext({
    required this.measurement,
    required this.signal,
    required this.scalingInfo,
    required this.hadChange,
    required this.color
  });

  void initialScaledPoints(final String measurement, final String signal){
    y = Vector.fromList(signalData[measurement]![signal]!.values.iterable.map((e) => e.toDouble()).toList().cast<double>(), dtype: DType.float32);
    x = Vector.fromList(signalData[measurement]![signal]!.timestamps.iterable.map((e) => e.toDouble()).toList().cast<double>(), dtype: DType.float32);

    y = (y - scalingInfo.valueOffset) * scalingInfo.valueScale;
    x = (x - scalingInfo.timeOffset) * scalingInfo.timeScale;
  }

  void reScalePoints(final ScalingInfo newInfo, final ScalingInfo oldInfo){
    final bool updateTime = newInfo.timeDataChanged(oldInfo);
    final bool updateValue = newInfo.valueDataChanged(oldInfo);

    final double timeMult = newInfo.timeScale / oldInfo.timeScale;
    final double timeOffset = (oldInfo.timeOffset - newInfo.timeOffset) * newInfo.timeScale;
    final double valueMult = newInfo.valueScale / oldInfo.valueScale;
    final double valueOffset = (oldInfo.valueOffset - newInfo.valueOffset) * newInfo.valueScale;

    if(updateTime){
      x = x * timeMult + timeOffset;
    }
    if(updateValue){
      y = y * valueMult + valueOffset;
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
            measurement: measurement,
            signal: signal,
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
        onVerticalDragUpdate: (details) {
          if(details.delta.dy.abs() < details.delta.dx.abs()){
            ChartController.moveInTime = details.primaryDelta ?? 0;
          }
          else{
            ChartController.zoomInTime = details.delta.distance * details.delta.dy.sign * -1;
          }
        },
        onHorizontalDragUpdate: (details) {
          if(details.delta.dy.abs() < details.delta.dx.abs()){
            ChartController.moveInTime = details.primaryDelta ?? 0;
          }
          else{
            ChartController.zoomInTime = details.delta.distance * details.delta.dy.sign * -1;
          }
        },
        onSecondaryTapDown: (details) async {
          final Map<String, List<String>> visibility = dataSeen.map((key, value) => MapEntry(key, value.keys.toList()));
          final double timeStamp = ChartController.positionToTimeStamp(details.localPosition.dx);
          final Map<String, Map<String, num>> values = cursorDataAtTimeStamp(timeStamp, visibility);
          cursorInfoNotifier.update((cursorInfo) {
            cursorInfo.cursors.add(CursorData.fromCurrent(timeStamp, values));
          });
          if(windowType == WindowType.CUSTOM_CHART && customChartWindowType == CustomChartWindowType.GRID && isInSharingGroup){
            ChildProcess.sendCustomChartUpdate(setCustomChartMarkerAddPayload(timeStamp));
          }
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
  void paint(final Canvas canvas, final Size size) {
    final Paint paint = _chartLinePaint..color = plotContext.color;
    final int end = min(plotContext.scalingInfo.startIndex + plotContext.scalingInfo.measCount + 2, plotContext.x.length);
    final int increment = max((end - plotContext.scalingInfo.startIndex) ~/ 100000, 1);
    final ChartDrawMode drawMode = ChartController.drawModesNotifier.value.getMode(plotContext.measurement, plotContext.signal);
    
    if(drawMode == ChartDrawMode.LINE){
      Path path = Path();
      for(int i = max(plotContext.scalingInfo.startIndex - 1, 0); i < end; i += increment){
        if(i == max(plotContext.scalingInfo.startIndex - 1, 0)){
          canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
          canvas.scale(1,-1); // ezt PlotContext.reScalePoints és initialScaledPointsban kéne csinálni meg a kövit is
          canvas.translate(0, -size.height);
          path.moveTo(plotContext.x[i], plotContext.y[i]);
          continue;
        }
        try{
          path.lineTo(plotContext.x[i], plotContext.y[i]);
        } on RangeError{
          localLogger.warning("ChartLinePainter detected miscalculated scalinginfo", doNoti: false);
          break;
        }
      }
      canvas.drawPath(path, paint);
    }
    else if(drawMode == ChartDrawMode.SCATTER){
      final Paint pointPaint = _chartLinePaint..strokeCap = StrokeCap.round;
      List<Offset> points = [];
      for(int i = plotContext.scalingInfo.startIndex; i < end; i += increment){
        if(i == plotContext.scalingInfo.startIndex){
          canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
          canvas.scale(1,-1); // ezt PlotContext.reScalePoints és initialScaledPointsban kéne csinálni meg a kövit is
          canvas.translate(0, -size.height);
          continue;
        }
        try{
          points.add(Offset(plotContext.x[i], plotContext.y[i]));
        } on RangeError{
          localLogger.warning("ChartLinePainter detected miscalculated scalinginfo", doNoti: false);
          break;
        }
      }
      canvas.drawPoints(PointMode.points, points, pointPaint);
    }
    else{
      localLogger.error("Not implemented chart painting for chartDrawMode ${drawMode.name}", doNoti: false);
    }
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
        text: msToTimeString(label, addMs: valueAxisData.majorTickValues.length > 1 && valueAxisData.majorTickValues[1] - valueAxisData.majorTickValues[0] < 1000),
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