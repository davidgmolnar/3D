import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../../data/settings.dart';
import '../../../ui/common.dart';
import '../../../ui/dialogs/dbc_selector_dialog.dart';
import '../../../ui/dialogs/dialog_base.dart';
import '../../../ui/theme/theme.dart';
import '../log_logic/log_io_controller.dart';
import 'log_container.dart';

const double fileSelectionBarHeight = 100;

class LogImport extends StatefulWidget {
  const LogImport({super.key});

  @override
  State<LogImport> createState() => _LogImportState();
}

class _LogImportState extends State<LogImport> {

  @override
  void initState() {
    LogIOInfoController.logIOInfoNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: fileSelectionBarHeight,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: StyleManager.globalStyle.bgColor,
                    border: Border(right: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor,))
                  ),
                  child: ListView.builder(
                    itemCount: LogIOInfoController.logIOInfoNotifier.value.selectedPaths.length,
                    itemExtent: 25,
                    itemBuilder: ((context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                            child: Text(LogIOInfoController.logIOInfoNotifier.value.selectedPaths[index]),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: LogIOInfoController.logIOInfoNotifier.value.measurementAliases[index] ?? "Alias"
                              ),
                              onFieldSubmitted: (alias) {
                                LogIOInfoController.logIOInfoNotifier.update((value) {
                                  value.measurementAliases[index] = alias;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              LogIOInfoController.logIOInfoNotifier.update((value) {
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
                width: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          dialogTitle: "Pick files to be imported",
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: ["csv", "bin"]
                        );
                        if(result != null){
                          final List<String> filtered = result.paths.removedWhere((element) => element == null).cast<String>();
                          LogIOInfoController.logIOInfoNotifier.update((value) {
                            value.selectedPaths.addAll(filtered);
                            value.measurementAliases.addAll(List.filled(filtered.length, null));
                          });
                          List<String>? dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
                          if(dbcPaths == null || dbcPaths.isEmpty){
                            // ignore: use_build_context_synchronously
                            await showDialog<Widget>(context: context, builder: (BuildContext context){
                              return const DialogBase(
                                title: "DBC Selection",
                                dialog: DBCSelectorDialog(),
                                minWidth: 700,
                              );
                            });
                            dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
                            if(dbcPaths == null || dbcPaths.isEmpty){
                              // ignore: use_build_context_synchronously
                              showError(context, "You must select a DBC file to import a binary log");
                              // ignore: use_build_context_synchronously
                              await showDialog<Widget>(context: context, builder: (BuildContext context){
                                return const DialogBase(
                                  title: "DBC Selection",
                                  dialog: DBCSelectorDialog(),
                                  minWidth: 700,
                                );
                              });
                              dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
                            }
                          }
                        }
                      },
                      child: Text("Select", style: StyleManager.textStyle,),
                    ),
                    TextButton(
                      onPressed: (){
                        if(LogIOInfoController.logIOInfoNotifier.value.processing){
                          return;
                        }
                        if(LogIOInfoController.logIOInfoNotifier.value.selectedPaths.isEmpty){
                          showError(context, "Nothing was selected");
                          return;
                        }
                        LogIOInfoController.logIOInfoNotifier.value.processing = true;
                        try{
                          LogIOInfoController.sendFilesToMaster();
                        }catch(exc){
                          showError(context, "Error when importing: ${exc.toString()}");
                        }
                        setState(() {});
                        LogIOInfoController.logIOInfoNotifier.update((value) {});
                      },
                      child: Text("Import", style: StyleManager.textStyle,),
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
              itemCount: LogIOInfoController.logIOInfoNotifier.value.context.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(LogIOInfoController.logIOInfoNotifier.value.context[index], maxLines: 5,);
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
                        value: LogIOInfoController.logIOInfoNotifier.value.linePercentage,
                        color: StyleManager.globalStyle.primaryColor,
                        backgroundColor: StyleManager.globalStyle.bgColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: LinearProgressIndicator(
                        value: LogIOInfoController.logIOInfoNotifier.value.selectedPaths.isNotEmpty ? 
                          LogIOInfoController.logIOInfoNotifier.value.filesLoaded / LogIOInfoController.logIOInfoNotifier.value.selectedPaths.length : 0,
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
                    child: Text(LogIOInfoController.logIOInfoNotifier.value.error ? "There were errors" : "There were no errors"),
                  ),
                  Container(
                    width: 250,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text("Processed ${LogIOInfoController.logIOInfoNotifier.value.filesLoaded} files"),
                  ),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(LogIOInfoController.logIOInfoNotifier.value.processing ? "Processing" : "Idle"),
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
    LogIOInfoController.logIOInfoNotifier.removeListener(update);
    super.dispose();
  }
}

class LogExport extends StatefulWidget {
  const LogExport({super.key});

  @override
  State<LogExport> createState() => _LogExportState();
}

class _LogExportState extends State<LogExport> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container()),
        Container(
          height: logBottomBarHeight,
          color: StyleManager.globalStyle.secondaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [

            ],
          ),
        )
      ],
    );
  }
}