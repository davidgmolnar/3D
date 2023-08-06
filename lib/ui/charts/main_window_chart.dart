import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../toolbar/toolbar_item.dart';
import '../window/window_titlebar.dart';
import 'chart_area.dart';
import 'chart_bottom_overview.dart';
import 'chart_logic/chart_controller.dart';
import 'chart_scaler.dart';

class ChartContainer extends StatelessWidget {
  const ChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ChartController.chartAreaWidth = constraints.maxWidth;
        final double height = MediaQuery.of(context).size.height - toolbarItemSize - titlebarHeight - 2 * 1;
        ChartController.chartAreaHeight = height;
        return Container(
          height: height,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor)),
          ),
          child: const Chart(),
        );
      },
    );
  }
}

class Chart extends StatelessWidget {
  const Chart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: const [
              ChartScaler(),
              Expanded(child: ChartArea()),
            ],
          ),
        ),
        const ChartBottomOverview()
      ],
    );
  }
}