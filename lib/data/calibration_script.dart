import '../io/logger.dart';
import 'data.dart';
import 'signal_container.dart';

// ignore: constant_identifier_names
const String ERR_SIGNAL_UNAVAILABLE = "ERR_SIGNAL_UNAVAILABLE";
// ignore: constant_identifier_names
const String ERR_OPERATION_UNKNOWN = "ERR_OPERATION_UNKNOWN";

class ScriptInstruction{
  final String line;

  const ScriptInstruction(this.line);

  static RegExp usedSignalRegexp = RegExp(r"#[a-zA-Z0-9_ ]+,");

  SignalContainer execute(String activeLog, Map<String, SignalContainer> localStack){
    String leftOperand = line.split("=").first;
    List<String> neededSignals = usedSignalRegexp.allMatches(line).map((e) { return e[0]!.trim(); }).toList();
    if(neededSignals.any((signal) => !localStack.containsKey(signal))){
      neededSignals.removeWhere((signal) => localStack.containsKey(signal));
      localLogger.error("Unknown signals found: $neededSignals");
      throw Exception(ERR_SIGNAL_UNAVAILABLE);
    }

    List<Measurement> values = [];
    // ...

    return SignalContainer(
      dbcName: leftOperand,
      displayName: leftOperand,
      values: values,
      // ha minden needed signalnak van unitja akkor ennek is lehet
    );
  }

}

class CalibrationScript{
  final List<ScriptInstruction> instructions;
  final String path;

  const CalibrationScript(this.instructions, this.path);

  Map<String, SignalContainer> execute(String activeLog) {
    Map<String, SignalContainer> localStack = signalData[activeLog]!;

    for(int i = 0; i < instructions.length; i++){
      try{
        SignalContainer line = instructions[i].execute(activeLog, localStack);
        localStack[line.dbcName] = line;
      }
      catch (exc){
        if(exc.toString() == ERR_SIGNAL_UNAVAILABLE){
          localLogger.error("Failed to execute script $path, signal unavailable at line $i");
        }
        if(exc.toString() == ERR_OPERATION_UNKNOWN){
          localLogger.error("Failed to execute script $path, operation unknown at line $i");
        }
        else{
          localLogger.error("Failed to execute script $path, unknown error at line $i");
        }
        return {};
      }
    }

    localStack.removeWhere((key, signalContainer) => signalContainer.values.isEmpty);
    return localStack;
  }
}