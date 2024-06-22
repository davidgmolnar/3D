import 'package:flutter/material.dart';

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
    StatisticsViewController.notifier.addListener(_onControllerUpdate);
    super.initState();
  }

  void _onControllerUpdate(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Meas selector               ->
        // Stat Signals list selector  -> once both set, send req to master
        // refresh                     -> backup to this^^
        // vertical divider
        // Plot type selector
        // plot signal selector
        DropdownButton<String>(
          value: StatisticsViewController.notifier.value.meas,
          items: [DropdownMenuItem<String>(value: null, child: Text("Select", style: StyleManager.textStyle,)), ...StatisticsViewController.notifier.value.allTraceNames.keys.map((meas) => DropdownMenuItem<String>(value: meas, child: Text(meas, style: StyleManager.textStyle,)))],
          onChanged: (final String? selected){
            StatisticsViewController.notifier.update((value) {
              value.meas = selected;
              if(selected != null && value.selectedSignals.isNotEmpty){
                StatisticsViewController.sendRequest();
              }
            });
          }
        ),
        SearchListSelector(
          selection: StatisticsViewController.notifier.value.selectedSignals,
          hintText: "Select",
          options: StatisticsViewController.notifier.value.allTraceNames[StatisticsViewController.notifier.value.meas] ?? [],
          onSelected: (p0) {
            StatisticsViewController.notifier.update((value) {
              value.selectedSignals.clear();
              value.selectedSignals.addAll(p0);
              if(p0.isNotEmpty && value.meas != null){
                StatisticsViewController.sendRequest();
              }
            });
          },
        ),
        IconButton(
          onPressed: (){
            if(StatisticsViewController.notifier.value.selectedSignals.isNotEmpty && StatisticsViewController.notifier.value.meas != null){
              StatisticsViewController.sendRequest();
            }
            else{
              noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Set measurement and signals first"), 5000));
            }
          },
          icon: Icon(Icons.refresh, color: StyleManager.globalStyle.primaryColor,)
        ),
        Divider(thickness: 1, color: StyleManager.globalStyle.primaryColor,),
        DropdownButton<StatistiscsViewPlotType>(
          value: StatisticsViewController.notifier.value.plotType,
          items: StatistiscsViewPlotType.values.map((e) => DropdownMenuItem<StatistiscsViewPlotType>(value: e, child: Text(e.asString(), style: StyleManager.textStyle,))).toList(),
          onChanged: (selected){
            if(selected != null){
              StatisticsViewController.notifier.update((value) {
                value.plotType = selected;
              });
            }
          }
        ),
        SearchSelector(
          selected: StatisticsViewController.notifier.value.signalToPlot,
          options: StatisticsViewController.notifier.value.selectedSignals,
          hintText: "Select",
          onSelected: (p0) {
            StatisticsViewController.notifier.update((value) {
              value.signalToPlot = p0;
            });
          },
        )
      ],
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}