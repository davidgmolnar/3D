import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_dbc_parser/dart_dbc_parser.dart';
import 'package:dart_dbc_parser/signal/dbc_signal.dart';

import '../../io/logger.dart';
import '../data.dart';
import '../settings.dart';
import '../signal_container.dart';
import '../typed_data_list_container.dart';
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

        final LogEntry? entry = await __doInstruction(inst, options);
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

  static Future<LogEntry?> __doInstruction(FrozenInstruction inst, CalculationOptions options) async {
    // TODO olyanok nincsenek megcsinálva h pl összeadsz fokot radiánnal akkor az jól jöjjön ki
    switch (inst.op) {
      case Operation.ADD:
        return await __twoOperandBase(inst, options, (p0, p1) => p0 + p1, null);
      case Operation.SUB:
        return await __twoOperandBase(inst, options, (p0, p1) => p0 - p1, null);
      case Operation.MULT:
        return await __twoOperandBase(inst, options, (p0, p1) => p0 * p1, (p0, p1) => unitMult(p0, p1));
      case Operation.DIV:
        return await __twoOperandBase(inst, options, (p0, p1) => p0 / p1, ((p0, p1) => unitDiv(p0, p1)));
      case Operation.DERIVATE: // TODO a zoh import ezt rendesen megbaszkodja
        return await __oneOperandBaseWithLookAhead(inst, options, (p0, t0, p1, t1, p2, t2) => (p1 - p0) / (t1 - t0) * 1000.0, (p0) => 0, (p0) => unitDiv(p0, const Unit(scalar: 1, components: {Units.s: 1})));
      case Operation.AND:
        return await __twoOperandBase(inst, options, (p0, p1) => p0.toInt() & p1.toInt(), null);
      case Operation.NAND:
        return await __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() & p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int nand
      case Operation.OR:
        return await __twoOperandBase(inst, options, (p0, p1) => p0.toInt() | p1.toInt(), null);
      case Operation.NOR:
        return await __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() | p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int nor
      case Operation.XOR:
        return await __twoOperandBase(inst, options, (p0, p1) => p0.toInt() ^ p1.toInt(), null);
      case Operation.XNOR:
        return await __twoOperandBase(inst, options, (p0, p1) => ~(p0.toInt() ^ p1.toInt()) & 0x7FFFFFFFFFFFFFFF, null); // 63 bit unsigned int xnor
      case Operation.NOT:
        return await __oneOperandBase(inst, options, (p0) => ~p0.toInt() & 0x7FFFFFFFFFFFFFFF); // 63 bit unsigned int not
      case Operation.ABS:
        return await __oneOperandBase(inst, options, (p0) => p0.abs());
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
        return await __twoOperandBase(inst, options, (p0, p1) => min(p0, p1), null);
      case Operation.MAX:
        return await __twoOperandBase(inst, options, (p0, p1) => max(p0, p1), null);
      /*case Operation.IF:
        return 5;*/
      case Operation.INTEGRATE:
        return await __oneOperandBaseWithLookAhead(inst, options, (p0, t0, p1, t1, p2, t2) => p2 + (p0 + p1) / 2 * (t1 - t0) / 1000.0, (p0) => 0, (p0) => unitMult(p0, const Unit(scalar: 1, components: {Units.s: 1})));
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
      final int chMinTime = signalData[options.measurement]![ch.substring(1)]!.timestamps.first.toInt();
      if(chMinTime > maxTime){
        maxTime = chMinTime;
      }
    }
    return maxTime;
  }

  static int __commonEndTime(final FrozenInstruction inst, final CalculationOptions options){
    int minTime = double.maxFinite.toInt();
    for(final String ch in inst.operands){
      final int chMaxTime = signalData[options.measurement]![ch.substring(1)]!.timestamps.last.toInt();
      if(chMaxTime < minTime){
        minTime = chMaxTime;
      }
    }
    return minTime;
  }

  static void __commit(final String sig, final String meas, final TypedDataListContainer<TypedData> values, final TypedDataListContainer<Uint32List> timestamps, final Unit? unit){
    if(!signalData[meas]!.containsKey(sig)){
      signalData[meas]![sig] = SignalContainer(
        dbcName: sig,
        values: TypedDataListContainer<Float32List>(list: Float32List(0)),
        timestamps: TypedDataListContainer<Uint32List>(list: Uint32List(0)),
        displayName: sig
      );
    }

    signalData[meas]![sig]!.values.clear();
    signalData[meas]![sig]!.timestamps.clear();
    signalData[meas]![sig]!.values.set(values);
    signalData[meas]![sig]!.timestamps.set(timestamps);

    if(unit != null){
      signalData[meas]![sig]!.unit = unit;
    }
  }

  static Future<DBCSignal?> __tryGetSignalByName(final String name) async {
    final List<String>? dbcPaths = SettingsProvider.get("dbc.pathlist")?.selection;
    if(dbcPaths != null && dbcPaths.isNotEmpty){
      DBCDatabase can = await DBCDatabase.loadFromFile(dbcPaths.map((e) => File(e)).toList());
      for(final Map<String, DBCSignal> msg in can.database.values){
        if(msg.keys.contains(name)){
          return msg[name]!;
        }
      }
    }
    return null;
  }

  static Future<TypedDataListContainer> __initializeValueContainer(final String name) async {
    DBCSignal? sig = await __tryGetSignalByName(name);
    if(sig == null){
      return TypedDataListContainer<Float32List>(list: Float32List(0));
    }
    else{
      return TypedDataListContainer.emptyFromDBC(sig);
    }
  }

  static num __interpAt(final num y1, final num t1, final num y2, final num t2, final num t){
    if(t1 <= t2){
      if(t == t1){
        return y1;
      }
      else if(t == t2){
        return y2;
      }
      else{
        return y1 + (y2 - y1) / (t2 - t1) * (t - t1);
      }
    }
    else{
      return __interpAt(y2, t2, y1, t1, t);
    }
  }

  static Future<LogEntry?> __twoOperandBase(final FrozenInstruction inst, final CalculationOptions options, final num Function(num, num) op, final Unit? Function(Unit?, Unit?)? resultUnit) async {
    final TypedDataListContainer values = await __initializeValueContainer(inst.result);
    final TypedDataListContainer<Uint32List> timestamps = TypedDataListContainer(list: Uint32List(0));
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

      for(int i = 0; i < signalData[options.measurement]![channelOperand]!.values.size; i++){
        values.pushBack(op(signalData[options.measurement]![channelOperand]!.values[i], constantvalue));
        timestamps.pushBack(signalData[options.measurement]![channelOperand]!.timestamps[i]);
        if(values.last.isNaN || values.last.isInfinite){
          return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
        }
      }

      __commit(inst.result, options.measurement, values, timestamps, signalData[options.measurement]![channelOperand]!.unit);
      
    }
    else if(inst.numberOfChannelParameters == 2){
      int time = __commonStartTime(inst, options);
      int endTime = __commonEndTime(inst, options);
      final String op0 = inst.operands[0].substring(1);
      final String op1 = inst.operands[1].substring(1);
      int p0Index = signalData[options.measurement]![op0]!.values.toList().indexWhere((point) => point.timeStamp >= time);
      int p1Index = signalData[options.measurement]![op1]!.values.toList().indexWhere((point) => point.timeStamp >= time);

      for(; time < endTime; time += options.sampleTimeMs){
        while(signalData[options.measurement]![op0]!.timestamps[p0Index] < time){
          p0Index++;
        }
        while(signalData[options.measurement]![op1]!.timestamps[p1Index] < time){
          p1Index++;
        }

        late final num p0;
        late final num p1;
        if(p0Index == 0){
          p0 = signalData[options.measurement]![op0]!.values[p0Index];
        }
        else{
          p0 = __interpAt(signalData[options.measurement]![op0]!.values[p0Index - 1],
                          signalData[options.measurement]![op0]!.timestamps[p0Index - 1],
                          signalData[options.measurement]![op0]!.values[p0Index],
                          signalData[options.measurement]![op0]!.timestamps[p0Index],
                          time);
        }
        
        if(p1Index == 0){
          p1 = signalData[options.measurement]![op1]!.values[p0Index];
        }
        else{
          p1 = __interpAt(signalData[options.measurement]![op1]!.values[p0Index - 1],
                          signalData[options.measurement]![op1]!.timestamps[p0Index - 1],
                          signalData[options.measurement]![op1]!.values[p0Index],
                          signalData[options.measurement]![op1]!.timestamps[p0Index],
                          time);
        }
        values.pushBack(op(p0, p1));
        timestamps.pushBack(time);

        if(values.last.isNaN || values.last.isInfinite){
          return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
        }
      }

      final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![op0]!.unit, signalData[options.measurement]![op1]!.unit): null; 
      __commit(inst.result, options.measurement, values, timestamps, unit);
    }

    return null;
  }

  static Future<LogEntry?> __oneOperandBase(final FrozenInstruction inst, final CalculationOptions options, final num Function(num) op) async {
    final TypedDataListContainer values = await __initializeValueContainer(inst.result);
    final TypedDataListContainer<Uint32List> timestamps = TypedDataListContainer(list: Uint32List(0));
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    for(int i = 0; i < signalData[options.measurement]![channelOperand]!.values.size; i++){
      values.pushBack(op(signalData[options.measurement]![channelOperand]!.values[i]));
      timestamps.pushBack(signalData[options.measurement]![channelOperand]!.timestamps[i]);

      if(values.last.isNaN || values.last.isInfinite){
        return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
      }
    }

    __commit(inst.result, options.measurement, values, timestamps, signalData[options.measurement]![channelOperand]!.unit);
    return null;
  }
//                                                                                                                                          logvalue1 logvalue2 prevcalc
  static Future<LogEntry?> __oneOperandBaseWithLookAhead(final FrozenInstruction inst, final CalculationOptions options, final num Function(num, int, num, int, num, int) op, final num Function(num) initialValue, final Unit? Function(Unit?)? resultUnit) async {
    final TypedDataListContainer values = await __initializeValueContainer(inst.result);
    final TypedDataListContainer<Uint32List> timestamps = TypedDataListContainer(list: Uint32List(0));
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("One operand operations must be called on a channel not a constant");
    }
    final String channelOperand = inst.operands[0].substring(1);

    num previousValue = signalData[options.measurement]![channelOperand]!.values[0];
    int previousTime = signalData[options.measurement]![channelOperand]!.timestamps[0].toInt();
    values.pushBack(initialValue(signalData[options.measurement]![channelOperand]!.values[0]));
    timestamps.pushBack(signalData[options.measurement]![channelOperand]!.timestamps[0]);
    for(int i = 1; i < signalData[options.measurement]![channelOperand]!.values.size; i++){
      values.pushBack(op(previousValue, previousTime, signalData[options.measurement]![channelOperand]!.values[i], signalData[options.measurement]![channelOperand]!.timestamps[i].toInt(), values.last, timestamps.last.toInt()));
      timestamps.pushBack(signalData[options.measurement]![channelOperand]!.timestamps[i]);
      previousValue = signalData[options.measurement]![channelOperand]!.values[i];
      if(values.last.isNaN || values.last.isInfinite){
        return LogEntry.error("NaN or Infinite result from instruction ${inst.op.name}");
      }
    }

    final Unit? unit = resultUnit != null ? resultUnit(signalData[options.measurement]![channelOperand]!.unit): null; 
    __commit(inst.result, options.measurement, values, timestamps, unit);
    return null;
  }

  static LogEntry? __delete(final FrozenInstruction inst, final CalculationOptions options){
    if(inst.numberOfChannelParameters != 1){
      return LogEntry.error("The delete operation needs a channel to be specified, not a constant");
    }
    
    final String channelOperand = inst.operands[0].substring(1);
    if(signalData[options.measurement]!.containsKey(channelOperand)){
      signalData[options.measurement]![channelOperand]!.values.clear();
      signalData[options.measurement]![channelOperand]!.timestamps.clear();
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