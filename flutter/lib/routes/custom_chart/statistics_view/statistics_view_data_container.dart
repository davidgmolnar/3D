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
  Map<String, List<Stat>> statistics = {};
  Map<String, List<StatType>> statLineData = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate, ["data.selected_names", "data.meas", "laps.selected"]);
    super.initState();
  }
  
  void _onControllerUpdate(){
    if(StatisticsViewController.notifier.value["data.selected_names"].isNotEmpty && StatisticsViewController.notifier.value["data.meas"] != null){
      statistics.clear();
      statLineData.clear();
      for(final String signal in StatisticsViewController.notifier.value["data.selected_names"]) {
        statistics[signal] = StatisticsProcessor.stat(StatisticsViewController.notifier.value["data.meas"]!, signal);
        statLineData[signal] = [StatType.MIN, StatType.MAX];
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      child: SizedBox(
        height: 1000,
        width: 3000,
        child: Column(
          children: [
            StatisticsViewDataHeader(statLineData: statLineData,),
            Expanded(
              child: ListView.builder(
                itemCount: statistics.length + 1,
                itemExtent: 100,
                cacheExtent: 300,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if(index == 0){
                    return ListView.builder(
                      itemCount: StatisticsViewController.notifier.value["laps.selected"].isEmpty ? 1 : StatisticsViewController.notifier.value["laps.selected"].length,
                      itemExtent: 30,
                      cacheExtent: 300,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: 30,
                          width: 100,
                          child: Text(StatisticsViewController.notifier.value["laps.selected"].isEmpty ? "Full log" : "Lap $index.", style: StyleManager.textStyle,),
                        );
                      },
                    );
                  }
                  final List<Stat> stat = statistics.values.toList()[index - 1];
                  return ListView.builder(
                    itemCount: (StatisticsViewController.notifier.value["laps.selected"].length == 0 ? 1 : StatisticsViewController.notifier.value["laps.selected"].length),
                    itemExtent: 30,
                    cacheExtent: 300,
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, vindex) {
                      final String signal = statistics.keys.elementAt(index - 1);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: statLineData[signal]!.map((e) => 
                          SizedBox(
                            height: 30,
                            width: 50,
                            child: Text(
                              stat[vindex].get(e).roundToDecimalPlaces(5).toString(),
                              style: StyleManager.textStyle,
                            ),
                          )
                        ).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

class StatisticsViewDataHeader extends StatelessWidget {
  const StatisticsViewDataHeader({super.key, required this.statLineData});

  final Map<String, List<StatType>> statLineData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(height: 300, width: 100,),
        ...statLineData.keys.map((final String signal) => 
          SizedBox(
            height: 300 - 2 * StyleManager.globalStyle.padding,
            width: statLineData[signal]!.length * 50,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Text(signal, style: StyleManager.textStyle,),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: statLineData[signal]!.map((e) => SizedBox(
                    height: 30,
                    width: 50,
                    child: Text(e.name, style: StyleManager.textStyle,)
                  )).toList(),
                )
              ],
            ),
          ),
        ).toList()
      ],
    );
  }
}