import 'package:flutter/material.dart';

import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewPlotContainer extends StatefulWidget {
  const StatisticsViewPlotContainer({super.key});

  @override
  State<StatisticsViewPlotContainer> createState() => _StatisticsViewPlotContainerState();
}

class _StatisticsViewPlotContainerState extends State<StatisticsViewPlotContainer> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate);
    super.initState();
  }

  void _onControllerUpdate(){

  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

