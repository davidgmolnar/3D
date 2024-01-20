import 'dart:math';

import '../../io/logger.dart';
import '../data.dart';
import '../signal_container.dart';
import 'calibration_script_parsing.dart';
import 'constants.dart';
import 'unit.dart';

class CalibrationOptions{
  final bool cleanRebuild;
  final String measurement;
  final int sampleTimeMs;

  CalibrationOptions({
    required this.cleanRebuild,
    required this.measurement,
    required this.sampleTimeMs
  });

  CalibrationOptions copyWith({bool? cleanRebuild, String? measurement, int? sampleTimeMs}){
    return CalibrationOptions(
      cleanRebuild: cleanRebuild ?? this.cleanRebuild,
      measurement: measurement ?? this.measurement,
      sampleTimeMs: sampleTimeMs ?? this.sampleTimeMs
    );
  }

  Map<String, dynamic> asJson(){
    return {
      "cr": cleanRebuild,
      "meas": measurement,
      "st": sampleTimeMs
    };
  }

  static CalibrationOptions? fromJson(Map json){
    if(!json.containsKey('meas') || json['meas'] is! String){
      return null;
    }
    else if(!json.containsKey('cr') || json['cr'] is! bool){
      return null;
    }
    else if(!json.containsKey('st') || json['st'] is! int){
      return null;
    }
    else{
      return CalibrationOptions(cleanRebuild: json["cr"], measurement: json["meas"], sampleTimeMs: json["st"]);
    }
  }
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
            lastIndicated = instNo;
            await Future.delayed(const Duration(milliseconds: 10));
          }
          else if(lastIndicated + indicationStep < instNo){
            progressIndication((instNo.toDouble() / fullLen.toDouble()), null);
            lastIndicated = instNo;
            await Future.delayed(const Duration(milliseconds: 10));
          }
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

    // TODO olyanok nincsenek megcsinálva h pl összeadsz fokot radiánnal akkor az jól jöjjön ki
    switch (inst.op) {
      case Operation.ADD:
        return __twoOperandBase(inst, options, (p0, p1) => p0 + p1, null);
      case Operation.SUB:
        return __twoOperandBase(inst, options, (p0, p1) => p0 - p1, null);
      case Operation.MULT:
        return __twoOperandBase(inst, options, (p0, p1) => p0 * p1, (p0, p1) => unitMult(p0, p1));
      case Operation.DIV:
        return __twoOperandBase(inst, options, (p0, p1) => p0 / p1, ((p0, p1) => unitDiv(p0, p1)));
      case Operation.DERIVATE: // TODO a zoh import ezt rendesen megbaszkodja
        return __oneOperandBaseWithLookAhead(inst, options, (p0, p1) => (p1.value - p0.value) / (p1.timeStamp - p0.timeStamp) * 1000.0, (p0) => 0, (p0) => unitDiv(p0, const Unit(scalar: 1, components: {Units.s: 1})));
      case Operation.AND:
        return __twoOperandBase(inst, options, (p0, p1) => p0.toInt() & p1.toInt(), null);
      case Operation.NAND:
        return __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() & p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int nand
      case Operation.OR:
        return __twoOperandBase(inst, options, (p0, p1) => p0.toInt() | p1.toInt(), null);
      case Operation.NOR:
        return __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() | p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int nor
      case Operation.XOR:
        return __twoOperandBase(inst, options, (p0, p1) => p0.toInt() ^ p1.toInt(), null);
      case Operation.XNOR:
        return __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() ^ p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int xnor
      case Operation.NOT:
        return __oneOperandBase(inst, options, (p0) => ~p0.toInt() & 0x7FFFFFFFFFFFFFFF); // 63 bit unsigned int not
      case Operation.ABS:
        return __oneOperandBase(inst, options, (p0) => p0.abs());
      /*case Operation.SHIFT:
        return 2;
      case Operation.F:
        return 2;*/
      case Operation.NOP:
        return null;
      case Operation.SKIPIF:
        return null;
      /*case Operation.SET:
        return 1;*/
      case Operation.DELETE:
        return __delete(inst, options);
      case Operation.MIN:
        return __twoOperandBase(inst, options, (p0, p1) => min(p0, p1), null);
      case Operation.MAX:
        return __twoOperandBase(inst, options, (p0, p1) => max(p0, p1), null);
      /*case Operation.IF:
        return 5;*/
      case Operation.INTEGRATE:
        return __oneOperandBaseWithLookAhead(inst, options, (p0, p1) => p0.value + (p0.value + p1.value) / 2 * (p1.timeStamp - p0.timeStamp) / 1000.0, (p0) => 0, (p0) => unitMult(p0, const Unit(scalar: 1, components: {Units.s: 1})));
      /*case Operation.RCLP:
        return 2;
      case Operation.CONST:
        return 2;*/
      default:
        throw Exception("Operation ${inst.op} execution not implemented");
    }
  }

  static int __commonStartTime(final FrozenInstruction inst, final CalibrationOptions options){
    int maxTime = double.negativeInfinity.toInt();
    for(final String ch in inst.operands){
      final int chMinTime = signalData[options.measurement]![ch]!.values.first.timeStamp;
      if(chMinTime > maxTime){
        maxTime = chMinTime;
      }
    }
    return maxTime;
  }

  static int __commonEndTime(final FrozenInstruction inst, final CalibrationOptions options){
    int minTime = double.infinity.toInt();
    for(final String ch in inst.operands){
      final int chMaxTime = signalData[options.measurement]![ch]!.values.last.timeStamp;
      if(chMaxTime < minTime){
        minTime = chMaxTime;
      }
    }
    return minTime;
  }

  static void __commit(final String sig, final String meas, final List<Measurement> values, final Unit? unit){
    signalData[meas]![sig]!.values.clear();
    signalData[meas]![sig]!.values.addAll(values);

    if(unit != null){
      signalData[meas]![sig]!.unit = unit;
    }
  }

  static LogEntry? __twoOperandBase(final FrozenInstruction inst, final CalibrationOptions options, final num Function(num, num) op, final Unit? Function(Unit?, Unit?)? resultUnit){
    if(inst.numberOfChannelParameters == 0){
      return LogEntry.error("Combining two constants via script is not recommended and therefore not implemented");
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
        point.value = op(point.value, constantvalue);
      }
      
    }
    else if(inst.numberOfChannelParameters == 2){
      final List<Measurement> values = [];
      int time = __commonStartTime(inst, options);
      int endTime = __commonEndTime(inst, options);
      final String op0 = inst.operands[0].substring(1);
      final String op1 = inst.operands[1].substring(1);
      int p0Index = signalData[options.measurement]![op0]!.values.indexWhere((point) => point.timeStamp >= time);
      int p1Index = signalData[options.measurement]![op1]!.values.indexWhere((point) => point.timeStamp >= time);

      for(; time < endTime; time += options.sampleTimeMs){
        while(signalData[options.measurement]![op0]!.values[p0Index].timeStamp < time){
          p0Index++;
        }
        while(signalData[options.measurement]![op1]!.values[p1Index].timeStamp < time){
          p1Index++;
        }

        final num p0 = signalData[options.measurement]![op0]!.values[p0Index - 1].interpAt(
          signalData[options.measurement]![op0]!.values[p0Index], time
        );
        final num p1 = signalData[options.measurement]![op1]!.values[p1Index - 1].interpAt(
          signalData[options.measurement]![op1]!.values[p1Index], time
        );
        values.add(Measurement(op(p0, p1), time));
      }

      final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![op0]!.unit, signalData[options.measurement]![op1]!.unit): null; 
      __commit(inst.result, options.measurement, values, unit);
    }

    return null;
  }

  static LogEntry? __oneOperandBase(final FrozenInstruction inst, final CalibrationOptions options, final num Function(num) op){
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    if(inst.result != channelOperand){
      signalData[options.measurement]![inst.result] = signalData[options.measurement]![channelOperand]!;
    }
    for(final Measurement point in signalData[options.measurement]![inst.result]!.values){
      point.value = op(point.value);
    }
    return null;
  }

  static LogEntry? __oneOperandBaseWithLookAhead(final FrozenInstruction inst, final CalibrationOptions options, final num Function(Measurement, Measurement) op, final num Function(num) initialValue, final Unit? Function(Unit?)? resultUnit){
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    if(inst.result != channelOperand){
      signalData[options.measurement]![inst.result] = signalData[options.measurement]![channelOperand]!;
    }
    Measurement previousValue = signalData[options.measurement]![inst.result]!.values[0];
    signalData[options.measurement]![inst.result]!.values[0].value = initialValue(signalData[options.measurement]![inst.result]!.values[0].value);
    for(int i = 1; i < signalData[options.measurement]![inst.result]!.values.length; i++){
      num newPoint = op(previousValue, signalData[options.measurement]![inst.result]!.values[i]);
      previousValue = signalData[options.measurement]![inst.result]!.values[i];
      signalData[options.measurement]![inst.result]!.values[i].value = newPoint;
    }

    final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![channelOperand]!.unit): null; 
    if(unit == null){
      signalData[options.measurement]![inst.result]!.unit = unit;
    }
    return null;
  }

  static LogEntry? __delete(final FrozenInstruction inst, final CalibrationOptions options){
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("The delete operation needs a channel to be specified, not a constant");
    }
    
    final String channelOperand = inst.operands[0].substring(1);
    if(signalData[options.measurement]!.containsKey(channelOperand)){
      signalData[options.measurement]![channelOperand]!.values.clear();
      signalData[options.measurement]!.remove(channelOperand);
      return null;
    }
    else{
      return LogEntry.error("The channel $channelOperand does not exist in measurement ${options.measurement}");
    }
  }

  // __set

  // __shift

  // __const

  // __if

  // __f
}