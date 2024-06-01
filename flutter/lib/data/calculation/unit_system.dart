import '../../io/logger.dart';

typedef UnitAlias = String;

class UnitDescription{
  final List<String> representations;    // [s, sec, seconds]   |  [min, minutes]   |  [kg, kilogramms]
  final UnitAlias unitAlias;             // seconds             |  minutes          |  kilogramms
  final bool isSI;                       // true                |  false            |  true
  final String dim;                      // time                |  time             |  weight

  const UnitDescription({required this.unitAlias, required this.representations, required this.isSI, required this.dim});
}

class UnitConversionTable{
  final Map<UnitAlias, MapEntry<UnitAlias, double>> conversionsToSI = {};

  UnitConversionTable.load(List data){
    for(final Map conv in data){
      conversionsToSI[conv["from"]] = MapEntry(conv["to"], conv["amount"]);
    }
  }
}

class UnitCompositionTable{
  final Map<UnitAlias,   List<List<MapEntry<UnitAlias, int>>>> compositions = {};
  //        CompoundUnit [   [     {SimpleUnit: exponent},{SimpleUnit: exponent}],[{SimpleUnit: exponent},{SimpleUnit: exponent}]]

  UnitCompositionTable.load(List data){
    for(final Map comp in data){
      final UnitAlias to = comp["to"];
      final List<List<MapEntry<UnitAlias, int>>> compOptions = [];
      for(final Map compOption in comp["composition_options"]){
        compOptions.add([]);
        for(final MapEntry<UnitAlias, int> compOptionComponent in compOption.entries.cast<MapEntry<UnitAlias, int>>()){
          compOptions.last.add(compOptionComponent);
        }
      }
      compositions[to] = compOptions;
    }
  }
}

abstract class UnitSystem{
  static final List<UnitDescription> _unitDescriptions = [];
  static late final UnitConversionTable _conversionTable;
  static late final UnitCompositionTable _compositionTable;

  static bool load(Map data){
    bool success = true;
    try{
      for(Map desc in data["unit_descriptions"]){
        _unitDescriptions.add(UnitDescription(unitAlias: desc["alias"], representations: desc["representations"], isSI: desc["is_SI"], dim: desc["dim"]));
      }
    } catch (ex){
      success = false;
      localLogger.error("Failed to load unit system descriptions: $ex", doNoti: false);
    }

    try{
      _conversionTable = UnitConversionTable.load(data["conversions"]);
    }catch (ex){
      success = false;
      localLogger.error("Failed to load unit system conversion table: $ex", doNoti: false);
    }

    try{
      _compositionTable = UnitCompositionTable.load(data["compositions"]);
    }catch (ex){
      success = false;
      localLogger.error("Failed to load unit system composition table: $ex", doNoti: false);
    }


    if(!success){
      localLogger.error("Failed to load unit system");
      _unitDescriptions.clear();
      _conversionTable.conversionsToSI.clear();
      _compositionTable.compositions.clear();
      return false;
    }

    // TODO validation, eg all nonSI-s have conversions to SI in each found dim, or UnitComposition table only has SI(this is correctable though once conversiontable is valid)
    // TODO validate all unitaliases referenced in conversiontable and compositiontable have a description
    // TODO validate all unitdescriptions have the shortest representation first(correctable)
    return success;
  }
}
