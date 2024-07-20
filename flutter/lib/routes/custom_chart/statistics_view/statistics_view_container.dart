import 'package:flutter/material.dart';

import 'statistics_view_data_container.dart';
import 'statistics_view_plot_container.dart';
import 'statistics_view_toolbar.dart';

class StatisticsViewContainer extends StatelessWidget {
  const StatisticsViewContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: StatisticsViewToolbar()
        ),
        Expanded(
          child: StatisticsViewDataContainer()
        ),
        SizedBox(
          height: 300,
          child: StatisticsViewPlotContainer()
        ),
      ],
    );
  }
}