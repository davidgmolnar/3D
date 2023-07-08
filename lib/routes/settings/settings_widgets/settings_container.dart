import 'package:flutter/material.dart';

import '../../../ui/theme/theme.dart';
import '../settings_logic/settings_window_type.dart';
import 'settings_trace_editor.dart';

const double settingsBottomBarHeight = 100;

class SettingsContainer extends StatelessWidget {
  const SettingsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget child = Center(child: Text("Loading", style: StyleManager.subTitleStyle,),);
    switch (settingsWindowType) {
      case SettingsWindowType.SETTINGS:
        child = Center(child: Text("Type not implemented", style: StyleManager.subTitleStyle,),);
        break;
      case SettingsWindowType.TRACE_EDITOR:
        child = const SettingsTraceEditor();
        break;
      case SettingsWindowType.CALCULATION_TESTER:
        child = Center(child: Text("Type not implemented", style: StyleManager.subTitleStyle,),);
        break;
      default:
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
      ),
      child: child,
    );
  }
}