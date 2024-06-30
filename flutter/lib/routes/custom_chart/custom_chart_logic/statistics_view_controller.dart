import 'dart:ui';

import '../../../data/custom_notifiers.dart';
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
    "plot.configs": {
      StatistiscsViewPlotType.HIST: HistogramConfig(binCount: 50, minmax: const Offset(0, 100)),
      StatistiscsViewPlotType.PDF: PDFConfig(bw: 1, minmax: const Offset(-5, 5)),
      StatistiscsViewPlotType.CDF: CDFConfig(bw: 1, minmax: const Offset(-5, 5)),
    },
    "plot.datas": {
      StatistiscsViewPlotType.HIST: Histogram(bins: []),
      StatistiscsViewPlotType.PDF: PDF(line: []),
      StatistiscsViewPlotType.CDF: CDF(line: []),
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
}