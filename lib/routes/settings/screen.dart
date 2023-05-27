import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class SettingApp extends StatefulWidget {
  const SettingApp({super.key});

  @override
  State<SettingApp> createState() => _SettingAppState();
}

class _SettingAppState extends State<SettingApp> {
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
      home: const SettingScreen(),
    );
  }

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }
}

class SettingScreen extends StatelessWidget{
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}