import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class MapApp extends StatefulWidget {
  const MapApp({super.key});

  @override
  State<MapApp> createState() => _MapAppState();
}

class _MapAppState extends State<MapApp> with WindowListener{
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
      home: const MapScreen(),
    );
  }

  @override
  void onWindowClose() async {
    shutdown();
  }
}

class MapScreen extends StatelessWidget{
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}