import 'package:flutter/material.dart';

import 'io/logger.dart';
import 'multiprocess/childprocess.dart';
import 'multiprocess/childprocess_api.dart';
import 'routes/window_type.dart';

void main(List<String> args) {
  try{
    if(args.isEmpty){
      localSocketPort = masterSocketPort;
      windowType = WindowType.MAIN_WINDOW;
      localLogger = Logger(mainLogPath, "Master Logger");
    }
    else{
      localSocketPort = int.parse(args[1]);
      windowType = windowType.tryParse(args[0])!;
      localLogger = Logger(mainLogPath, "${windowType.name} Logger @$localSocketPort");
    }
  }
  catch (exc){
    if(localSocketPort != masterSocketPort){
      ChildProcess().signalStop();
    }
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
