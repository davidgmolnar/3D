import 'dart:math';

import '../../io/logger.dart';
import '../data.dart';
import '../signal_container.dart';
import 'calculation_script_parsing.dart';
import 'constants.dart';
import 'unit.dart';

class CalculationOptions{
  final bool cleanRebuild;
  final String measurement;
  final int sampleTimeMs;

  CalculationOptions({
    required this.cleanRebuild,
    required this.measurement,
    required this.sampleTimeMs
  });

  CalculationOptions copyWith({bool? cleanRebuild, String? measurement, int? sampleTimeMs}){
    return CalculationOptions(
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

  static CalculationOptions? fromJson(Map json){
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
      return CalculationOptions(cleanRebuild: json["cr"], measurement: json["meas"], sampleTimeMs: json["st"]);
    }
  }
}

class CalculationScriptProcessor{
  static Future<void> exec(final List<List<FrozenInstruction>> script, final CalculationOptions options, {Function(double, String?)? progressIndication, int? indicationCount}) async {
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
            progressIndication((instNo.toDouble() / fullLen.toDouble()), entry.asString("CALCULATION"));
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
            progressIndication((instNo.toDouble() / fullLen.toDouble()), entry.asString("CALCULATION"));
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
      progressIndication(1.0, entry.asString("CALCULATION"));
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  static LogEntry? __doInstruction(FrozenInstruction inst, CalculationOptions options){
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
        return __oneOperandBaseWithLookAhead(inst, options, (p0, p1, p2) => (p1.value - p0.value) / (p1.timeStamp - p0.timeStamp) * 1000.0, (p0) => 0, (p0) => unitDiv(p0, const Unit(scalar: 1, components: {Units.s: 1})));
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
        return __oneOperandBaseWithLookAhead(inst, options, (p0, p1, p2) => p2.value + (p0.value + p1.value) / 2 * (p1.timeStamp - p0.timeStamp) / 1000.0, (p0) => 0, (p0) => unitMult(p0, const Unit(scalar: 1, components: {Units.s: 1})));
      /*case Operation.RCLP:
        return 2;
      case Operation.CONST:
        return 2;*/
      default:
        throw Exception("Operation ${inst.op} execution not implemented");
    }
  }

  static int __commonStartTime(final FrozenInstruction inst, final CalculationOptions options){
    int maxTime = -double.maxFinite.toInt();
    for(final String ch in inst.operands){
      final int chMinTime = signalData[options.measurement]![ch.substring(1)]!.values.first.timeStamp;
      if(chMinTime > maxTime){
        maxTime = chMinTime;
      }
    }
    return maxTime;
  }

  static int __commonEndTime(final FrozenInstruction inst, final CalculationOptions options){
    int minTime = double.maxFinite.toInt();
    for(final String ch in inst.operands){
      final int chMaxTime = signalData[options.measurement]![ch.substring(1)]!.values.last.timeStamp;
      if(chMaxTime < minTime){
        minTime = chMaxTime;
      }
    }
    return minTime;
  }

  static void __commit(final String sig, final String meas, final List<Measurement> values, final Unit? unit){
    if(!signalData[meas]!.containsKey(sig)){
      signalData[meas]![sig] = SignalContainer(
        dbcName: sig,
        values: [],
        displayName: sig
      );
    }

    signalData[meas]![sig]!.values.clear();
    signalData[meas]![sig]!.values.addAll(values);

    if(unit != null){
      signalData[meas]![sig]!.unit = unit;
    }
  }

  static LogEntry? __twoOperandBase(final FrozenInstruction inst, final CalculationOptions options, final num Function(num, num) op, final Unit? Function(Unit?, Unit?)? resultUnit){
    final List<Measurement> values = [];
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

      for(final Measurement point in signalData[options.measurement]![channelOperand]!.values){
        values.add(Measurement(op(point.value, constantvalue), point.timeStamp));
        if(values.last.value.isNaN || values.last.value.isInfinite){
          return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
        }
      }

      __commit(inst.result, options.measurement, values, signalData[options.measurement]![channelOperand]!.unit);
      
    }
    else if(inst.numberOfChannelParameters == 2){
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

        late final num p0;
        late final num p1;
        if(p0Index == 0){
          p0 = signalData[options.measurement]![op0]!.values[p0Index].value;
        }
        else{
          p0 = signalData[options.measurement]![op0]!.values[p0Index - 1].interpAt(
            signalData[options.measurement]![op0]!.values[p0Index], time
          );
        }
        
        if(p1Index == 0){
          p1 = signalData[options.measurement]![op1]!.values[p0Index].value;
        }
        else{
          p1 = signalData[options.measurement]![op1]!.values[p1Index - 1].interpAt(
            signalData[options.measurement]![op1]!.values[p1Index], time
          );
        }
        values.add(Measurement(op(p0, p1), time));

        if(values.last.value.isNaN || values.last.value.isInfinite){
          return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
        }
      }

      final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![op0]!.unit, signalData[options.measurement]![op1]!.unit): null; 
      __commit(inst.result, options.measurement, values, unit);
    }

    return null;
  }

  static LogEntry? __oneOperandBase(final FrozenInstruction inst, final CalculationOptions options, final num Function(num) op){
    final List<Measurement> values = [];
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    for(final Measurement point in signalData[options.measurement]![channelOperand]!.values){
      values.add(Measurement(op(point.value), point.timeStamp));

      if(values.last.value.isNaN || values.last.value.isInfinite){
        return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
      }
    }

    __commit(inst.result, options.measurement, values, signalData[options.measurement]![channelOperand]!.unit);
    return null;
  }
//                                                                                                                                  logvalue1    logvalue2    prev calc
  static LogEntry? __oneOperandBaseWithLookAhead(final FrozenInstruction inst, final CalculationOptions options, final num Function(Measurement, Measurement, Measurement) op, final num Function(num) initialValue, final Unit? Function(Unit?)? resultUnit){
    final List<Measurement> values = [];
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    Measurement previousValue = signalData[options.measurement]![channelOperand]!.values[0];
    values.add(Measurement(initialValue(signalData[options.measurement]![channelOperand]!.values[0].value), signalData[options.measurement]![channelOperand]!.values[0].timeStamp));
    for(int i = 1; i < signalData[options.measurement]![channelOperand]!.values.length; i++){
      values.add(Measurement(op(previousValue, signalData[options.measurement]![channelOperand]!.values[i], values.last), signalData[options.measurement]![channelOperand]!.values[i].timeStamp));
      previousValue = signalData[options.measurement]![channelOperand]!.values[i];
      if(values.last.value.isNaN || values.last.value.isInfinite){
        return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
      }
    }

    final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![channelOperand]!.unit): null; 
    __commit(inst.result, options.measurement, values, unit);
    return null;
  }

  static LogEntry? __delete(final FrozenInstruction inst, final CalculationOptions options){
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