import 'package:flutter/material.dart';

import '../../../ui/theme/theme.dart';
import 'settings_container.dart';

class SettingsBottomBar extends StatelessWidget{
  const SettingsBottomBar({super.key, required this.onCancel, required this.onApply, required this.onApplyAndClose});

  final Function onCancel;
  final Function onApply;
  final Function onApplyAndClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: settingsBottomBarHeight,
      decoration: BoxDecoration(border: Border(top: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))),
      child: Row(
        children: const []
      )
    );
  }

}