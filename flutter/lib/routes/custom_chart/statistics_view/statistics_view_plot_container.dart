import 'package:flutter/material.dart';

import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewPlotContainer extends StatefulWidget {
  const StatisticsViewPlotContainer({super.key});

  @override
  State<StatisticsViewPlotContainer> createState() => _StatisticsViewPlotContainerState();
}

class _StatisticsViewPlotContainerState extends State<StatisticsViewPlotContainer> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_reDrawNeeded, ["plot.signal", "plot.type", "plot.configs"]);
    super.initState();
  }

  void _reDrawNeeded(){
    // calc plot into "plot.datas"
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if(StatisticsViewController.notifier.value["plot.signal"] == null){
      return Center(child: Text("Select a signal to plot", style: StyleManager.subTitleStyle,));
    }
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StatisticsPlotConfigView(
                  onChanged: _reDrawNeeded
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_reDrawNeeded);
    super.dispose();
  }
}

class StatisticsPlotConfigView extends StatelessWidget {
  const StatisticsPlotConfigView({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 100,
      decoration: BoxDecoration(
        color: StyleManager.globalStyle.secondaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(StyleManager.globalStyle.padding))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for(final MapEntry<String, num> param in StatisticsViewController.plotConfig.entries)
            StatisticsPlotConfigElement(
              param: param,
              minmax: StatisticsViewController.plotConfigMinMax,
              onChanged: (final double value){
                StatisticsViewController.updatePlotConfig(param.key, value);
                onChanged();
              }
            )
        ],
      ),
    );
  }
}

class StatisticsPlotConfigElement extends StatelessWidget {
  const StatisticsPlotConfigElement({super.key, required this.param, required this.minmax, required this.onChanged});

  final MapEntry<String, num> param;
  final Offset minmax;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${param.key}: ${param.value}",
          style: StyleManager.textStyle,
        ),
        Slider(
          min: minmax.dx,
          max: minmax.dy,
          value: param.value.toDouble(),
          onChanged: onChanged,
          activeColor: StyleManager.globalStyle.primaryColor,
          inactiveColor: StyleManager.globalStyle.bgColor,
        )
      ],
    );
  }
}