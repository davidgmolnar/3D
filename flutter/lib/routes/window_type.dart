// ignore_for_file: constant_identifier_names

enum WindowType{
  INITIAL,
  MAIN_WINDOW,
  SETTINGS,
  CUSTOM_CHART,
  MAP_CHART,
  LOG,
  LAP_EDITOR
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
      case "CUSTOM_CHART":
        return WindowType.CUSTOM_CHART;
      case "MAP_CHART":
        return WindowType.MAP_CHART;
      case "LOG":
        return WindowType.LOG;
      case "LAP_EDITOR":
        return WindowType.LAP_EDITOR;
      default:
        return null;
    }
  }
}