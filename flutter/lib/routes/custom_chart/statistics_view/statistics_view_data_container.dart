import 'package:flutter/material.dart';

import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewDataContainer extends StatefulWidget {
  const StatisticsViewDataContainer({super.key});

  @override
  State<StatisticsViewDataContainer> createState() => _StatisticsViewDataContainerState();
}

class _StatisticsViewDataContainerState extends State<StatisticsViewDataContainer> {
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