import 'package:flutter/material.dart';

import '../../../ui/charts/main_window_chart.dart';
import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/custom_chart_window_type.dart';
import 'custom_chart_toolbar.dart';

const double logBottomBarHeight = 100;

class CustomChartContainer extends StatelessWidget {
  const CustomChartContainer({super.key});
  
  @override
  Widget build(BuildContext context) {
    Widget child = Center(child: Text("Loading", style: StyleManager.subTitleStyle,),);
    switch (customChartWindowType) {
      case CustomChartWindowType.ERROR:
        child = Center(child: Text("Something went wrong", style: StyleManager.subTitleStyle,),);
        break;
      case CustomChartWindowType.GRID:
        child = ListView(
          children: const [
            Column(
              children: [
                CustomChartToolbar(),
                ChartContainer()
              ],
            )
          ],
        );
        break;
      case CustomChartWindowType.STATISTICS:
        child = Center(child: Text("Type not implemented", style: StyleManager.subTitleStyle,),);
        break;
      case CustomChartWindowType.CHARACTERISTICS:
        child = ListView(
          children: const [
            Column(
              children: [
                CustomChartToolbar(),
                ChartContainer()
              ],
            )
          ],
        );
        break;
      default:
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
      ),
      child: child,
    );
  }
}