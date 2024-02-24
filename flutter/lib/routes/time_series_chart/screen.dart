import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class ChartApp extends StatefulWidget {
  const ChartApp({super.key});

  @override
  State<ChartApp> createState() => _ChartAppState();
}

class _ChartAppState extends State<ChartApp> {
  @override
  void initState() {
    StyleManager.updater = _update;
    postStartup();
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
}

class ChartScreen extends StatelessWidget{
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}