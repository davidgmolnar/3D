import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:characters/characters.dart';

import '../../io/logger.dart';
import '../../io/serializer.dart';

enum ParserState{
  // ignore: constant_identifier_names
  RESULT,
  // ignore: constant_identifier_names
  OP,
  // ignore: constant_identifier_names
  OPERAND,
  // ignore: constant_identifier_names
  COMMENT,
  // ignore: constant_identifier_names
  LINESTART,
  // ignore: constant_identifier_names
  LINEFINISHED,
}

enum Operation{
  // ignore: constant_identifier_names
  ADD,
  // ignore: constant_identifier_names
  SUB,
  // ignore: constant_identifier_names
  MULT,
  // ignore: constant_identifier_names
  DIV,
  // ignore: constant_identifier_names
  DERIVATE,
  // ignore: constant_identifier_names
  AND,
  // ignore: constant_identifier_names
  NAND,
  // ignore: constant_identifier_names
  OR,
  // ignore: constant_identifier_names
  NOR,
  // ignore: constant_identifier_names
  XOR,
  // ignore: constant_identifier_names
  NOT,
  // ignore: constant_identifier_names
  ABS,
  // ignore: constant_identifier_names
  SHIFT,
  // ignore: constant_identifier_names
  F,
  // ignore: constant_identifier_names
  NOP,
  // ignore: constant_identifier_names
  SKIPIF,
  // ignore: constant_identifier_names
  SET,
  // ignore: constant_identifier_names
  DELETE,
  // ignore: constant_identifier_names
  MIN,
  // ignore: constant_identifier_names
  IF,
  // ignore: constant_identifier_names
  INTEGRATE,
  // ignore: constant_identifier_names
  RCLP,
  // ignore: constant_identifier_names
  CONST,
}

extension FromString on Operation{
  Operation? tryParse(String str){
    switch (str.toUpperCase()) {
      case "+":
        return Operation.ADD;
      case "-":
        return Operation.SUB;
      case "*":
        return Operation.MULT;
      case "/":
        return Operation.DIV;
      case "DERIVATE":
        return Operation.DERIVATE;
      case "AND":
        return Operation.AND;
      case "NAND":
        return Operation.NAND;
      case "OR":
        return Operation.OR;
      case "NOR":
        return Operation.NOR;
      case "XOR":
        return Operation.XOR;
      case "NOT":
        return Operation.NOT;
      case "ABS":
        return Operation.ABS;
      case "SHIFT":
        return Operation.SHIFT;
      case "F":
        return Operation.F;
      case "NOT_PARSED":
        return Operation.NOP;
      // ignore: no_duplicate_case_values
      case "NOT_PARSED":
        return Operation.SKIPIF;
      case "SET":
        return Operation.SET;
      // ignore: no_duplicate_case_values
      case "NOT_PARSED":
        return Operation.DELETE;
      case "MIN":
        return Operation.MIN;
      case "IF":
        return Operation.IF;
      case "INTEGRATE":
        return Operation.INTEGRATE;
      case "RCLP":
        return Operation.RCLP;
      case "CONST":
        return Operation.CONST;
      default:
        return null;
    }
  }

  int requiredParams(){
    switch (this) {
      case Operation.ADD:
        return 2;
      case Operation.SUB:
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
        return 2;
      default:
        return 0;
    }
  }
}

class Instruction{
  String result = "";
  List<String> operands = [];
  Operation op = Operation.NOP;
  String opBuffer = "";

  void clear(){
    result = "";
    operands = [];
    op = Operation.NOP;
    opBuffer = "";
  }

  FrozenInstruction get freeze => FrozenInstruction(result: result, operands: operands, op: op);
}

class FrozenInstruction{
  final String result;
  final List<String> operands;
  final Operation op;

  FrozenInstruction({
    required this.result,
    required this.operands,
    required this.op
  });

  Map<String, dynamic> toJson(){
    return {
      "result": result,
      "operands": operands,
      "op": op.index,
    };
  }

  static FrozenInstruction fromJson(Map data){
    return FrozenInstruction(result: data["result"], operands: data["operands"], op: Operation.values[data["op"]]);
  }
}

class CompiledCalibration{
  final String filename;
  final DateTime fileLastModified;
  final List<String> requiredChannels;
  final List<String> resultChannels;
  final List<List<FrozenInstruction>> instructions;
  final List<LogEntry> context;

  CompiledCalibration({
    required this.filename,
    required this.fileLastModified,
    required this.requiredChannels,
    required this.resultChannels,
    required this.instructions,
    required this.context,
  });

  Map<String, dynamic> toJson(){
    return {
      "filename": filename,
      "fileLastModified": fileLastModified.millisecondsSinceEpoch,
      "requiredChannels": requiredChannels,
      "resultChannels": resultChannels,
      "instructions": instructions.map((block) => block.map((inst) => inst.toJson()))
    };
  }

  static CompiledCalibration? fromJson(Map data){
    try{
      return CompiledCalibration(
        filename: data["filename"],
        fileLastModified: DateTime.fromMillisecondsSinceEpoch(data["fileLastModified"]),
        requiredChannels: data["requiredChannels"],
        resultChannels: data["resultChannels"],
        instructions: data["instructions"].map((block) => block.map((inst) => FrozenInstruction.fromJson(inst))),
        context: []
      );
    }
    catch(err){
      return null;
    }
  }
}

class CalibrationScriptParser{

  static ParserState _state = ParserState.LINESTART;

  static Future<CompiledCalibration> run(File file, {Function(double, String?)? lineProgressIndication, int? indicationCount}) async {
    _state = ParserState.LINESTART;
    final bool doIndication = lineProgressIndication != null && indicationCount != null;
    List<LogEntry> context = [];

    final List<int> bytes = (await file.readAsBytes()).toList();
    final originalLength = bytes.length;
    final String str = Serializer.safeUTF8Decode(bytes);
    final decodedLength = str.length;

    if(originalLength != decodedLength){
      final LogEntry entry = LogEntry.error("${originalLength - decodedLength} non-UTF-8 characters were ignored in calibration file ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString("CALIBRATION"));
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    final List<String> lines = str.split('\n');

    final List<List<FrozenInstruction>> instructions = [];
    int lineNum = 0;
    late final int indicationStep;
    if(doIndication){
      indicationStep = lines.length ~/ indicationCount;
    }

    final Instruction instruction = Instruction();

    for(String line in lines){
      if(_state == ParserState.LINEFINISHED && instruction != Instruction()){
        instructions.last.add(instruction.freeze);
      }
      instruction.clear();

      _state = ParserState.LINESTART;
      lineNum++;
      if(line.isEmpty){
        continue;
      }

      if(doIndication && lineNum % indicationStep == 0){
        lineProgressIndication(lineNum / lines.length, null);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      line = line.trim();

      for(String char in line.characters){
        if(_state == ParserState.COMMENT){
          if(line.startsWith("[") && line.endsWith(']')){
            instructions.add([]);
          }
          _state = ParserState.LINESTART;
          break;
        }

        switch (_state) {

          case ParserState.LINESTART:
            if([";", "/", "["].contains(char)){
              _state = ParserState.COMMENT;
            }
            else{
              instruction.result += char;
              _state = ParserState.RESULT;
            }
            break;

          case ParserState.RESULT:
            if([" ", "="].contains(char)){
              _state = ParserState.OP;
            }
            else if(["("].contains(char)){
              if(instruction.result == "IfExists"){
                instruction.result = "";
                instruction.op = Operation.SKIPIF;
                instruction.operands.add('');
                _state = ParserState.OPERAND;
              }
              else if(instruction.result == "Delete"){
                instruction.result = "";
                instruction.op = Operation.DELETE;
                instruction.operands.add('');
                _state = ParserState.OPERAND;
              }
              else{
                final LogEntry entry = LogEntry.error("Interpretation for preprocessor token ${instruction.result} at line $lineNum not implemented, notify 3D responsible, token ignored");
                context.add(entry);
                if(doIndication){
                  lineProgressIndication(lineNum / lines.length, entry.asString("CALIBRATION"));
                  await Future.delayed(const Duration(milliseconds: 10));
                }
                _state = ParserState.COMMENT;
              }
            }
            else{
              instruction.result += char;
            }
            break;

          case ParserState.OP:
            if(["("].contains(char)){
              Operation? op = Operation.NOP;
              op = op.tryParse(instruction.opBuffer);
              if(op == null){
                final LogEntry entry = LogEntry.error("Interpretation for operation ${instruction.opBuffer} at line $lineNum not implemented, notify 3D responsible, operation ignored");
                context.add(entry);
                if(doIndication){
                  lineProgressIndication(lineNum / lines.length, entry.asString("CALIBRATION"));
                  await Future.delayed(const Duration(milliseconds: 10));
                }
                _state = ParserState.COMMENT;
              }
              else{
                instruction.op = op;
                instruction.operands.add('');
                _state = ParserState.OPERAND;
              }
            }
            else if(!([" ", "="].contains(char))){
              instruction.opBuffer += char;
            }
            break;
          
          case ParserState.OPERAND:
            if([")"].contains(char)){
              for(int i = 0; i < instruction.operands.length; i++){
                instruction.operands[i] = instruction.operands[i].replaceAll('(', '');
              }
              _state = ParserState.LINEFINISHED;
            }
            else if([","].contains(char)){
              instruction.operands.add('');
            }
            else if(!([",", " "].contains(char))){
              instruction.operands.last += char;
            }
            break;

          default:
            break;
        } // switch (_state) 
      } // for(String char in line.characters)
    } // for(String line in lines)

    List<String> resultChannels = [];
    List<String> requiredChannels = [];
    List<String> optionalChannels = [];

    for(List<FrozenInstruction> blockInstructions in instructions){
      for(FrozenInstruction inst in blockInstructions){
        if(inst.op == Operation.SKIPIF){
          optionalChannels.add(inst.operands[0]);
        }
        for(String operand in inst.operands){
          if(operand.startsWith("#")){
            operand = operand.substring(1);
            if(!resultChannels.contains(operand) && !requiredChannels.contains(operand) && !optionalChannels.contains(operand)){
              requiredChannels.add(operand);
            }
          }
        }
        if(inst.op == Operation.DELETE){
          if(inst.operands[0].startsWith("#")){
            resultChannels.remove(inst.operands[0].substring(1));
          }
        }
        else{
          if(!resultChannels.contains(inst.result) && inst.result.isNotEmpty){
            resultChannels.add(inst.result);
          }
        }
      }
    }

    return CompiledCalibration(
      filename: file.absolute.path,
      fileLastModified: await file.lastModified(),
      requiredChannels: requiredChannels,
      resultChannels: resultChannels.where((element) => !requiredChannels.contains(element)).toList(),
      instructions: instructions,
      context: context
    );
  }

  static Future<bool> validate(CompiledCalibration script, {Function(double, String?)? lineProgressIndication}) async {
    bool valid = true;
    final bool doIndication = lineProgressIndication != null;

    int blockNum = 0;
    for(List<FrozenInstruction> blockInstructions in script.instructions){
      for(FrozenInstruction inst in blockInstructions){
        if(inst.op.requiredParams() != inst.operands.length){
          final LogEntry entry = LogEntry.error("Operation ${inst.op.name} in block $blockNum requires ${inst.op.requiredParams()} operands, ${inst.operands.length} given");
          script.context.add(entry);
          if(doIndication){
            lineProgressIndication(1, entry.asString("CALIBRATION"));
            await Future.delayed(const Duration(milliseconds: 10));
          }
          valid = false;
        }
      }
      blockNum++;
    }
    
    return valid;
  }
}