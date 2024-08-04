import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/dialogs/lapdata_dialog.dart';
import '../../ui/notifications/notification_widgets.dart';
import '../../ui/theme/theme.dart';
import '../../ui/window/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';

class LapEditorApp extends StatefulWidget {
  const LapEditorApp({super.key});

  @override
  State<LapEditorApp> createState() => _LapEditorAppState();
}

class _LapEditorAppState extends State<LapEditorApp> with WindowListener{
  @override
  void initState() {
    StyleManager.init(_update);
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
      home: const LapEditorScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class LapEditorScreen extends StatelessWidget{
  const LapEditorScreen({super.key});

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
                  LapDataDialog(),
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