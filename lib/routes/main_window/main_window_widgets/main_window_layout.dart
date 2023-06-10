import 'package:flutter/material.dart';

import '../../../ui/charts/main_window_chart.dart';
import 'main_window_toolbar.dart';

class MainWindowLayout extends StatelessWidget {
  const MainWindowLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        MainWindowToolbar(),
        ChartContainer()
      ],
    );
  }
}