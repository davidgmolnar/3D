import 'package:flutter/material.dart';

const double chartBottomOverviewHeight = 100;

class ChartBottomOverview extends StatelessWidget {
  const ChartBottomOverview({super.key, required this.chartUpdater});

  final Function chartUpdater;

  @override
  Widget build(BuildContext context) {
    return Container(height: chartBottomOverviewHeight, color: Colors.blue,);
  }
}