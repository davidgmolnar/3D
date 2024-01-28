import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:log_analyser/extensions.dart';

import '../../../ui/common.dart';
import '../../../ui/input_widgets/buttons.dart';
import '../../../ui/input_widgets/text_fields.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/toolbar/toolbar_item.dart';
import '../log_logic/calibration_io_controller.dart';
import 'log_container.dart';

const double scriptSelectionBarHeight = 150;

class CalibrationWindow extends StatefulWidget {
  const CalibrationWindow({super.key});

  @override
  State<CalibrationWindow> createState() => _CalibrationWindowState();
}

class _CalibrationWindowState extends State<CalibrationWindow> {

  @override
  void initState() {
    CalibrationIoController.calIOInfoNotifier.addListener(update);
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
                    itemCount: CalibrationIoController.calIOInfoNotifier.value.selectedPaths.length,
                    itemExtent: 25,
                    itemBuilder: ((context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                            child: Text(CalibrationIoController.calIOInfoNotifier.value.selectedPaths[index]),
                          ),
                          IconButton(
                            onPressed: () {
                              CalibrationIoController.calIOInfoNotifier.update((value) {
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
                        CalibrationIoController.reset();
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          dialogTitle: "Pick scripts",
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: ["CAL"]
                        );
                        if(result != null){
                          CalibrationIoController.calIOInfoNotifier.update((value) {
                            final List<String> filtered = result.paths.removedWhere((element) => element == null).cast<String>();
                            value.selectedPaths.addAll(filtered);
                          });
                        }
                      },
                      child: Text("Select", style: StyleManager.textStyle,),
                    ),
                    ToggleableTextField<String>(
                      initialValue: CalibrationIoController.calIOInfoNotifier.value.calibrationOptions.measurement,
                      parser: (p0) => p0,
                      onFinished: (p0) {
                        CalibrationIoController.calIOInfoNotifier.update((value) {
                          value.calibrationOptions = value.calibrationOptions.copyWith(measurement: p0);
                        });
                      },
                      width: 250,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ButtonWithTwoText(
                          onPressed: (p0) {
                            CalibrationIoController.calIOInfoNotifier.update((value) {
                              value.calibrationOptions = value.calibrationOptions.copyWith(cleanRebuild: p0);
                            });
                          },
                          isInitiallyActive: CalibrationIoController.calIOInfoNotifier.value.calibrationOptions.cleanRebuild,
                          textWhenActive: "Clean rebuild",
                          textWhenInactive: "Lazy rebuild",
                        ),
                        ToggleableTextField<int>(
                          initialValue: CalibrationIoController.calIOInfoNotifier.value.calibrationOptions.sampleTimeMs,
                          parser: (p0) => int.tryParse(p0),
                          onFinished: (p0) {
                            CalibrationIoController.calIOInfoNotifier.update((value) {
                              value.calibrationOptions = value.calibrationOptions.copyWith(sampleTimeMs: p0);
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
                            if(CalibrationIoController.calIOInfoNotifier.value.processing){
                              return;
                            }
                            if(CalibrationIoController.calIOInfoNotifier.value.selectedPaths.isEmpty){
                              showError(context, "Nothing was selected");
                              return;
                            }
                            if(CalibrationIoController.calIOInfoNotifier.value.calibrationOptions.measurement == "Please select measurement"){
                              showError(context, "A measurement must be selected");
                              return;
                            }
                            CalibrationIoController.calIOInfoNotifier.value.processing = true;
                            try{
                              CalibrationIoController.sendFilesToMaster();
                            }catch(exc){
                              showError(context, "Error when starting calfile execution: ${exc.toString()}");
                            }
                            setState(() {});
                            CalibrationIoController.calIOInfoNotifier.update((value) {});
                          },
                          icon: Icon(Icons.play_arrow, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        IconButton(
                          onPressed: (){
                            showError(context, "This feature is WIP");
                            return;
                            /*if(CalibrationIoController.calIOInfoNotifier.value.processing){
                              return;
                            }
                            if(CalibrationIoController.calIOInfoNotifier.value.selectedPaths.isEmpty){
                              showError(context, "Nothing was selected");
                              return;
                            }
                            CalibrationIoController.calIOInfoNotifier.value.processing = true;
                            CalibrationIoController.calIOInfoNotifier.value.isDebug = true;
                            try{
                              CalibrationIoController.sendFilesToMaster();
                            }catch(exc){
                              showError(context, "Error when starting calfile execution: ${exc.toString()}");
                            }
                            setState(() {});
                            CalibrationIoController.calIOInfoNotifier.update((value) {});*/
                          },
                          icon: Icon(Icons.bug_report, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        IconButton(
                          onPressed: (){
                            showError(context, "This feature is WIP");
                            return;
                          },
                          icon: Icon(FontAwesomeIcons.arrowRightToBracket, color: StyleManager.globalStyle.primaryColor,),
                          splashRadius: 10,
                        ),
                        ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: [
                          const ToolbarDropdownItem(onPressed: CalibrationIoController.compileOnly, text: "Compile only"),
                          ToolbarDropdownItem(onPressed: (){CalibrationIoController.compileAll(context);}, text: "Compile all"),
                          ToolbarDropdownItem(onPressed: (){CalibrationIoController.editParameters(context);}, text: "Edit parameters"),
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
              itemCount: CalibrationIoController.calIOInfoNotifier.value.context.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(CalibrationIoController.calIOInfoNotifier.value.context[index], maxLines: 5,);
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
                        value: CalibrationIoController.calIOInfoNotifier.value.linePercentage,
                        color: StyleManager.globalStyle.primaryColor,
                        backgroundColor: StyleManager.globalStyle.bgColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: LinearProgressIndicator(
                        value: CalibrationIoController.calIOInfoNotifier.value.selectedPaths.isNotEmpty ? 
                          CalibrationIoController.calIOInfoNotifier.value.scriptsFinished / CalibrationIoController.calIOInfoNotifier.value.selectedPaths.length : 0,
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
                    child: Text(CalibrationIoController.calIOInfoNotifier.value.error ? "There were errors" : "There were no errors"),
                  ),
                  Container(
                    width: 250,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text("Processed ${CalibrationIoController.calIOInfoNotifier.value.scriptsFinished} scripts"),
                  ),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(CalibrationIoController.calIOInfoNotifier.value.processing ? "Processing" : "Idle"),
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
    CalibrationIoController.calIOInfoNotifier.removeListener(update);
    super.dispose();
  }
}