import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class LogApp extends StatefulWidget {
  const LogApp({super.key});

  @override
  State<LogApp> createState() => _LogAppState();
}

class _LogAppState extends State<LogApp> {
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
      home: const LogScreen(),
    );
  }

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }
}

class LogScreen extends StatelessWidget{
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}