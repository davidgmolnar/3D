// ignore_for_file: constant_identifier_names

enum WindowType{
  MAIN_WINDOW,
  SETTINGS,
  TIME_SERIES_CHART,
  MAP_CHART
}

Map<WindowType, String> windowTypeDescription = {
  WindowType.MAIN_WINDOW: "Main window",
  WindowType.SETTINGS: "Settings window",
  WindowType.TIME_SERIES_CHART: "Time chart",
  WindowType.MAP_CHART: "Map chart"
};