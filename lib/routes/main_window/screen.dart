import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme.dart';
import '../../ui/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';
import 'main_window_widgets/main_window_layout.dart';

class MainWindowApp extends StatefulWidget {
  const MainWindowApp({super.key});

  @override
  State<MainWindowApp> createState() => _MainWindowAppState();
}

class _MainWindowAppState extends State<MainWindowApp> {
  @override
  void initState() {
    StyleManager.updater = update;
    postStartup();
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StyleManager.title ?? windowTypeTitle[windowType]!,
      scaffoldMessengerKey: snackbarKey,
      theme: StyleManager.getThemeData(context),
      home: const MainWindowScreen(),
    );
  }

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }
}

class MainWindowScreen extends StatelessWidget{
  const MainWindowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: const [
            CustomWindowTitleBar(),
            MainWindowLayout()
          ],
        ),
      ),
    );
  }
}