import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../routes/startup.dart';
import '../routes/window_type.dart';
import 'theme.dart';

class WindowTitle extends StatelessWidget {
  const WindowTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
      child: Text(title, style: StyleManager.subTitleStyle),
    );
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({Key? key}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StyleManager.globalStyle.secondaryColor,
      child: Row(
        children: [
          MinimizeWindowButton(colors: StyleManager.windowButtonColors,),
          appWindow.isMaximized
              ? RestoreWindowButton(colors: StyleManager.windowButtonColors,
                  onPressed: maximizeOrRestore,
                )
              : MaximizeWindowButton(colors: StyleManager.windowButtonColors,
                  onPressed: maximizeOrRestore,
                ),
          CloseWindowButton(colors: StyleManager.windowButtonColors,),
        ],
      ),
    );
  }
}

class CustomWindowTitleBar extends StatelessWidget {
  const CustomWindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: StyleManager.globalStyle.secondaryColor,
              child: MoveWindow(
                child: WindowTitle(
                  title: StyleManager.title ?? windowTypeTitle[windowType]!
                )
              ),
            )
          ),
          const WindowButtons()
        ],
      ),
    );
  }
}