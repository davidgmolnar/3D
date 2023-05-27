import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class MainWindowApp extends StatefulWidget {
  const MainWindowApp({super.key});

  @override
  State<MainWindowApp> createState() => _MainWindowAppState();
}

class _MainWindowAppState extends State<MainWindowApp> {
  @override
  void initState() {
    StyleManager.updater = update;
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: windowTypeTitle[windowType]!,
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
    return Container();
  }
}