import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../../ui/dialogs/dialog_base.dart';
import '../../../ui/input_widgets/list_selector.dart';
import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/statistics_processor.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewDataContainer extends StatefulWidget {
  const StatisticsViewDataContainer({super.key});

  
  static final Map<String, List<StatType>> statLineData = {};

  @override
  State<StatisticsViewDataContainer> createState() => _StatisticsViewDataContainerState();
}

class _StatisticsViewDataContainerState extends State<StatisticsViewDataContainer> {
  Map<String, List<Stat>> statistics = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate, ["data.selected_names", "data.meas", "laps.selected"]);
    super.initState();
  }
  
  void _onControllerUpdate(){
    if(StatisticsViewController.notifier.value["data.selected_names"].isNotEmpty && StatisticsViewController.notifier.value["data.meas"] != null){
      statistics.clear();
      for(final String signal in StatisticsViewController.notifier.value["data.selected_names"]) {
        statistics[signal] = StatisticsProcessor.stat(StatisticsViewController.notifier.value["data.meas"]!, signal);
        if(!StatisticsViewDataContainer.statLineData.containsKey(signal) || StatisticsViewDataContainer.statLineData[signal]!.isEmpty){
          StatisticsViewDataContainer.statLineData[signal] = [StatType.MIN, StatType.MAX];
        }
      }

      StatisticsViewDataContainer.statLineData.removeWhere((key, value) => !StatisticsViewController.notifier.value["data.selected_names"].contains(key));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if(statistics.isEmpty){
      return Container();
    }
    final List<MapEntry<String, StatType>> unravel = [];
    for(MapEntry<String, List<StatType>> entry in StatisticsViewDataContainer.statLineData.entries){
      for(int i = 0; i < entry.value.length; i++){
        unravel.add(MapEntry(entry.key, entry.value[i]));
      }
    }
    return InteractiveViewer(
      constrained: false,
      child: SizedBox(
        height: 300.0 + (StatisticsViewController.notifier.value["laps.selected"].isEmpty ? 1 : StatisticsViewController.notifier.value["laps.selected"].length) * 30.0,
        width: (unravel.length + 1) * 100.0,
        child: Column(
          children: [
            StatisticsViewDataHeader(statLineData: StatisticsViewDataContainer.statLineData,),
            Expanded(
              child: ListView.builder(
                itemCount: unravel.length + 1,
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
                      itemBuilder: (context, vindex) {
                        return Container(
                          color: vindex % 2 == 0 ? StyleManager.globalStyle.secondaryColor : StyleManager.globalStyle.bgColor,
                          height: 30,
                          width: 100,
                          child: Text(StatisticsViewController.notifier.value["laps.selected"].isEmpty ? "Full log" : "Lap ${StatisticsViewController.notifier.value["laps.selected"][vindex] + 1}.", style: StyleManager.textStyle,),
                        );
                      },
                    );
                  }
                  final String signal = unravel[index - 1].key;
                  final List<Stat> stat = statistics[signal]!;
                  int minIndex = 0;
                  int maxIndex = 0;
                  for(int i = 0; i < stat.length; i++){
                    if(stat[i].get(unravel[index - 1].value) < stat[minIndex].get(unravel[index - 1].value)){
                      minIndex = i;
                    }
                    if(stat[i].get(unravel[index - 1].value) > stat[maxIndex].get(unravel[index - 1].value)){
                      maxIndex = i;
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: index == 1 || unravel[index - 1].key !=  unravel[index - 2].key ?
                        Border(left: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
                        :
                        const Border()
                    ),
                    child: ListView.builder(
                      itemCount: (StatisticsViewController.notifier.value["laps.selected"].length == 0 ? 1 : StatisticsViewController.notifier.value["laps.selected"].length),
                      itemExtent: 30,
                      cacheExtent: 300,
                      scrollDirection: Axis.vertical,
                      controller: _scrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, vindex) {
                        return Container(
                          color: vindex == maxIndex && StatisticsViewController.notifier.value["laps.selected"].length > 1 && maxIndex != minIndex ?
                           Colors.red
                            : vindex == minIndex && StatisticsViewController.notifier.value["laps.selected"].length > 1 && maxIndex != minIndex  ?
                            Colors.green
                            :
                            vindex % 2 == 0 ? StyleManager.globalStyle.secondaryColor : StyleManager.globalStyle.bgColor,
                          height: 30,
                          width: 100,
                          child: Center(
                            child: Text(
                              stat[vindex].get(unravel[index - 1].value).roundToDecimalPlaces(7).toString(),
                              style: StyleManager.textStyle,
                            ),
                          ),
                        );
                      },
                    ),
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
          GestureDetector(
            onTap: () {
              showDialog<Widget>(
                context: context,
                builder: (BuildContext context){
                  return DialogBase(
                    title: "Select stat types",
                    minWidth: 500,
                    maxHeight: 500,
                    dialog: ListSelectorDialog(selection: statLineData[signal]!.map((e) => e.name).toList(), hintText: "", options: StatType.values.map((e) => e.name).toList(), onSelected: (final List<String> selected){
                      statLineData[signal]?.clear();
                      statLineData[signal] = [];
                      for(final String sel in selected){
                        statLineData[signal]!.add(StatType.values.firstWhere((element) => element.name == sel));
                      }
                      StatisticsViewController.notifier.updateKey("data.selected_names");
                    },),
                  );
                }
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
              ),
              height: 300,
              width: statLineData[signal]!.length * 100,
              child: Column(
                children: [
                  Container(
                    height: 300 - 30,
                    width: 100 - 1,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Text(signal, style: StyleManager.textStyle,),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: statLineData[signal]!.map((e) => SizedBox(
                      height: 30,
                      width: 100 - 1,
                      child: Center(child: Text(e.name, style: StyleManager.textStyle,))
                    )).toList(),
                  )
                ],
              ),
            ),
          ),
        ).toList()
      ],
    );
  }
}