import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../../ui/window/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';
import 'custom_chart_widgets/custom_chart_container.dart';

class CustomChartApp extends StatefulWidget {
  const CustomChartApp({super.key});

  @override
  State<CustomChartApp> createState() => _CustomChartAppState();
}

class _CustomChartAppState extends State<CustomChartApp> with WindowListener{
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
      home: const CustomChartScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class CustomChartScreen extends StatelessWidget{
  const CustomChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomWindowTitleBar(),
            Expanded(
              child: CustomChartContainer()
            ),
          ],
        ),
      ),
    );
  }
}