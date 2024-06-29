import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/statistics_processor.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewDataContainer extends StatefulWidget {
  const StatisticsViewDataContainer({super.key});

  @override
  State<StatisticsViewDataContainer> createState() => _StatisticsViewDataContainerState();
}

class _StatisticsViewDataContainerState extends State<StatisticsViewDataContainer> {
  Map<String, Stat> statistics = {};

  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate, ["data.selected_names", "data.meas"]);
    super.initState();
  }
  
  void _onControllerUpdate(){
    if(StatisticsViewController.notifier.value["data.selected_names"].isNotEmpty && StatisticsViewController.notifier.value["data.meas"] != null){
      statistics.clear();
      for(final String signal in StatisticsViewController.notifier.value["data.selected_names"]) {
        statistics[signal] = StatisticsProcessor.stat(StatisticsViewController.notifier.value["data.meas"]!, signal);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatisticsViewDataHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: statistics.length,
            itemExtent: 30,
            cacheExtent: 300,
            itemBuilder: (context, index) {
              final Stat stat = statistics.values.toList()[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 300, child: Text(statistics.keys.elementAt(index), style: StyleManager.textStyle,)),
                    Expanded(child: Text(stat.min.roundToDecimalPlaces(5).toString(), style: StyleManager.textStyle,)),
                    Expanded(child: Text(stat.max.roundToDecimalPlaces(5).toString(), style: StyleManager.textStyle,)),
                    Expanded(child: Text(stat.integral.roundToDecimalPlaces(5).toString(), style: StyleManager.textStyle,)),
                    Expanded(child: Text(stat.avg.roundToDecimalPlaces(5).toString(), style: StyleManager.textStyle,)),
                  ],
                ),
              );
            },
                ),
        ),
      ]
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

class StatisticsViewDataHeader extends StatelessWidget {
  const StatisticsViewDataHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 300, child: Text("Signal", style: StyleManager.textStyle,)),
          Expanded(child: Text("Min", style: StyleManager.textStyle,)),
          Expanded(child: Text("Max", style: StyleManager.textStyle,)),
          Expanded(child: Text("Integral", style: StyleManager.textStyle,)),
          Expanded(child: Text("Avg", style: StyleManager.textStyle,)),
        ],
      ),
    );
  }
}