import '../../../data/custom_notifiers.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';

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

class StatisticsViewData{
  StatistiscsViewPlotType plotType = StatistiscsViewPlotType.HIST;
  String? signalToPlot;
  String? meas;
  final Map<String, List<String>> visibleTraceNames = {};
  final Map<String, List<String>> allTraceNames = {};
  final List<String> selectedSignals = [];
}

abstract class StatisticsViewController{
  static final UpdateableValueNotifier<StatisticsViewData> notifier = UpdateableValueNotifier<StatisticsViewData>(StatisticsViewData());

  static void sendRequest(){
    ChildProcess.send(Response(
      localSocketPort,
      ResponseType.DATA,
      ChildRequest(
        type: ChildRequestType.STATISTICS_MEAS_REQ,
        context: {
          "meas": notifier.value.meas!,
          "signals": notifier.value.selectedSignals
        }
      ).asJson
    ));
  }
}