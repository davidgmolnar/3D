import 'package:flutter/material.dart';

import '../../../ui/theme/theme.dart';
import 'settings_container.dart';

class SettingsBottomBar extends StatelessWidget{
  const SettingsBottomBar({super.key});

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