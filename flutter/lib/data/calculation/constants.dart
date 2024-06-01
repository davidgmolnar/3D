import 'dart:math';

import '../../io/file_system.dart';
import '../../io/logger.dart';
import 'unit.dart';

const String parameterPath = "CalculationParameters/";

const Map<String, num> __constants = {
  "PI" : pi,
  "2PI": 2 * pi,
  "PI/2": pi / 2,
  "E": e,
  "G": 9.80665,
  "LN2": ln2,
  "RAD2DEG": 180 / pi,
  "DEG2RAD": pi / 180,
};

abstract class Const{
  static final Map<String, num> __parameters = {};

  static bool parameterIsConstant(final String parameter){
    return __constants.keys.contains(parameter.toUpperCase());
  }

  static Map<String, num> get parameters => {}..addAll(__constants)..addAll(__parameters);

  static void loadParameters(Map<String, num> loadedParameters){
    for(String key in loadedParameters.keys){
      __parameters[key.toUpperCase()] = loadedParameters[key]!;
    }
    __syncToDisk();
  }

  static void addParameter(final String key, final num value){
    __parameters[key.toUpperCase()] = value;
    __syncToDisk();
  }

  static void removeParameter(final String key){
    __parameters.remove(key.toUpperCase());
    __syncToDisk();
  }

  static void __syncToDisk(){
    FileSystem.trySaveMapToLocalAsync(parameterPath, "calculation_parameters.json", __parameters);
  }

  static void loadFromDisk(){
    clearParameters();
    Map<String, num> loaded = FileSystem.tryLoadMapFromLocalSync(parameterPath, "calculation_parameters.json").cast<String, num>();
    loadParameters(loaded);
  }

  static void clearParameters() {
    __parameters.clear();
    __syncToDisk();
  }

  static bool parsable(final String str){
    if(str[0] == '@'){
      if(__constants.keys.contains(str.substring(1).toUpperCase())){
        return true;
      }
      return false;
    }
    else if(str.toUpperCase().startsWith("PARAMETERS.")){
      return true;
    }
    else if(str.startsWith("FAVG")){
      if(int.tryParse(str.substring(4)) != null){
        return true;
      }
      else{
        final String rest = str.substring(4);
        for(int i = 0; i < rest.length - 1; i++){
          if(double.tryParse(rest.substring(0, rest.length - i)) != null){
            String maybeUnit = rest.substring(rest.length - i);
            if(maybeUnit.toUpperCase() == "SEC"){
              maybeUnit = "s";
            }
            return Units.values.map((e) => e.name).contains(maybeUnit);
          }
        }
        return false;
      }
    }
    else if(["<", ">", "=", "<=", ">=", "<>", "!="].contains(str)){
      return true;
    }
    else if(str.toUpperCase().startsWith("DIM=")){
      String maybeUnit = str.substring(5, str.length - 1);
      if(maybeUnit.toUpperCase() == "SEC"){
        maybeUnit = "s";
      }
      else if(maybeUnit == "km/h"){
        return true;
      }
      return Units.values.map((e) => e.name).contains(maybeUnit);
    }
    else{
      num? res = num.tryParse(str);
      if(res != null){
        return true;
      }

      for(int i = 0; i < str.length - 1; i++){
        if(double.tryParse(str.substring(0, str.length - i)) != null){
          String maybeUnit = str.substring(str.length - i);
          if(maybeUnit.toUpperCase() == "SEC"){
            maybeUnit = "s";
          }
          else if(maybeUnit == "km/h"){
            return true;
          }
          return Units.values.map((e) => e.name).contains(maybeUnit);
        }
      }
      return false;

    }
  }

  static num parse(final String str, Function(LogEntry) onError){
    if(str[0] == '@'){
      final p = str.substring(1).toUpperCase();
      if(__constants.containsKey(p)){
        return __constants[p]!;
      }
      else{
        onError(LogEntry.error("Constant $str was not predefined, skipping instruction"));
        return 0;
      }
    }

    else if(str.toUpperCase().startsWith("PARAMETERS.")){
      final p = str.substring(11).toUpperCase();
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