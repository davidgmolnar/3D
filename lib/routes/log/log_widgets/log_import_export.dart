import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../io/deserializer.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../ui/theme/theme.dart';
import '../log_logic/log_io_controller.dart';
import 'log_container.dart';



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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: LinearProgressIndicator(value: LogIOInfoController.logIOInfoNotifier.value.progressPercentage / 100,)),
                    Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: Text(LogIOInfoController.logIOInfoNotifier.value.processingFile ?? "Import finished"),
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 150,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(LogIOInfoController.logIOInfoNotifier.value.error ? "There were errors" : "There were no errors"),
                  ),
                  Container(
                    width: 150,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text("Successfully loaded ${LogIOInfoController.logIOInfoNotifier.value.successulLoads} files"),
                  ),
                  Container(
                    width: 100,
                    padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                    child: Text(!LogIOInfoController.logIOInfoNotifier.value.ready ? "Processing" : !LogIOInfoController.logIOInfoNotifier.value.sendingToController ? "Ready" : "Sending"),
                  ),
                  TextButton(
                    onPressed: () {
                      if(!LogIOInfoController.logIOInfoNotifier.value.ready || LogIOInfoController.logIOInfoNotifier.value.sendingToController){
                        return;
                      }
                      ChildProcess.send(Deserializer.utf8Decoder.convert(
                        jsonEncode(LogIOInfoController.logIOInfoNotifier.value.resultJsonEncodeable)
                      ));
                      LogIOInfoController.logIOInfoNotifier.update((value) {
                        value.sendingToController = true;
                      });
                    },
                    child: const Text("Send to app"),
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
            children: [

            ],
          ),
        )
      ],
    );
  }
}