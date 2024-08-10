import 'package:flutter/material.dart';

import '../../data/lapdata.dart';
import '../../data/settings.dart';
import '../../data/settings_classes.dart';
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
  double? prevChartAreaHeight;
  Map<String, List<TraceSetting>>? prevVisibleSignals;

  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update); // to know chart area height
    TraceSettingsProvider.traceSettingNotifier.addListener(update); // to know visible signals
    super.initState();
  }

  void update(){
    bool needUpdate = false;

    if(prevChartAreaHeight == null || prevChartAreaHeight != ChartController.chartHeigth){
      prevChartAreaHeight = ChartController.chartHeigth;
      needUpdate = true;
    }

    Map<String, List<TraceSetting>> vis = TraceSettingsProvider.visibleSignalsData;
    if(prevVisibleSignals == null || prevVisibleSignals != vis){
      prevVisibleSignals = vis;
      needUpdate = true;
    }

    if(needUpdate){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}