import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../ui/common.dart';
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
  bool importStarted = false;

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
                          allowedExtensions: ["csv", "bin", "txt"]
                        );
                        if(result != null){
                          LogIOInfoController.logIOInfoNotifier.update((value) {
                            final List<String> filtered = result.paths.removedWhere((element) => element == null).cast<String>();
                            value.selectedPaths.addAll(filtered);
                            value.measurementAliases.addAll(List.filled(filtered.length, null));
                          });
                        }
                      },
                      child: Text("Select", style: StyleManager.textStyle,),
                    ),
                    TextButton(
                      onPressed: (){
                        if(importStarted){
                          return;
                        }
                        importStarted = true;
                        try{
                          LogIOInfoController.loadFiles();
                        }catch(exc){
                          showError(context, "Error when importing: ${exc.toString()}");
                        }
                        setState(() {});
                      },
                      child: Text("Preprocess", style: StyleManager.textStyle,),
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
                return Text("[${LogIOInfoController.logIOInfoNotifier.value.context[index].timeStamp}] [${
                  LogIOInfoController.logIOInfoNotifier.value.context[index].level.name.toUpperCase()}] ${
                  LogIOInfoController.logIOInfoNotifier.value.context[index].message}", maxLines: 5,);
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
                      child: LinearProgressIndicator(value: LogIOInfoController.logIOInfoNotifier.value.progressPercentage / 100,),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: Text(LogIOInfoController.logIOInfoNotifier.value.processingFile ?? "Processing finished"),
                    )
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
                    child: Text("Successfully processed ${LogIOInfoController.logIOInfoNotifier.value.successfulLoads} files"),
                  ),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(!importStarted ? "" : !LogIOInfoController.logIOInfoNotifier.value.ready ? "Processing" : !LogIOInfoController.logIOInfoNotifier.value.sendingToController ? "Ready" : "Sending"),
                  ),
                  TextButton(
                    onPressed: () async {
                      if(!LogIOInfoController.logIOInfoNotifier.value.ready || LogIOInfoController.logIOInfoNotifier.value.sendingToController){
                        return;
                      }
                      LogIOInfoController.logIOInfoNotifier.update((value) {
                        value.sendingToController = true;
                      });

                      ChildProcess.send(Response(localSocketPort, ResponseType.FINISHED, ResponseFinishable(ResponseFinishableType.IMPORT_LOG, LogIOInfoController.logIOInfoNotifier.value.resultJsonEncodeable).asJson));
                      LogIOInfoController.reset();
                    },
                    child: const Text("Import"),
                  )
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