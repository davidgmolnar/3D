import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../data/settings_classes.dart';
import '../theme/theme.dart';
import 'chart_logic/chart_controller.dart';

const double chartBottomOverviewHeight = 100;

class ChartBottomOverview extends StatelessWidget {
  const ChartBottomOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        //ChartController.moveInFullChannelTime = details.primaryDelta ?? 0;
      },
      child: const SizedBox(
        height: chartBottomOverviewHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChartBottomOverviewChartLine(),
            ChartBottomOverviewFrame()
          ],
        ),
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

  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update); // to know shownDuration
    TraceSettingsProvider.traceSettingNotifier.addListener(update); // to know visible range
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
  @override
  void paint(Canvas canvas, Size size) {
    final double duration = (TraceSettingsProvider.lastVisibleTimestamp - TraceSettingsProvider.firstVisibleTimestamp).toDouble();
    final ChartShowDuration showDuration = ChartController.shownDurationNotifier.value;
    final double startToFullDurationRatio = (showDuration.timeOffset - TraceSettingsProvider.firstVisibleTimestamp) / duration;
    final double endToFullDurationRatio = (showDuration.timeOffset + showDuration.timeDuration - TraceSettingsProvider.firstVisibleTimestamp) / duration;

    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    canvas.drawRect(
      Rect.fromPoints(Offset(size.width * startToFullDurationRatio, 0), Offset(size.width * endToFullDurationRatio, chartBottomOverviewHeight)),
      Paint()..color = StyleManager.globalStyle.secondaryColor.withOpacity(0.3)..strokeWidth = 2..style = PaintingStyle.fill
    );
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