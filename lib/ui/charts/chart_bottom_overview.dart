import 'package:flutter/material.dart';

import 'chart_logic/chart_controller.dart';

const double chartBottomOverviewHeight = 100;

class ChartBottomOverview extends StatefulWidget {
  const ChartBottomOverview({super.key});

  @override
  State<ChartBottomOverview> createState() => _ChartBottomOverviewState();
}

class _ChartBottomOverviewState extends State<ChartBottomOverview> {
  @override
  void initState() {
    ChartController.shownDurationNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // keret arra ami visible
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        print('bottom onHorizontalDragUpdate ${details.primaryDelta}');
        ChartController.moveInTime = details.primaryDelta ?? 0;
        setState(() {});
      },
      child: Container(
        // draw frame around visible part
        // draw overview of full timescale
        // below time axis
        height: chartBottomOverviewHeight,
        color: Colors.blue,
      )
    );
  }

  @override
  void dispose() {
    ChartController.shownDurationNotifier.removeListener(update);
    super.dispose();
  }
}