// ignore_for_file: constant_identifier_names

enum WindowType{
  INITIAL,
  MAIN_WINDOW,
  SETTINGS,
  CUSTOM_CHART,
  MAP_CHART,
  LOG
}

WindowType windowType = WindowType.INITIAL;

extension FromString on WindowType{
  WindowType? tryParse(String string){
    switch (string) {
      case "INITIAL":
        return WindowType.INITIAL;
      case "MAIN_WINDOW":
        return WindowType.MAIN_WINDOW;
      case "SETTINGS":
        return WindowType.SETTINGS;
      case "TIME_SERIES_CHART":
        return WindowType.CUSTOM_CHART;
      case "MAP_CHART":
        return WindowType.MAP_CHART;
      case "LOG":
        return WindowType.LOG;
      default:
        return null;
    }
  }
}