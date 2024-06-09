import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:characters/characters.dart';

import '../../io/logger.dart';
import '../../io/importer.dart';
import 'constants.dart';

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
  XNOR,
  // ignore: constant_identifier_names
  NOT,
  // ignore: constant_identifier_names
  ABS,
  // ignore: constant_identifier_names
  SQRT,
  // ignore: constant_identifier_names
  SHIFT,
  // ignore: constant_identifier_names
  POWER,
  // ignore: constant_identifier_names
  MOD,
  // ignore: constant_identifier_names
  SIN,
  // ignore: constant_identifier_names
  COS,
  // ignore: constant_identifier_names
  TAN,
  // ignore: constant_identifier_names
  ARCSIN,
  // ignore: constant_identifier_names
  ARCCOS,
  // ignore: constant_identifier_names
  ARCTAN,
  // ignore: constant_identifier_names
  ARCTAN2,
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
  MAX,
  // ignore: constant_identifier_names
  IF,
  // ignore: constant_identifier_names
  INTEGRATE,
  // ignore: constant_identifier_names
  RCLP,
  // ignore: constant_identifier_names
  CONST,
  // ignore: constant_identifier_names
  FILLFROMBOOL,
  // ignore: constant_identifier_names
  WORD,
  // ignore: constant_identifier_names
  LIMIT,
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
      case "XNOR":
        return Operation.XOR;
      case "NOT":
        return Operation.NOT;
      case "ABS":
        return Operation.ABS;
      case "SQRT":
        return Operation.SQRT;
      case "SHIFT":
        return Operation.SHIFT;
      case "POWER":
        return Operation.POWER;
      case "MOD":
        return Operation.MOD;
      case "SIN":
        return Operation.SIN;
      case "COS":
        return Operation.COS;
      case "TAN":
        return Operation.TAN;
      case "ARCSIN":
        return Operation.ARCSIN;
      case "ARCCOS":
        return Operation.ARCCOS;
      case "ARCTAN":
        return Operation.ARCTAN;
      case "ARCTAN2":
        return Operation.ARCTAN2;
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
      case "MAX":
        return Operation.MAX;
      case "IF":
        return Operation.IF;
      case "INTEGRATE":
        return Operation.INTEGRATE;
      case "RCLP":
        return Operation.RCLP;
      case "CONST":
        return Operation.CONST;
      case "FILLFROMBOOL":
        return Operation.FILLFROMBOOL;
      case "WORD":
        return Operation.WORD;
      case "LIMIT":
        return Operation.LIMIT;
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
      case Operation.XNOR:
        return 2;
      case Operation.NOT:
        return 1;
      case Operation.ABS:
        return 1;
      case Operation.SQRT:
        return 1;
      case Operation.SHIFT:
        return 2;
      case Operation.POWER:
        return 2;
      case Operation.MOD:
        return 2;
      case Operation.SIN:
        return 1;
      case Operation.COS:
        return 1;
      case Operation.TAN:
        return 1;
      case Operation.ARCSIN:
        return 1;
      case Operation.ARCCOS:
        return 1;
      case Operation.ARCTAN:
        return 1;
      case Operation.ARCTAN2:
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
      case Operation.MAX:
        return 2;
      case Operation.IF:
        return 5;
      case Operation.INTEGRATE:
        return 1;
      case Operation.RCLP:
        return 2;
      case Operation.CONST:
        return 2;
      case Operation.FILLFROMBOOL:
        return 2;
      case Operation.WORD:
        return 1;
      case Operation.LIMIT:
        return 3;
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

  int get numberOfChannelParameters => operands.fold(0, (previousValue, operand) => operand[0] == '#' ? previousValue + 1 : previousValue);

  Map<String, dynamic> toJson(){
    return {
      "result": result,
      "operands": operands,
      "op": op.index,
    };
  }

  static FrozenInstruction fromJson(Map data){
    return FrozenInstruction(result: data["result"], operands: data["operands"].cast<String>().toList(), op: Operation.values[data["op"]]);
  }
}

class CompiledCalculation{
  final String filename;
  final DateTime fileLastModified;
  final List<String> requiredChannels;
  final List<String> resultChannels;
  final List<List<FrozenInstruction>> instructions;
  final List<LogEntry> context;

  CompiledCalculation({
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
      "instructions": instructions.map((block) => block.map((inst) => inst.toJson()).toList()).toList()
    };
  }

  static CompiledCalculation? fromJson(Map data){
    try{
      return CompiledCalculation(
        filename: data["filename"],
        fileLastModified: DateTime.fromMillisecondsSinceEpoch(data["fileLastModified"]),
        requiredChannels: data["requiredChannels"].cast<String>().toList(),
        resultChannels: data["resultChannels"].cast<String>().toList(),
        instructions: data["instructions"].map((block) => block.map((inst) => FrozenInstruction.fromJson(inst)).cast<FrozenInstruction>().toList()).cast<List<FrozenInstruction>>().toList(),
        context: []
      );
    }
    catch(err){
      return null;
    }
  }
}

class CalculationScriptParser{

  static ParserState _state = ParserState.LINESTART;

  static Future<CompiledCalculation> run(File file, {Function(double, String?)? lineProgressIndication, int? indicationCount}) async {
    _state = ParserState.LINESTART;
    final bool doIndication = lineProgressIndication != null && indicationCount != null;
    List<LogEntry> context = [];

    final List<int> bytes = (await file.readAsBytes()).toList();
    final originalLength = bytes.length;
    final String str = Importer.safeUTF8Decode(bytes);
    final decodedLength = str.length;

    if(originalLength != decodedLength){
      final LogEntry entry = LogEntry.warning("${originalLength - decodedLength} non-UTF-8 characters were ignored in calculation file ${file.absolute.path}");
      context.add(entry);
      if(doIndication){
        lineProgressIndication(0, entry.asString("CALCULATION"));
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
      try{
        if(_state == ParserState.LINEFINISHED && instruction != Instruction()){
          if(instructions.isEmpty){
            instructions.add([]);
          }
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
                if(instruction.result.toUpperCase() == "IFEXISTS"){
                  instruction.result = "";
                  instruction.op = Operation.SKIPIF;
                  instruction.operands.add('');
                  _state = ParserState.OPERAND;
                }
                else if(instruction.result.toUpperCase() == "DELETE"){
                  instruction.result = "";
                  instruction.op = Operation.DELETE;
                  instruction.operands.add('');
                  _state = ParserState.OPERAND;
                }
                else{
                  final LogEntry entry = LogEntry.error("Interpretation for preprocessor token ${instruction.result} at line $lineNum not implemented, notify 3D responsible, token ignored");
                  context.add(entry);
                  if(doIndication){
                    lineProgressIndication(lineNum / lines.length, entry.asString("CALCULATION"));
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
                    lineProgressIndication(lineNum / lines.length, entry.asString("CALCULATION"));
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
      }catch(exc){
        final LogEntry entry = LogEntry.error("Error when parsing line $line: ${exc.toString()}");
        context.add(entry);
        if(doIndication){
          lineProgressIndication(lineNum / lines.length, entry.asString("CALCULATION"));
        }
      }
    } // for(String line in lines)

    if(_state == ParserState.LINEFINISHED && instruction != Instruction()){
      if(instructions.isEmpty){
        instructions.add([]);
      }
      instructions.last.add(instruction.freeze);
    }

    List<String> resultChannels = [];
    List<String> requiredChannels = [];
    List<String> optionalChannels = [];

    for(List<FrozenInstruction> blockInstructions in instructions){
      for(FrozenInstruction inst in blockInstructions){
        if(inst.op == Operation.SKIPIF){
          optionalChannels.add(inst.operands[0].substring(1));
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

    return CompiledCalculation(
      filename: file.absolute.path,
      fileLastModified: await file.lastModified(),
      requiredChannels: requiredChannels,
      resultChannels: resultChannels.where((element) => !requiredChannels.contains(element)).toList(),
      instructions: instructions,
      context: context
    );
  }

  static Future<bool> validate(CompiledCalculation script, {Function(double, String?)? lineProgressIndication}) async {
    bool valid = true;
    final bool doIndication = lineProgressIndication != null;

    int blockNum = 0;
    for(List<FrozenInstruction> blockInstructions in script.instructions){
      for(FrozenInstruction inst in blockInstructions){
        if(inst.op == Operation.WORD){
          if(inst.op.requiredParams() > inst.operands.length || inst.operands.length > 3){
            final LogEntry entry = LogEntry.error("Operation ${inst.op.name} in block $blockNum requires at least ${inst.op.requiredParams()}, at most 3 operands, ${inst.operands.length} given");
            script.context.add(entry);
            if(doIndication){
              lineProgressIndication(1, entry.asString("CALCULATION"));
              await Future.delayed(const Duration(milliseconds: 10));
            }
            valid = false;
          }
        }
        else if(inst.op.requiredParams() != inst.operands.length){
          final LogEntry entry = LogEntry.error("Operation ${inst.op.name} in block $blockNum requires ${inst.op.requiredParams()} operands, ${inst.operands.length} given");
          script.context.add(entry);
          if(doIndication){
            lineProgressIndication(1, entry.asString("CALCULATION"));
            await Future.delayed(const Duration(milliseconds: 10));
          }
          valid = false;
        }

        if(inst.numberOfChannelParameters != inst.operands.length){
          for(final String operand in inst.operands){
            if(operand[0] != '#' && inst.op != Operation.F){
              if(!Const.parsable(operand)){
                final LogEntry entry = LogEntry.error("Constant expression '$operand' in block $blockNum cannot be parsed, if this is unexpected, notify 3D responsible");
                script.context.add(entry);
                if(doIndication){
                  lineProgressIndication(1, entry.asString("CALCULATION"));
                  await Future.delayed(const Duration(milliseconds: 10));
                }
                valid = false;
              }
            }
          }
        }
      }
      blockNum++;
    }
    
    return valid;
  }
}