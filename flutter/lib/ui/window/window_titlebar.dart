import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../../routes/startup.dart';
import '../../routes/window_type.dart';
import '../theme/theme.dart';

const titlebarHeight = 25 + 5; // Windows default + nemtom miért de nagyobb

class WindowTitle extends StatelessWidget {
  const WindowTitle({super.key,});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
      child: Text(StyleManager.title ?? windowTypeTitle[windowType]!, style: StyleManager.subTitleStyle),
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
      // TODO meg kell próbálni ha ide rakok egy StyleManager.update()-t akkor a maximizeOrRestore gomb nyomására updatel-e a chart és nem bugol ki. Nem kritikus mert gesture-re megjavul a chart
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
          CloseWindowButton(
            colors: StyleManager.windowButtonColors..mouseOver = Colors.red,
            onPressed: () async {
              shutdown();
            },
          ),
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
                child: const WindowTitle()
              ),
            )
          ),
          const WindowButtons()
        ],
      ),
    );
  }
}