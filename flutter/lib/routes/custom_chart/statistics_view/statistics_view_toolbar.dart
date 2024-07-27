import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/lapdata.dart';
import '../../../io/logger.dart';
import '../../../ui/dialogs/dialog_base.dart';
import '../../../ui/dialogs/string_input_dialog.dart';
import '../../../ui/input_widgets/list_selector.dart';
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
                if(StatisticsViewController.notifier.value["data.meas"] != null){
                  StatisticsViewController.notifier.value["data.selected_names"].clear();
                  StatisticsViewController.notifier.value["plot.signal"] = null;
                }
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
          ListSelector(
            selection: StatisticsViewController.notifier.value["laps.selected"].cast<int>().map((final int lapIndex) => LapData.rep(StatisticsViewController.notifier.value["laps"][lapIndex], lapIndex)).toList().cast<String>(),
            hintText: "Select laps",
            options: List.generate(StatisticsViewController.notifier.value["laps"].length, (lapIndex) => LapData.rep(StatisticsViewController.notifier.value["laps"][lapIndex], lapIndex)),
            onSelected: (final List<String> lapStringReps){
              final List<int> lapIndexes = lapStringReps.map((rep) {
                return int.parse(rep.split(':').first.substring(4)) - 1;
              }).toList();
              lapIndexes.sort();
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
          IconButton(
            onPressed: () async {
              if(StatisticsViewController.notifier.value["data.meas"] == null){
                noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Set measurement first"), 5000));
                return;
              }

              // ask for preset name in dialog but from available selection dropdown
              // check if preset exists

              final List<String> missing = await StatisticsViewController.loadState(presetName, StatisticsViewController.notifier.value["data.meas"]);
              if(missing.isNotEmpty){
                noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Missing signals: $missing"), 5000));
                return;
              }
              noti.NotificationController.add(noti.Notification.decaying(LogEntry.info("Successfully loaded preset $presetName"), 5000));
            },
            icon: Icon(FontAwesomeIcons.fileImport, color: StyleManager.globalStyle.primaryColor,),
          ),
          IconButton(
            onPressed: () async {
              showDialog<Widget>(context: context, builder: (BuildContext context){
                return DialogBase(
                  title: "Input dialog",
                  dialog: StringInputDialog(
                    hintText: "Specify preset name",
                    onFinished: (presetName) {
                      StatisticsViewController.saveState(presetName);
                    },
                  ),
                  minWidth: 400,
                  maxHeight: 150,
                );
              });
            },
            icon: Icon(FontAwesomeIcons.fileExport, color: StyleManager.globalStyle.primaryColor,),
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
          ),
          DropdownButton<int>(
            value: StatisticsViewController.notifier.value["laps.plot_selected"],
            items: [DropdownMenuItem<int>(value: null, child: Text("Full log", style: StyleManager.textStyle,),),
              ...StatisticsViewController.notifier.value["laps.selected"].cast<int>().map((final int lapIndex) => DropdownMenuItem<int>(value: lapIndex, child: Text(LapData.rep(StatisticsViewController.notifier.value["laps"][lapIndex], lapIndex), style: StyleManager.textStyle,))).toList()],
            onChanged: (selected){
              StatisticsViewController.notifier.update("laps.plot_selected", selected);
            }
          ),
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
Be able to export current state of statisticsviewcontroller except plotdata and lapdata, and reload it, also run calfile where needed
  Phase 1.
  Check if signals are in fscache loaded signals. If not in there throw error, else load them

  Phase 2.
  When saving calfiles will need to be specified
  Instead of throwing error immediately send missing signal names to master along with the list of calfiles to run, it will run the list, and update signals in statview
 */