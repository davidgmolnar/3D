import 'package:log_analyser/multiprocess/childprocess.dart';
import 'package:log_analyser/multiprocess/childprocess_controller.dart';

import '../io/logger.dart';
import '../multiprocess/childprocess_api.dart';
import 'window_type.dart';

bool tryStartup(List<String> args){
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
    return false;
  }

  localLogger.start();
  if(windowType == WindowType.MAIN_WINDOW){
    ChildProcessController().start();
  }
  else{
    ChildProcess().start();
    ChildProcess().signalReady();
  }
  return true;
}