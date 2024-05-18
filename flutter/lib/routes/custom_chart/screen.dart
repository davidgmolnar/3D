import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/charts/main_window_chart.dart';
import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../../ui/window/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';
import 'custom_chart_widgets/custom_chart_toolbar.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomWindowTitleBar(),
            Expanded(
              child: ListView(
                children: const [
                  Column( // TODO innentől ez egy customChartWindowType switch és egy külön widget legyen
                    children: [
                      CustomChartToolbar(),
                      ChartContainer()
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}