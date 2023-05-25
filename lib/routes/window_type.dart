// ignore_for_file: constant_identifier_names

enum WindowType{
  INITIAL,
  MAIN_WINDOW,
  SETTINGS,
  TIME_SERIES_CHART,
  MAP_CHART,
}

WindowType windowType = WindowType.INITIAL;

Map<WindowType, String> windowTypeDescription = {
  WindowType.INITIAL: "Initial window",
  WindowType.MAIN_WINDOW: "Main window",
  WindowType.SETTINGS: "Settings window",
  WindowType.TIME_SERIES_CHART: "Time chart",
  WindowType.MAP_CHART: "Map chart"
};

extension FromString on WindowType{
  WindowType? tryParse(String string){
    switch (string) {
      case "INITIAL":
        return WindowType.INITIAL;
      case "MAIN_WINDOW":
        return WindowType.INITIAL;
      case "SETTINGS":
        return WindowType.INITIAL;
      case "TIME_SERIES_CHART":
        return WindowType.INITIAL;
      case "MAP_CHART":
        return WindowType.INITIAL;
      default:
        return null;
    }
  }
}