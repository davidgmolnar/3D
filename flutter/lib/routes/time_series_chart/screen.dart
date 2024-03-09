import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class ChartApp extends StatefulWidget {
  const ChartApp({super.key});

  @override
  State<ChartApp> createState() => _ChartAppState();
}

class _ChartAppState extends State<ChartApp> with WindowListener{
  @override
  void initState() {
    StyleManager.updater = _update;
    postStartup(this);
    setState(() {});
    super.initState();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StyleManager.title ?? windowTypeTitle[windowType]!,
      scaffoldMessengerKey: snackbarKey,
      theme: StyleManager.getThemeData(context),
      home: const ChartScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class ChartScreen extends StatelessWidget{
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}