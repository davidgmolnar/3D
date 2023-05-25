import 'package:flutter/material.dart';

import 'routes/startup.dart';

void main(List<String> args) {
  if(!tryStartup(args)){
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(); // külön materialappok már kapásból, leálláskor logger.stop() és childprocess/manager.dispose()
  }
}
