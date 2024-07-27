import 'dart:io';
import 'dart:ui';

import '../../../data/custom_notifiers.dart';
import '../../../data/sci/kde.dart';
import '../../../io/file_system.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';
import 'statistics_processor.dart';

enum StatistiscsViewPlotType{
  // ignore: constant_identifier_names
  HIST,
  // ignore: constant_identifier_names
  PDF,
  // ignore: constant_identifier_names
  CDF,
}

extension ToString on StatistiscsViewPlotType{
  String asString(){
    switch (this) {
      case StatistiscsViewPlotType.HIST:
        return "Histogram";
      case StatistiscsViewPlotType.PDF:
        return "PDF";
      case StatistiscsViewPlotType.CDF:
        return "CDF";
    }
  }
}

abstract class StatisticsViewController{
  static final MappedConditionalNotifier<dynamic> notifier = MappedConditionalNotifier<dynamic>( value: {
    "plot.type": StatistiscsViewPlotType.HIST,
    "plot.signal": null,
    "data.meas": null,
    "data.visible_names": {},
    "data.all_names": {},
    "data.selected_names": [],
    "laps": [],
    "laps.selected": [],
    "laps.plot_selected": null,
    "plot.configs": {
      StatistiscsViewPlotType.HIST: HistogramConfig(binCount: 50, minmax: const Offset(0, 100)),
      StatistiscsViewPlotType.PDF: PDFConfig(bw: 1, minmax: const Offset(-2, 5)),
      StatistiscsViewPlotType.CDF: CDFConfig(bw: 1, minmax: const Offset(-2, 5)),
    },
    "plot.datas": {
      StatistiscsViewPlotType.HIST: Histogram(bins: []),
      StatistiscsViewPlotType.PDF: PDF(line: KDEResult.empty()),
      StatistiscsViewPlotType.CDF: CDF(line: KDEResult.empty()),
    }
  });

  static void sendRequest(){
    ChildProcess.send(Response(
      localSocketPort,
      ResponseType.DATA,
      ChildRequest(
        type: ChildRequestType.STATISTICS_MEAS_REQ,
        context: {
          "meas": notifier.value["data.meas"]!,
          "signals": notifier.value["data.selected_names"]
        }
      ).asJson
    ));
  }

  static Map<String, num> get plotConfig{
    return notifier.value["plot.configs"][notifier.value["plot.type"]].asMap;
  }

  static Offset get plotConfigMinMax{
    return notifier.value["plot.configs"][notifier.value["plot.type"]]!.minmax;
  }

  static void updatePlotConfig(final String path, final num newValue){
    notifier.value["plot.configs"][notifier.value["plot.type"]]!.set(path, newValue);
    //notifier.updateKey("plot.configs");
  }

  static Future<bool> saveState(final String presetName) async {
    final Map<String, dynamic> stateToSave = {
      "data.selected_names": notifier.value["data.selected_names"]
    };

    List<FileSystemEntity> entities = await FileSystem.tryListElementsInLocalAsync(FileSystem.statPresetDir);
    if(entities.any((element) => element.path.endsWith("$presetName.3DSTATPRESET"))){
      return false;
    }

    await FileSystem.trySaveMapToLocalAsync(FileSystem.statPresetDir, "$presetName.3DSTATPRESET", stateToSave);
    return true;
  }

  static Future<List<String>> loadState(final String presetName, final String meas) async { // meas has to be selected first, then passed in here
    List<FileSystemEntity> entities = await FileSystem.tryListElementsInLocalAsync(FileSystem.statPresetDir);
    if(entities.any((element) => element.path.endsWith("$presetName.3DSTATPRESET"))){
      final Map data = await FileSystem.tryLoadMapFromLocalAsync(FileSystem.statPresetDir, "$presetName.3DSTATPRESET");
      final List<String> signalsToLoad = data["data.selected_names"].cast<String>();

      final List<String> available = StatisticsViewController.notifier.value["data.all_names"][meas].cast<String>();
      final List<String> missing = [];
      for(final String sig in signalsToLoad){
        if(!available.contains(sig)){
          missing.add(sig);
        }
      }
      if(missing.isNotEmpty){
        return missing;
      }

      StatisticsViewController.notifier.value["data.selected_names"].clear();
      StatisticsViewController.notifier.value["data.selected_names"].addAll(signalsToLoad);
    }
    return [];
  }
}