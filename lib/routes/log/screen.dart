import 'package:flutter/material.dart';

import '../../ui/common.dart';
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

class _LogAppState extends State<LogApp> {
  @override
  void initState() {
    StyleManager.titleNotifier.addListener(_update);
    postStartup();
    super.initState();
  }

  void _update() => setState(() {});
  
  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StyleManager.titleNotifier.value ?? windowTypeTitle[windowType]!,
      scaffoldMessengerKey: snackbarKey,
      theme: StyleManager.getThemeData(context),
      home: const LogScreen(),
    );
  }

  @override
  void dispose() {
    StyleManager.titleNotifier.removeListener(_update);
    super.dispose();
  }
}

class LogScreen extends StatelessWidget{
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: const [
            CustomWindowTitleBar(),
            Expanded(
              child: LogContainer()
            ),
          ],
        ),
      ),
    );
  }
}