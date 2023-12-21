import '../../io/logger.dart';
import '../data.dart';
import '../signal_container.dart';
import 'calibration_script_parsing.dart';

class CalibrationOptions{
  final bool cleanRebuild;
  final String measurement;
  final int sampleTime;

  CalibrationOptions({
    required this.cleanRebuild,
    required this.measurement,
    required this.sampleTime
  });
}

class CalibrationScriptProcessor{
  static void exec(final List<List<FrozenInstruction>> script, final CalibrationOptions options, {Function(double, String?)? progressIndication, int? indicationCount}) async {
    final bool doIndication = progressIndication != null && indicationCount != null;
    int instNo = 0;
    int blockNo = 0;
    late final int indicationStep;
    int lastIndicated = 0;
    final int fullLen = script.fold(0, (previousValue, block) => previousValue + block.length);
    if(doIndication){
      indicationStep = (fullLen.toDouble() / indicationCount).ceil();
    }

    for(List<FrozenInstruction> block in script){
      blockNo++;
      for(FrozenInstruction inst in block){
        instNo++;
        if(inst.op == Operation.SKIPIF && !signalData[options.measurement]!.containsKey(inst.operands[0].substring(1))){
          final LogEntry entry = LogEntry.warning("Skipping $blockNo. block, as ${inst.operands[0].substring(1)} signal did not exist in measurement ${options.measurement}");
          localLogger.add(entry);
          if(doIndication){
            progressIndication((instNo.toDouble() / fullLen.toDouble()), entry.asString("CALIBRATION"));
            lastIndicated = instNo;
            await Future.delayed(const Duration(milliseconds: 10));
          }
          instNo += block.length - block.indexOf(inst) - 1;
          break;
        }
        __doInstruction(inst, options);
        if(doIndication && lastIndicated + indicationStep < instNo){
          progressIndication((instNo.toDouble() / fullLen.toDouble()), null);
          lastIndicated = instNo;
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    }

    final LogEntry entry = LogEntry.info("Script successfully executed");
    localLogger.add(entry);
    if(doIndication){
      progressIndication(1.0, entry.asString("CALIBRATION"));
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  static void __doInstruction(FrozenInstruction inst, CalibrationOptions options){
    if(!signalData[options.measurement]!.containsKey(inst.result)){
      signalData[options.measurement]![inst.result] = SignalContainer(
        dbcName: inst.result,
        values: [],
        displayName: inst.result
      );
    }

    // getcommontimeindexes

    switch (inst.op) {
      case Operation.ADD:
        return __add(inst, options/* getcommontimeindexes */);
      /*case Operation.SUB:
        return 2;
      case Operation.MULT:
        return 2;
      case Operation.DIV:
        return 2;
      case Operation.DERIVATE:
        return 1;
      case Operation.AND:
        return 2;
      case Operation.NAND:
        return 2;
      case Operation.OR:
        return 2;
      case Operation.NOR:
        return 2;
      case Operation.XOR:
        return 2;
      case Operation.NOT:
        return 1;
      case Operation.ABS:
        return 1;
      case Operation.SHIFT:
        return 2;
      case Operation.F:
        return 2;
      case Operation.NOP:
        return 0;
      case Operation.SKIPIF:
        return 1;
      case Operation.SET:
        return 1;
      case Operation.DELETE:
        return 1;
      case Operation.MIN:
        return 2;
      case Operation.IF:
        return 5;
      case Operation.INTEGRATE:
        return 1;
      case Operation.RCLP:
        return 2;
      case Operation.CONST:
        return 2;*/
      default:
        throw Exception("Operation ${inst.op} execution not implemented");
    }
  }

  static void __add(FrozenInstruction inst, CalibrationOptions options/* getcommontimeindexes */){

  }
}