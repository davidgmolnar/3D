import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:log_analyser/extensions.dart';

import '../../../io/logger.dart';
import '../../../ui/input_widgets/buttons.dart';
import '../../../ui/input_widgets/text_fields.dart';
import '../../../ui/notifications/notification_logic.dart' as noti;
import '../../../ui/theme/theme.dart';
import '../../../ui/toolbar/toolbar_item.dart';
import '../log_logic/calculation_io_controller.dart';
import 'log_container.dart';

const double scriptSelectionBarHeight = 150;

class CalculationWindow extends StatefulWidget {
  const CalculationWindow({super.key});

  @override
  State<CalculationWindow> createState() => _CalculationWindowState();
}

class _CalculationWindowState extends State<CalculationWindow> {

  @override
  void initState() {
    CalculationIoController.calIOInfoNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: scriptSelectionBarHeight,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: StyleManager.globalStyle.bgColor,
                    border: Border(right: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor,))
                  ),
                  child: ListView.builder(
                    itemCount: CalculationIoController.calIOInfoNotifier.value.selectedPaths.length,
                    itemExtent: 25,
                    itemBuilder: ((context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                            child: Text(CalculationIoController.calIOInfoNotifier.value.selectedPaths[index]),
                          ),
                          IconButton(
                            onPressed: () {
                              CalculationIoController.calIOInfoNotifier.update((value) {
                                value.selectedPaths.removeAt(index);
                              });
                            },
                            padding: const EdgeInsets.all(0),
                            icon: Icon(Icons.cancel, color: StyleManager.globalStyle.primaryColor,),
                            splashRadius: null,
                          )
                        ],
                      );
                    })
                  ),
                )
              ),
              Container(
                color: StyleManager.globalStyle.secondaryColor,
                width: 250,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () async {
                        CalculationIoController.reset();
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          dialogTitle: "Pick scripts",
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: ["CAL"]
                        );
                        if(result != null){
                          CalculationIoController.calIOInfoNotifier.update((value) {
                            final List<String> filtered = result.paths.removedWhere((element) => element == null).cast<String>();
                            value.selectedPaths.addAll(filtered);
                          });
                        }
                      },
                      child: Text("Select", style: StyleManager.textStyle,),
                    ),
                    ToggleableTextField<String>(
                      initialValue: CalculationIoController.calIOInfoNotifier.value.calculationOptions.measurement,
                      parser: (p0) => p0,
                      onFinished: (p0) {
                        CalculationIoController.calIOInfoNotifier.update((value) {
                          value.calculationOptions = value.calculationOptions.copyWith(measurement: p0);
                        });
                      },
                      width: 250,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ButtonWithTwoText(
                          onPressed: (p0) {
                            CalculationIoController.calIOInfoNotifier.update((value) {
                              value.calculationOptions = value.calculationOptions.copyWith(cleanRebuild: p0);
                            });
                          },
                          isInitiallyActive: CalculationIoController.calIOInfoNotifier.value.calculationOptions.cleanRebuild,
                          textWhenActive: "Clean rebuild",
                          textWhenInactive: "Lazy rebuild",
                        ),
                        ToggleableTextField<int>(
                          initialValue: CalculationIoController.calIOInfoNotifier.value.calculationOptions.sampleTimeMs,
                          parser: (p0) => int.tryParse(p0),
                          onFinished: (p0) {
                            CalculationIoController.calIOInfoNotifier.update((value) {
                              value.calculationOptions = value.calculationOptions.copyWith(sampleTimeMs: p0);
                            });
                          },
                          width: 100,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: (){
                            if(CalculationIoController.calIOInfoNotifier.value.processing){
                              return;
                            }
                            if(CalculationIoController.calIOInfoNotifier.value.selectedPaths.isEmpty){
                              noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("Nothing was selected"), 5000));
                              return;
                            }
                            if(CalculationIoController.calIOInfoNotifier.value.calculationOptions.measurement == "Please select measurement"){
                              noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("A measurement must be selected"), 5000));
                              return;
                            }
                            CalculationIoController.calIOInfoNotifier.value.processing = true;
                            try{
                              CalculationIoController.sendFilesToMaster();
                            }catch(exc){
                              noti.NotificationController.add(noti.Notification.decaying(LogEntry.error("Error when starting calfile execution: ${exc.toString()}"), 5000));
                            }
                            setState(() {});
                            CalculationIoController.calIOInfoNotifier.update((value) {});
                          },
                          icon: Icon(Icons.play_arrow, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        IconButton(
                          onPressed: (){
                            noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("This feature is WIP"), 5000));
                            return;
                            /*if(CalculationIoController.calIOInfoNotifier.value.processing){
                              return;
                            }
                            if(CalculationIoController.calIOInfoNotifier.value.selectedPaths.isEmpty){
                              showError(context, "Nothing was selected");
                              return;
                            }
                            CalculationIoController.calIOInfoNotifier.value.processing = true;
                            CalculationIoController.calIOInfoNotifier.value.isDebug = true;
                            try{
                              CalculationIoController.sendFilesToMaster();
                            }catch(exc){
                              showError(context, "Error when starting calfile execution: ${exc.toString()}");
                            }
                            setState(() {});
                            CalculationIoController.calIOInfoNotifier.update((value) {});*/
                          },
                          icon: Icon(Icons.bug_report, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        IconButton(
                          onPressed: (){
                            noti.NotificationController.add(noti.Notification.decaying(LogEntry.warning("This feature is WIP"), 5000));
                            return;
                          },
                          icon: Icon(FontAwesomeIcons.arrowRightToBracket, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: [
                          const ToolbarDropdownItem(onPressed: CalculationIoController.compileOnly, text: "Compile only"),
                          ToolbarDropdownItem(onPressed: (){CalculationIoController.compileAll(context);}, text: "Compile all"),
                          ToolbarDropdownItem(onPressed: (){CalculationIoController.editParameters(context);}, text: "Edit parameters"),
                        ], iconHeight: toolbarItemSize, invertColors: true,),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))
            ),
            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
            child: ListView.builder(
              itemCount: CalculationIoController.calIOInfoNotifier.value.context.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(CalculationIoController.calIOInfoNotifier.value.context[index], maxLines: 5,);
              },
            ),
          )
        ),
        Container(
          height: logBottomBarHeight,
          color: StyleManager.globalStyle.secondaryColor,
          child: Column(
            children: [
              SizedBox(
                height: logBottomBarHeight / 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: LinearProgressIndicator(
                        value: CalculationIoController.calIOInfoNotifier.value.linePercentage,
                        color: StyleManager.globalStyle.primaryColor,
                        backgroundColor: StyleManager.globalStyle.bgColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: LinearProgressIndicator(
                        value: CalculationIoController.calIOInfoNotifier.value.selectedPaths.isNotEmpty ? 
                          CalculationIoController.calIOInfoNotifier.value.scriptsFinished / CalculationIoController.calIOInfoNotifier.value.selectedPaths.length : 0,
                        color: StyleManager.globalStyle.primaryColor,
                        backgroundColor: StyleManager.globalStyle.bgColor,
                        ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 200,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(CalculationIoController.calIOInfoNotifier.value.error ? "There were errors" : "There were no errors"),
                  ),
                  Container(
                    width: 250,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text("Processed ${CalculationIoController.calIOInfoNotifier.value.scriptsFinished} scripts"),
                  ),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(CalculationIoController.calIOInfoNotifier.value.processing ? "Processing" : "Idle"),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    CalculationIoController.calIOInfoNotifier.removeListener(update);
    super.dispose();
  }
}