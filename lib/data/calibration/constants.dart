import 'dart:math';

import '../../io/logger.dart';

abstract class Const{
  static final Map<String, num> __parameters = {
    "PI" : pi,
    "2PI": 2 * pi,
    "PI/2": pi / 2,
    "E": e,
    "G": 9.80665,
    "LN2": log(2),
    "RAD2DEG": 180 / pi,
    "DEG2RAD": pi / 180,
  };

  static void loadParameters(Map<String, num> parameters){
    for(String key in parameters.keys){
      __parameters[key] = parameters[key]!;
    }
  }

  static void clearParameters() {
    __parameters.clear();
    loadParameters({
      "PI" : pi,
      "2PI": 2 * pi,
      "PI/2": pi / 2,
      "E": e,
      "G": 9.80665,
      "LN2": log(2),
      "RAD2DEG": 180 / pi,
      "DEG2RAD": pi / 180,
    });
  }

  static bool parsable(final String str){
    if(str[0] == '@'){
      if(["@PI", "@2PI", "@PI/2", "@E", "@G", "@LN2", "@RAD2DEG", "@DEG2RAD"].contains(str.toUpperCase())){
        return true;
      }
      return false;
    }
    else if(str.startsWith("Parameters.")){
      return true;
    }
    else{
      return num.tryParse(str) != null;
    }
  }

  static num parse(final String str, Function(LogEntry) onError){
    if(str[0] == '@'){
      final p = str.substring(1);
      if(__parameters.containsKey(p)){
        return __parameters[p]!;
      }
      else{
        onError(LogEntry.error("Constant $str was not predefined, skipping instruction"));
        return 0;
      }
    }

    else if(str.startsWith("Parameters.")){
      final p = str.substring(11);
      if(__parameters.containsKey(p)){
        return __parameters[p]!;
      }
      else{
        onError(LogEntry.error("Parameter $str was not loaded, skipping instruction"));
        return 0;
      }
    }

    else{
      return num.parse(str);
    }
  }
}