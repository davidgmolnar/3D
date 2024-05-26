import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/notifications/notification_widgets.dart';
import '../../ui/theme/theme.dart';
import '../../ui/window/window_titlebar.dart';
import '../startup.dart';
import '../window_type.dart';
import 'main_window_widgets/main_window_layout.dart';

final GlobalKey<NavigatorState> mainWindowNavigatorKey = GlobalKey<NavigatorState>();

class MainWindowApp extends StatefulWidget {
  const MainWindowApp({super.key});

  @override
  State<MainWindowApp> createState() => _MainWindowAppState();
}

class _MainWindowAppState extends State<MainWindowApp> with WindowListener {
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
      navigatorKey: mainWindowNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: StyleManager.title ?? windowTypeTitle[windowType]!,
      scaffoldMessengerKey: snackbarKey,
      theme: StyleManager.getThemeData(context),
      home: const MainWindowScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class MainWindowScreen extends StatelessWidget{
  const MainWindowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomWindowTitleBar(),
            Expanded(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ListView(
                    children: const [
                      MainWindowLayout()
                    ],
                  ),
                  const NotificationOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}