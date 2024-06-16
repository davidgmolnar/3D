import '../../../data/custom_notifiers.dart';

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

enum StatisticsViewStatElements{
  // ignore: constant_identifier_names
  MAX,
  // ignore: constant_identifier_names
  MIN,
  // ignore: constant_identifier_names
  AVG,
}

class StatisticsViewData{
  StatistiscsViewPlotType plotType = StatistiscsViewPlotType.HIST;
  String? signalToPlot;
}

abstract class StatisticsViewController{
  static final UpdateableValueNotifier<StatisticsViewData> notifier = UpdateableValueNotifier<StatisticsViewData>(StatisticsViewData());
}