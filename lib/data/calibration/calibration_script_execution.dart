import '../../io/logger.dart';
import '../data.dart';
import '../signal_container.dart';
import 'calibration_script_parsing.dart';
import 'constants.dart';

class CalibrationOptions{
  final bool cleanRebuild;
  final String measurement;
  final int sampleTimeMs;

  CalibrationOptions({
    required this.cleanRebuild,
    required this.measurement,
    required this.sampleTimeMs
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

        final LogEntry? entry = __doInstruction(inst, options);
        if(entry != null){
          localLogger.add(entry);
        }

        if(doIndication){
          if(entry != null){
            progressIndication((instNo.toDouble() / fullLen.toDouble()), entry.asString("CALIBRATION"));
          }
          else if(lastIndicated + indicationStep < instNo){
            progressIndication((instNo.toDouble() / fullLen.toDouble()), null);
          }
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

  static LogEntry? __doInstruction(FrozenInstruction inst, CalibrationOptions options){
    if(!signalData[options.measurement]!.containsKey(inst.result)){
      signalData[options.measurement]![inst.result] = SignalContainer(
        dbcName: inst.result,
        values: [],
        displayName: inst.result
      );
    }

    switch (inst.op) {
      case Operation.ADD:
        return __add(inst, options);
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

  static int __commonStartTime(final FrozenInstruction inst, final CalibrationOptions options){
    int minTime = double.infinity.toInt();
    for(final String ch in inst.operands){
      final int chMinTime = signalData[options.measurement]![ch]!.values.first.timeStamp;
      if(chMinTime < minTime){
        minTime = chMinTime;
      }
    }
    return minTime;
  }

  static int __commonEndTime(final FrozenInstruction inst, final CalibrationOptions options){
    int maxTime = double.negativeInfinity.toInt();
    for(final String ch in inst.operands){
      final int chMaxTime = signalData[options.measurement]![ch]!.values.last.timeStamp;
      if(chMaxTime > maxTime){
        maxTime = chMaxTime;
      }
    }
    return maxTime;
  }

  static void __commit(final String sig, final String meas, final List<Measurement> values){
    signalData[meas]![sig]!.values.clear();
    signalData[meas]![sig]!.values.addAll(values);
  }

  static LogEntry? __add(final FrozenInstruction inst, final CalibrationOptions options){
    // ide kell egy közös idő starttól kezdve options.sampletime enkénti interp meas iterálás (nem resampled copy) a signalokra, ha csak egy akkor nem commit van hanem elementwise add konstanssal

    if(inst.numberOfChannelParameters == 0){
      return LogEntry.warning("Adding two constants via script is not recommended and not implemented");
    }
    else if(inst.numberOfChannelParameters == 1){
      final String channelOperand = inst.operands.firstWhere((element) => element[0] == '#').substring(1);
      final String constantOperand = inst.operands.firstWhere((element) => element[0] != '#');
      LogEntry? constParseError;
      final num constantvalue = Const.parse(constantOperand, ((entry) {
        constParseError = entry;
      }));

      if(constParseError != null){
        return constParseError;
      }

      if(inst.result != channelOperand){
        signalData[options.measurement]![inst.result] = signalData[options.measurement]![channelOperand]!;
      }
      for(final Measurement point in signalData[options.measurement]![inst.result]!.values){
        point.value += constantvalue;
      }
      
    }
    else if(inst.numberOfChannelParameters == 2){
      final List<Measurement> values = [];
      int time = __commonStartTime(inst, options);
      int endTime = __commonStartTime(inst, options);
      for(; time < endTime; time += options.sampleTimeMs){
        // interp ch1 value
        // interp ch2 value
        // values.add(Measurement(interp1+interp2, time))
      }
      __commit(inst.result, options.measurement, values);
    }

    return null;
  }
}