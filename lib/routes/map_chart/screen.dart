import 'package:flutter/material.dart';

import '../../ui/common.dart';
import '../../ui/theme/theme.dart';
import '../startup.dart';
import '../window_type.dart';

class MapApp extends StatefulWidget {
  const MapApp({super.key});

  @override
  State<MapApp> createState() => _MapAppState();
}

class _MapAppState extends State<MapApp> {
  @override
  void initState() {
    StyleManager.titleNotifier.addListener(update);
    postStartup();
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StyleManager.titleNotifier.value ?? windowTypeTitle[windowType]!,
      scaffoldMessengerKey: snackbarKey,
      theme: StyleManager.getThemeData(context),
      home: const MapScreen(),
    );
  }

  @override
  void dispose() {
    StyleManager.titleNotifier.removeListener(update);
    super.dispose();
  }
}

class MapScreen extends StatelessWidget{
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}