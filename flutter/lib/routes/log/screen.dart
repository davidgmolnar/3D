import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/notifications/notification_widgets.dart';
import '../../ui/theme/theme.dart';
import '../../ui/window/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';
import 'log_widgets/log_container.dart';

class LogApp extends StatefulWidget {
  const LogApp({super.key});

  @override
  State<LogApp> createState() => _LogAppState();
}

class _LogAppState extends State<LogApp> with WindowListener {
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
      theme: StyleManager.getThemeData(context),
      home: const LogScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class LogScreen extends StatelessWidget{
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomWindowTitleBar(),
            Expanded(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  LogContainer(),
                  NotificationOverlay()
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}