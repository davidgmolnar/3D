import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/calculation/calculation_script_execution.dart';
import '../../../data/calculation/calculation_script_parsing.dart';
import '../../../data/calculation/calculation_script_runtime.dart';
import '../../../data/updateable_valuenotifier.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../ui/common.dart';
import '../../../ui/dialogs/dialog_base.dart';
import '../../../ui/dialogs/edit_parameters_dialog.dart';

class CalculationIOInfo{
  String? processingFile;
  bool error = false;
  bool processing = false;
  bool isDebug = false;
  int scriptsFinished = 0;
  double linePercentage = 0;
  List<String> context = [];
  List<String> selectedPaths = [];
  CalculationOptions calculationOptions = CalculationOptions(cleanRebuild: false, measurement: "Please select measurement", sampleTimeMs: 10);
}

class CalculationIoController{
  static final UpdateableValueNotifier<CalculationIOInfo> calIOInfoNotifier = UpdateableValueNotifier<CalculationIOInfo>(CalculationIOInfo());

  static Future<void> sendFilesToMaster() async {
    final Map<String, dynamic> request = {};
    request["script_paths"] = calIOInfoNotifier.value.selectedPaths;
    request["options"] = calIOInfoNotifier.value.calculationOptions.asJson();

    ChildProcess.send(Response(localSocketPort, ResponseType.FINISHED, ResponseFinishable(ResponseFinishableType.RUN_CAL, request).asJson));
  }

  static void setLinePercentage(final double linePercentage){
    calIOInfoNotifier.update((value) {
      value.linePercentage = linePercentage;
    });
  }

  static void addToContext(final String entry){
    calIOInfoNotifier.update((value) {
      value.context.add(entry);
      if(entry.contains("ERROR")){
        value.error = true;
      }
      if(["Build failed", "Exception when running script", "Cannot run calculation file on measurement", "Script successfully executed"].any((element) => entry.contains(element))){
        value.scriptsFinished++;
        if(value.scriptsFinished == value.selectedPaths.length){
          value.processing = false;
        }
      }
    });
  }  

  static void reset(){
    calIOInfoNotifier.update((value) {
      value.processingFile = null;
      value.error = false;
      value.scriptsFinished = 0;
      value.linePercentage = 0;
      value.context = [];
      value.selectedPaths = [];
      value.processing = false;
      value.isDebug = false;
      // value.calculationOptions = CalculationOptions(cleanRebuild: false, measurement: "Please select measurement", sampleTimeMs: 10);
    });
  }

  static void compileOnly() async {
    if(calIOInfoNotifier.value.selectedPaths.isEmpty){
      return;
    }

    calIOInfoNotifier.update((value) {
      value.processing = true;
    });

    for(final String path in calIOInfoNotifier.value.selectedPaths){
      final CompiledCalculation? script = await CalculationScriptRuntime.runCompilationOnly(File(path), calIOInfoNotifier.value.calculationOptions.cleanRebuild,
        progressIndication: (p0, p1) {
          if(p0 != 0){
            setLinePercentage(p0);
          }
          if(p1 != null){
            addToContext(p1);
          }
        },
      );

      if(script != null){
        calIOInfoNotifier.update((value) {
          value.scriptsFinished++;
          if(value.scriptsFinished == value.selectedPaths.length){
            value.processing = false;
          }
        });
      }
    }
  }

  static void compileAll(BuildContext context){
    showError(context, "This feature is WIP");
  }

  static void editParameters(BuildContext context){
    showDialog<Widget>(context: context, builder: (BuildContext context){
      return const DialogBase(
        title: "Edit parameters",
        dialog: EditParametersDialog(),
        minWidth: 600,
      );
    });
  }
}

