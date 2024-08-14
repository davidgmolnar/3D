import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/lapdata.dart';
import '../../data/settings.dart';
import '../../io/fscache.dart';
import '../theme/theme.dart';
import 'chart_logic/chart_controller.dart';
import 'chart_scaler.dart';
import 'cursor_displays.dart';

const double chartBottomOverviewHeight = 100;

class ChartBottomOverview extends StatelessWidget {
  const ChartBottomOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        //ChartController.moveInFullChannelTime = details.primaryDelta ?? 0;
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: chartBottomOverviewHeight,
            width: MediaQuery.of(context).size.width - (TraceSettingsProvider.scalingGroupData.length * chartScalerWidth + 2 * StyleManager.globalStyle.padding + 1),
            child: const Stack(
              fit: StackFit.expand,
              children: [
                ChartBottomOverviewChartLine(),
                ChartBottomOverviewFrame()
              ],
            ),
          ),
        ],
      )
    );
  }
}

class ChartBottomOverviewFrame extends StatefulWidget {
  const ChartBottomOverviewFrame({super.key});

  @override
  State<ChartBottomOverviewFrame> createState() => _ChartBottomOverviewFrameState();
}

class _ChartBottomOverviewFrameState extends State<ChartBottomOverviewFrame> {
  ChartShowDuration? prevShowDuration;
  double? prevFirstVisibleTimestamp;
  double? prevLastVisibleTimestamp;
  List<CursorData>? prevCursors;
  List<double>? prevLaps;
  List<double>? prevTempLaps;

  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update); // to know shownDuration
    TraceSettingsProvider.traceSettingNotifier.addListener(update); // to know visible range
    cursorInfoNotifier.addListener(update); // to know marker positions
    FSCache.addListener(() {
      LapData.reload();
      update();
    }, [FSCache.lapdataPath, FSCache.tempLapdataPath]); // to know lap marker positions
    super.initState();
  }

  void update(){
    bool needUpdate = false;
    if(prevShowDuration == null || prevShowDuration != ChartController.shownDurationNotifier.value){
      prevShowDuration = ChartController.shownDurationNotifier.value;
      needUpdate = true;
    }

    if(prevFirstVisibleTimestamp == null || prevFirstVisibleTimestamp != TraceSettingsProvider.firstVisibleTimestamp){
      prevFirstVisibleTimestamp = TraceSettingsProvider.firstVisibleTimestamp;
      needUpdate = true;
    }

    if(prevLastVisibleTimestamp == null || prevLastVisibleTimestamp != TraceSettingsProvider.lastVisibleTimestamp){
      prevLastVisibleTimestamp = TraceSettingsProvider.lastVisibleTimestamp;
      needUpdate = true;
    }

    if(prevCursors == null || prevCursors != cursorInfoNotifier.value.cursors){
      prevCursors = cursorInfoNotifier.value.cursors;
      needUpdate = true;
    }

    if(prevLaps == null || prevLaps != LapData.lapMarkers()){
      prevLaps = LapData.lapMarkers();
      needUpdate = true;
    }

    if(prevTempLaps == null || prevTempLaps != LapData.tempLapMarkers()){
      prevTempLaps = LapData.tempLapMarkers();
      needUpdate = true;
    }

    if(needUpdate){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartBottomOverviewFramePainter(),
    );
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}

class ChartBottomOverviewFramePainter extends CustomPainter {

  static final TextPainter textPainterBase = TextPainter(
    text: TextSpan(
      text: "DEFAULT TEXT",
      style: StyleManager.textStyle,
    ),
    textDirection: TextDirection.ltr,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double duration = (TraceSettingsProvider.lastVisibleTimestamp - TraceSettingsProvider.firstVisibleTimestamp).toDouble();
    //final ChartShowDuration showDuration = ChartController.shownDurationNotifier.value;
    //final double startToFullDurationRatio = (showDuration.timeOffset - TraceSettingsProvider.firstVisibleTimestamp) / duration;
    //final double endToFullDurationRatio = (showDuration.timeOffset + showDuration.timeDuration - TraceSettingsProvider.firstVisibleTimestamp) / duration;

    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));

    /*canvas.drawRect(
      Rect.fromPoints(Offset(size.width * startToFullDurationRatio.clamp(0, 1), 0), Offset(size.width * endToFullDurationRatio.clamp(0, 1), chartBottomOverviewHeight)),
      Paint()..color = StyleManager.globalStyle.secondaryColor.withOpacity(0.3)..strokeWidth = 2..style = PaintingStyle.fill
    );*/

    for(int markerIndex = 0; markerIndex < cursorInfoNotifier.value.cursors.length; markerIndex++){
      final double screenPosXRatio = (cursorInfoNotifier.value.cursors[markerIndex].timeStamp - TraceSettingsProvider.firstVisibleTimestamp) / duration;

      if(screenPosXRatio > 0 && screenPosXRatio < 1){
        canvas.drawLine(Offset(screenPosXRatio * size.width, 0), Offset(screenPosXRatio * size.width, size.height), Paint()..color = StyleManager.globalStyle.primaryColor..strokeWidth = 1);
        
        final TextPainter tp = textPainterBase..text = TextSpan(
          text: "${cursorInfoNotifier.value.cursors[markerIndex].isDelta ? "D" : "M"}$markerIndex",
          style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
        );
        tp.layout();
        final Offset majorPos = Offset(screenPosXRatio * size.width +  2 * StyleManager.globalStyle.padding, StyleManager.globalStyle.padding);
        tp.paint(canvas, majorPos.translate(-tp.width / 2, -10));
      }
    }

    List<double> lapMarkers = LapData.lapMarkers();
    for(int markerIndex = 0; markerIndex < lapMarkers.length; markerIndex++){
      final double screenPosXRatio = (lapMarkers[markerIndex] - TraceSettingsProvider.firstVisibleTimestamp) / duration;

      if(screenPosXRatio > 0 && screenPosXRatio < 1){
        canvas.drawLine(Offset(screenPosXRatio * size.width, 0), Offset(screenPosXRatio * size.width, size.height), Paint()..color = StyleManager.globalStyle.primaryColor..strokeWidth = 1);

        final TextPainter tp = textPainterBase..text = TextSpan(
          text: "L$markerIndex",
          style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
        );
        tp.layout();
        final Offset majorPos = Offset(screenPosXRatio * size.width +  2 * StyleManager.globalStyle.padding, StyleManager.globalStyle.padding);
        tp.paint(canvas, majorPos.translate(-tp.width / 2, -10));
      }
    }

    List<double> tempLapMarkers = LapData.tempLapMarkers();
    for(int markerIndex = 0; markerIndex < tempLapMarkers.length; markerIndex++){
      final double screenPosXRatio = (tempLapMarkers[markerIndex] - TraceSettingsProvider.firstVisibleTimestamp) / duration;

      if(screenPosXRatio > 0 && screenPosXRatio < 1){
        canvas.drawLine(Offset(screenPosXRatio * size.width, 0), Offset(screenPosXRatio * size.width, size.height), Paint()..color = StyleManager.globalStyle.primaryColor..strokeWidth = 1);
      
        final TextPainter tp = textPainterBase..text = TextSpan(
          text: "T$markerIndex",
          style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
        );
        tp.layout();
        final Offset majorPos = Offset(screenPosXRatio * size.width +  2 * StyleManager.globalStyle.padding, StyleManager.globalStyle.padding);
        tp.paint(canvas, majorPos.translate(-tp.width / 2, -10));
      }
    }
  }

  @override
  bool shouldRepaint(ChartBottomOverviewFramePainter oldDelegate) => true;
}

class ChartBottomOverviewChartLine extends StatefulWidget {
  const ChartBottomOverviewChartLine({super.key});

  @override
  State<ChartBottomOverviewChartLine> createState() => _ChartBottomOverviewChartLineState();
}

class _ChartBottomOverviewChartLineState extends State<ChartBottomOverviewChartLine> {
  Map<String, List<String>>? prevVisibleSignals;
  double? prevFirstVisibleTimestamp;
  double? prevLastVisibleTimestamp;

  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(update); // to know visible signals
    prevVisibleSignals = TraceSettingsProvider.visibleSignals;
    prevFirstVisibleTimestamp = TraceSettingsProvider.firstVisibleTimestamp;
    prevLastVisibleTimestamp = TraceSettingsProvider.lastVisibleTimestamp;
    super.initState();
  }

  void update(){
    bool needUpdate = false;

    Map<String, List<String>> vis = TraceSettingsProvider.visibleSignals;
    if(prevVisibleSignals == null || prevVisibleSignals != vis){
      prevVisibleSignals = vis;
      needUpdate = true;
    }
    
    if(prevFirstVisibleTimestamp == null || prevFirstVisibleTimestamp != TraceSettingsProvider.firstVisibleTimestamp){
      prevFirstVisibleTimestamp = TraceSettingsProvider.firstVisibleTimestamp;
      needUpdate = true;
    }

    if(prevLastVisibleTimestamp == null || prevLastVisibleTimestamp != TraceSettingsProvider.lastVisibleTimestamp){
      prevLastVisibleTimestamp = TraceSettingsProvider.lastVisibleTimestamp;
      needUpdate = true;
    }

    if(needUpdate){
      ChartBottomOverviewChartLinePainter.storage.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartBottomOverviewChartLinePainter(vis: prevVisibleSignals!),
    );
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}

class ChartBottomOverviewChartLinePainter extends CustomPainter {

  final Map<String, List<String>> vis;

  static Map<MapEntry<String, String>, Path> storage = {};

  ChartBottomOverviewChartLinePainter({super.repaint, required this.vis});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    canvas.scale(1, -1);
    canvas.translate(0, -size.height);
    
    if(storage.isEmpty){
      final Iterable<MapEntry<String, String>> visSignals = vis.entries.expand((element) => element.value.map((e) => MapEntry(element.key, e)));
      
      final List<double> maximums = [];
      final List<double> minimums = [];
      for(final MapEntry<String, String> sig in visSignals){
        final double minV = signalData[sig.key]![sig.value]!.values.iterable.fold<num>(0.0, (value, element) => min(value, element)).toDouble();
        final double maxV = signalData[sig.key]![sig.value]!.values.iterable.fold<num>(0.0, (value, element) => max(value, element)).toDouble();
        minimums.add(minV);
        maximums.add(maxV);
      }

      if(minimums.isEmpty || maximums.isEmpty){
        return;
      }

      final double canvasYMax = maximums.reduce((value, element) => max(value, element));
      final double canvasYMin = minimums.reduce((value, element) => min(value, element));
      final double canvasXmax = TraceSettingsProvider.lastVisibleTimestamp;
      final double canvasXmin = TraceSettingsProvider.firstVisibleTimestamp;
      final double canvasYRange = canvasYMax - canvasYMin;
      final double canvasXRange = canvasXmax - canvasXmin;
      final double xScale = size.width / canvasXRange;
      final double yScale = size.height / canvasYRange;

      for(final MapEntry<String, String> sig in visSignals){
        final Path sigPath = Path();
        final Paint paint = Paint()..color = TraceSettingsProvider.traceSettingNotifier.value[sig.key]!.firstWhere((element) => element.signal == sig.value).color..style = PaintingStyle.stroke;

        sigPath.moveTo((signalData[sig.key]![sig.value]!.timestamps.first - canvasXmin) * xScale, (signalData[sig.key]![sig.value]!.values.first - canvasYMin) * yScale);
        for(int i = 1; i < signalData[sig.key]![sig.value]!.timestamps.size; i += signalData[sig.key]![sig.value]!.timestamps.size ~/ 2500){
          sigPath.lineTo((signalData[sig.key]![sig.value]!.timestamps[i] - canvasXmin) * xScale, (signalData[sig.key]![sig.value]!.values[i] - canvasYMin) * yScale);
        }
        canvas.drawPath(sigPath, paint);
        storage[sig] = sigPath;
      }
    }
    else{
      for(final MapEntry<String, String> sig in storage.keys){
        canvas.drawPath(storage[sig]!, Paint()..color = TraceSettingsProvider.traceSettingNotifier.value[sig.key]!.firstWhere((element) => element.signal == sig.value).color..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(ChartBottomOverviewChartLinePainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(ChartBottomOverviewChartLinePainter oldDelegate) => false;
}