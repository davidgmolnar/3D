import 'package:flutter/material.dart';

import '../../../ui/theme/theme.dart';
import '../log_logic/log_window_action_type.dart';
import 'log_import_export.dart';

const double logBottomBarHeight = 100;

class LogContainer extends StatelessWidget {
  const LogContainer({super.key});
  
  @override
  Widget build(BuildContext context) {
    Widget child = Center(child: Text(StyleManager.titleNotifier.value ?? "null", style: StyleManager.subTitleStyle,),);
    switch (logWindowType) {
      case LogWindowActionType.DISPLAY:
        child = Center(child: Text("Type not implemented", style: StyleManager.subTitleStyle,),);
        break;
      case LogWindowActionType.IMPORT:
        child = const LogImport();
        break;
      case LogWindowActionType.EXPORT:
        child = Center(child: Text("Type not implemented", style: StyleManager.subTitleStyle,),);
        break;
      case LogWindowActionType.CALCULATION:
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