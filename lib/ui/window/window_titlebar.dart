import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../../routes/startup.dart';
import '../../routes/window_type.dart';
import '../theme/theme.dart';

const titlebarHeight = 25 + 5; // Windows default + nemtom miért de nagyobb

class WindowTitle extends StatefulWidget {
  const WindowTitle({super.key,});

  @override
  State<WindowTitle> createState() => _WindowTitleState();
}

class _WindowTitleState extends State<WindowTitle> {

  @override
  void initState() {
    StyleManager.titleNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
      child: Text(StyleManager.titleNotifier.value ?? windowTypeTitle[windowType]!, style: StyleManager.subTitleStyle),
    );
  }

  @override
  void dispose() {
    StyleManager.titleNotifier.removeListener(update);
    super.dispose();
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
                child: WindowTitle()
              ),
            )
          ),
          const WindowButtons()
        ],
      ),
    );
  }
}