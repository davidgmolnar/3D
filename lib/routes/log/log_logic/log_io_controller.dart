import '../../../data/updateable_valuenotifier.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';

class LogIOInfo{
  String? processingFile;
  bool error = false;
  bool processing = false;
  int filesLoaded = 0;
  double linePercentage = 0;
  List<String> context = [];
  List<String> selectedPaths = [];
  List<String?> measurementAliases = [];
}

class LogIOInfoController{
  static final UpdateableValueNotifier<LogIOInfo> logIOInfoNotifier = UpdateableValueNotifier<LogIOInfo>(LogIOInfo());

  static final List<String> _extensions = [];

  static Future<void> sendFilesToMaster() async {
    final Map<String, Map<String, String>> request = {};
    for(int i = 0; i < logIOInfoNotifier.value.selectedPaths.length; i++){
      request[i.toString()] = {"path": logIOInfoNotifier.value.selectedPaths[i], "alias": logIOInfoNotifier.value.measurementAliases[i] ?? logIOInfoNotifier.value.selectedPaths[i].replaceAll('\\', '/').split('/').last};
    }

    ChildProcess.send(Response(localSocketPort, ResponseType.FINISHED, ResponseFinishable(ResponseFinishableType.IMPORT_LOG, request).asJson));
  }

  static void setLinePercentage(final double linePercentage){
    logIOInfoNotifier.update((value) {
      value.linePercentage = linePercentage;
    });
  }

  static void addToContext(final String entry){
    logIOInfoNotifier.update((value) {
      value.context.add(entry);
      if(entry.contains("ERROR")){
        value.error = true;
      }
      if(entry.contains("Successfully loaded") || entry.contains('skipping file')){
        value.filesLoaded++;
        if(value.filesLoaded == value.selectedPaths.length){
          value.processing = false;
        }
      }
    });
  }  

  static void reset(){
    _extensions.clear();
    logIOInfoNotifier.update((value) {
      value.processingFile = null;
      value.error = false;
      value.filesLoaded = 0;
      value.linePercentage = 0;
      value.context = [];
      value.selectedPaths = [];
      value.processing = false;
      value.measurementAliases = [];
    });
  }
}

