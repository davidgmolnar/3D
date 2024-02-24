import 'package:dart_eval/dart_eval.dart';

class Evaluation{
  final num value;
  final String? failResult;

  const Evaluation({required this.value, required this.failResult});
}

abstract class ConstEval{
  static const String __start = "import 'dart:math';\nnum main(){\nreturn ";
  static const String __end = ";\n}";

  static Evaluation run(final String expression){
    try{
      return Evaluation(
        value: eval("$__start$expression$__end", function: 'main'),
        failResult: null
      );
    }catch(ex){
      return Evaluation(value: 0, failResult: ex.toString());
    }
  }
}