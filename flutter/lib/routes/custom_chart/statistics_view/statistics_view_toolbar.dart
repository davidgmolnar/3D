import 'package:flutter/material.dart';

import '../../../data/lapdata.dart';
import '../../../io/logger.dart';
import '../../../ui/input_widgets/search_list_selector.dart';
import '../../../ui/input_widgets/search_selector.dart';
import '../../../ui/notifications/notification_logic.dart' as noti;
import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewToolbar extends StatefulWidget {
  const StatisticsViewToolbar({super.key});

  @override
  State<StatisticsViewToolbar> createState() => _StatisticsViewToolbarState();
}

class _StatisticsViewToolbarState extends State<StatisticsViewToolbar> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate, ["data", "plot.type", "plot.signal", "laps"]);
    super.initState();
  }

  void _onControllerUpdate(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StyleManager.globalStyle.secondaryColor,
        border: Border(bottom: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
            child: DropdownButton<String>(
              value: StatisticsViewController.notifier.value["data.meas"],
              items: [DropdownMenuItem<String>(value: null, child: Text("Select measurement", style: StyleManager.textStyle,)), ...StatisticsViewController.notifier.value["data.all_names"].keys.map((meas) => DropdownMenuItem<String>(value: meas, child: Text(meas, style: StyleManager.textStyle,)))],
              onChanged: (final String? selected){
                StatisticsViewController.notifier.update("data.meas", selected);
                if(selected != null && StatisticsViewController.notifier.value["data.selected_names"].isNotEmpty){
                  StatisticsViewController.sendRequest();
                }
              }
            ),
          ),
          SearchListSelector(
            selection: StatisticsViewController.notifier.value["data.selected_names"].cast<String>(),
            hintText: "Select signals",
            options: StatisticsViewController.notifier.value["data.all_names"][StatisticsViewController.notifier.value["data.meas"]]?.cast<String>() ?? [],
            onSelected: (p0) {
              StatisticsViewController.notifier.value["data.selected_names"].clear();
              StatisticsViewController.notifier.value["data.selected_names"].addAll(p0);
              StatisticsViewController.notifier.updateKey("data.selected_names");
              if(p0.isNotEmpty && StatisticsViewController.notifier.value["data.meas"] != null){
                StatisticsViewController.sendRequest();
              }
            }
          ),
          SearchListSelector(
            selection: StatisticsViewController.notifier.value["laps.selected"].cast<int>().map((final int lapIndex) => LapData.rep(StatisticsViewController.notifier.value["laps"][lapIndex], lapIndex)).toList().cast<String>(),
            hintText: "Select laps",
            options: List.generate(StatisticsViewController.notifier.value["laps"].length, (lapIndex) => LapData.rep(StatisticsViewController.notifier.value["laps"][lapIndex], lapIndex)),
            onSelected: (final List<String> lapStringReps){
              final List<int> lapIndexes = lapStringReps.map((rep) {
                return int.parse(rep.split(':').first.substring(4)) - 1;
              }).toList();
              StatisticsViewController.notifier.update("laps.selected", lapIndexes);
            }
          ),
          IconButton(
            onPressed: (){
              if(StatisticsViewController.notifier.value["data.selected_names"].isNotEmpty && StatisticsViewController.notifier.value["data.meas"] != null){
                StatisticsViewController.sendRequest();
              }
              else{
                noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Set measurement and signals first"), 5000));
              }
            },
            icon: Icon(Icons.refresh_outlined, color: StyleManager.globalStyle.primaryColor,),
          ),
          Container(
            width: 1,
            color: StyleManager.globalStyle.primaryColor,
          ),
          DropdownButton<StatistiscsViewPlotType>(
            value: StatisticsViewController.notifier.value["plot.type"],
            items: StatistiscsViewPlotType.values.map((e) => DropdownMenuItem<StatistiscsViewPlotType>(value: e, child: Text(e.asString(), style: StyleManager.textStyle,))).toList(),
            onChanged: (selected){
              if(selected != null){
                StatisticsViewController.notifier.update("plot.type", selected);
              }
            }
          ),
          Padding(
            padding: EdgeInsets.all(StyleManager.globalStyle.padding),
            child: SearchSelector(
              selected: StatisticsViewController.notifier.value["plot.signal"],
              options: StatisticsViewController.notifier.value["data.selected_names"].cast<String>(),
              hintText: "Select signal to plot",
              onSelected: (p0) {
                StatisticsViewController.notifier.update("plot.signal", p0);
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

/* TODOS
Add a select lap to plot selector

Modify laps selection, instead of SearchListSelector it needs a List selector, no point in searching that

Add borders to StatisticsViewDataContainer table for visibility or use checkerboard bgcolor/secondary color
Add special colors to largest/smallest in a column

Be able to export current state of statisticsviewcontroller except plotdata and lapdata
 */