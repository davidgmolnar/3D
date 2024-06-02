import 'dart:math';

import '../../io/file_system.dart';
import '../../io/logger.dart';

typedef UnitAlias = String;

class UnitDescription{
  final List<String> representations;    // [s, sec, seconds]   |  [min, minutes]   |  [kg, kilogramms]
  final bool isBase;                     // true                |  false            |  true
  final String dim;                      // time                |  time             |  weight

  const UnitDescription({required this.representations, required this.isBase, required this.dim});

  @override
  String toString() {
    return representations.first;
  }
}

class ConversionHelper{
  final UnitAlias to;
  final int? power;
  final double? multiplier;
  final double? offset;

  ConversionHelper({required this.to, required this.power, required this.multiplier, required this.offset});
}

class UnitConversionTable{
  final Map<UnitAlias, ConversionHelper> conversionsToBase = {};

  List toJson(){
    return conversionsToBase.entries.map((entry) => {
      "from": entry.key,
      "to": entry.value.to,
      if(entry.value.power != null)
        "power": entry.value.power
      else if(entry.value.multiplier != null)
        "multiplier": entry.value.multiplier
      else if(entry.value.offset != null)
        "offset": entry.value.offset
    }).toList();
  }
}

class UnitCompositionTable{
  final Map<UnitAlias,   List<List<MapEntry<UnitAlias, int>>>> compositions = {};
  //        CompoundUnit [   [     {SimpleUnit: exponent},{SimpleUnit: exponent}],[{SimpleUnit: exponent},{SimpleUnit: exponent}]]

  void load(List data){
    for(final Map comp in data){
      final List<List<MapEntry<UnitAlias, int>>> compOptions = [];
      for(final Map compOption in comp["composition_options"]){
        compOptions.add([]);
        for(final MapEntry<UnitAlias, int> compOptionComponent in compOption.cast<UnitAlias, int>().entries){
          compOptions.last.add(compOptionComponent);
        }
      }
      compositions[comp["to"]] = compOptions;
    }
  }

  List toJson(){
    return compositions.entries.map((entry) => {
      "to": entry.key,
      "composition_options": entry.value.map((e) => 
        Map.fromEntries(e)
      ).toList()
    }).toList();
  }
}

abstract class UnitSystem{
  static final Map<UnitAlias, UnitDescription> _unitDescriptions = {};
  static final UnitConversionTable _conversionTable = UnitConversionTable();
  static final UnitCompositionTable _compositionTable = UnitCompositionTable();

  static void _syncToDisk(){
    Map jsonEncodeable = {};

    jsonEncodeable["unit_descriptions"] = _unitDescriptions.entries.map((desc) => {
      desc.key: {
        "representations": desc.value.representations,
        "is_base": desc.value.isBase,
        "dim": desc.value.dim
      }
    }).toList();

    jsonEncodeable["conversions"] = _conversionTable.toJson();
    jsonEncodeable["compositions"] = _compositionTable.toJson();

    FileSystem.trySaveMapToLocalAsync(FileSystem.unitSystemDir, "unit_system.json", jsonEncodeable, withIndent: true);
  }

  static void _loadDefaults(){
    _unitDescriptions.addAll(const {
      "millimeters": UnitDescription(representations: ["mm"], isBase: false, dim: "length"),
      "meters": UnitDescription(representations: ["m"], isBase: true, dim: "length"),
      "kilometers": UnitDescription(representations: ["km"], isBase: false, dim: "length"),

      "milliseconds": UnitDescription(representations: ["ms"], isBase: false, dim: "time"),
      "seconds": UnitDescription(representations: ["s", "sec"], isBase: true, dim: "time"),
      "minutes": UnitDescription(representations: ["min"], isBase: false, dim: "time"),
      "hours": UnitDescription(representations: ["h"], isBase: false, dim: "time"),
      
      "gramms": UnitDescription(representations: ["g"], isBase: false, dim: "mass"),
      "kilogramms": UnitDescription(representations: ["kg"], isBase: true, dim: "mass"),

      "newtons": UnitDescription(representations: ["N"], isBase: true, dim: "force"),
      "kilonewtons": UnitDescription(representations: ["kN"], isBase: false, dim: "force"),

      "milliampere": UnitDescription(representations: ["mA"], isBase: false, dim: "current"),
      "ampere": UnitDescription(representations: ["A"], isBase: true, dim: "current"),

      "millivolts": UnitDescription(representations: ["mV"], isBase: false, dim: "voltage"),
      "volts": UnitDescription(representations: ["V"], isBase: true, dim: "voltage"),

      "milliwatts": UnitDescription(representations: ["mW"], isBase: false, dim: "power"),
      "watts": UnitDescription(representations: ["W"], isBase: true, dim: "power"),
      "kilowatts": UnitDescription(representations: ["kW"], isBase: false, dim: "power"),

      "kelvins": UnitDescription(representations: ["K"], isBase: true, dim: "temperature"),
      "celsius": UnitDescription(representations: ["°C"], isBase: false, dim: "temperature"),
      
      "joules": UnitDescription(representations: ["J"], isBase: true, dim: "energy"),
      "kilojoules": UnitDescription(representations: ["kJ"], isBase: false, dim: "energy"),
      
      "pascals": UnitDescription(representations: ["Pa"], isBase: true, dim: "pressure"),
      "bars": UnitDescription(representations: ["bar"], isBase: false, dim: "pressure"),

      "radians": UnitDescription(representations: ["rad"], isBase: true, dim: "angle"),
      "degrees": UnitDescription(representations: ["°", "deg"], isBase: false, dim: "angle"),
  });

    _conversionTable.conversionsToBase.addAll({
      "millimeters": ConversionHelper(to: "meters", power: null, multiplier: 0.001, offset: null),
      "kilometers": ConversionHelper(to: "meters", power: null, multiplier: 1000, offset: null),

      "milliseconds": ConversionHelper(to: "seconds", power: null, multiplier: 0.001, offset: null),
      "minutes": ConversionHelper(to: "seconds", power: null, multiplier: 60, offset: null),
      "hours": ConversionHelper(to: "seconds", power: null, multiplier: 3600, offset: null),
      
      "gramms": ConversionHelper(to: "kilogramms", power: null, multiplier: 0.001, offset: null),

      "kilonewtons": ConversionHelper(to: "newtons", power: null, multiplier: 1000, offset: null),

      "milliampere": ConversionHelper(to: "ampere", power: null, multiplier: 0.001, offset: null),

      "millivolts": ConversionHelper(to: "volts", power: null, multiplier: 0.001, offset: null),

      "milliwatts": ConversionHelper(to: "watts", power: null, multiplier: 0.001, offset: null),
      "kilowatts": ConversionHelper(to: "watts", power: null, multiplier: 1000, offset: null),

      "celsius": ConversionHelper(to: "kelvins", power: null, multiplier: null, offset: 273.15),

      "kilojoules": ConversionHelper(to: "joules", power: null, multiplier: 1000, offset: null),

      "bars": ConversionHelper(to: "pascals", power: null, multiplier: 100000, offset: null),

      "degrees": ConversionHelper(to: "radians", power: null, multiplier: 180/pi, offset: null),
    });

    _compositionTable.compositions.addAll({
      "newtons": [
        const [MapEntry("kilogramms", 1), MapEntry("meters", 1), MapEntry("seconds", -2)],
        const [MapEntry("pascals", 1), MapEntry("meters", 2)],
        const [MapEntry("joules", 1), MapEntry("meters", -1)],
      ],
      "watts": [
        const [MapEntry("joules", 1), MapEntry("seconds", -1)],
        const [MapEntry("volts", 1), MapEntry("ampere", 1)],
      ],
      "joules": [
        const [MapEntry("newtons", 1), MapEntry("meters", 1)],
        const [MapEntry("watts", 1), MapEntry("seconds", 1)],
        const [MapEntry("pascals", 1), MapEntry("meters", 3)],
      ],
      "pascals": [
        const [MapEntry("newtons", 1), MapEntry("meters", -2)],
        const [MapEntry("joules", 1), MapEntry("meters", -3)],
      ]
    });
  }

  static bool _ensureShortestUnitDescriptionRepresentationFirst(){
    for(final UnitDescription desc in _unitDescriptions.values){
      final String shortestRep = desc.representations.reduce((previousValue, element) => previousValue.length < element.length ? previousValue : element);
      final int shortestIndex = desc.representations.indexOf(shortestRep);
      if(shortestIndex != 0){
        desc.representations[shortestIndex] = desc.representations[0];
        desc.representations[0] = shortestRep;
      }
    }
    return true;
  }

  static bool _checkUnitAliasesReferecedHaveDesc(){
    for(final MapEntry<UnitAlias, ConversionHelper> entry in _conversionTable.conversionsToBase.entries){
      if(!_unitDescriptions.containsKey(entry.key)){
        localLogger.error("Unit alias ${entry.key} was referenced in conversion table, but was not declared in unit descriptions");
        return false;
      }
      if(!_unitDescriptions.containsKey(entry.value.to)){
        localLogger.error("Unit alias ${entry.value.to} was referenced in conversion table, but was not declared in unit descriptions");
        return false;
      }
    }

    for(final MapEntry<String, List<List<MapEntry<String, int>>>> entry in _compositionTable.compositions.entries){
      if(!_unitDescriptions.containsKey(entry.key)){
        localLogger.error("Unit alias ${entry.key} was referenced in composition table, but was not declared in unit descriptions");
        return false;
      }

      if(entry.value.any((e) => e.map((e) => e.key).any((alias) => !_unitDescriptions.containsKey(alias)))){
        localLogger.error("Some unit alias(es) were referenced as a component in composition table, but was not declared in unit descriptions");
        return false;
      }
    }

    return true;
  }

  static bool _checkDimHasOneBase(){
    final Iterable<String> dimsWithBase = _unitDescriptions.values.where((desc) => desc.isBase).map((desc) => desc.dim);
    final Set<String> allDims = _unitDescriptions.values.map((e) => e.dim).toSet();
    final bool success = dimsWithBase.length == dimsWithBase.toSet().length && dimsWithBase.toSet().length == allDims.length;
    if(!success){
      localLogger.error("Each dimension must have one and only one base unit");
    }
    return success;
  }

  static bool _checkConversionStaysWithinDim(){
    for(final MapEntry<UnitAlias, ConversionHelper> entry in _conversionTable.conversionsToBase.entries){
      if(_unitDescriptions[entry.key]!.dim != _unitDescriptions[entry.value.to]!.dim){
        localLogger.error("Invalid conversion found: ${entry.key} is of dimension ${_unitDescriptions[entry.key]!.dim}, which cannot convert to ${entry.value.to} which is of dimension ${_unitDescriptions[entry.value.to]!.dim}");
        return false;
      }
    }
    return true;
  }

  static bool _checkConversionIsToBase(){
    for(final MapEntry<UnitAlias, ConversionHelper> entry in _conversionTable.conversionsToBase.entries){
      if(_unitDescriptions[entry.key]!.isBase){
        localLogger.error("Conversion for base unit ${entry.key} cannot be declared");
        return false;
      }

      if(!_unitDescriptions[entry.value.to]!.isBase){
        localLogger.error("Conversion to non-base unit ${entry.value.to} cannot be declared");
        return false;
      }
    }
    return true;
  }

  static bool _checkConversionHelpers(){
    for(final ConversionHelper helper in _conversionTable.conversionsToBase.values){
      int count = 0;
      count += helper.power != null ? 1 : 0;
      count += helper.multiplier != null ? 1 : 0;
      count += helper.offset != null ? 1 : 0;
      if(count != 1){
        localLogger.error("One and only one of {power, multiplier, offset} must be set, $count was given for a conversion to ${helper.to}");
        return false;
      }
    }
    return true;
  }

  static bool _checkNonBaseIsConvertible(){
    for(final MapEntry<UnitAlias, UnitDescription> entry in _unitDescriptions.entries.where((entry) => !entry.value.isBase)){
      if(!_conversionTable.conversionsToBase.containsKey(entry.key)){
        localLogger.error("Missing conversion to base for unit ${entry.key}");
        return false;
      }
    }
    return true;
  }

  static bool _checkCompositionUsesBaseUnits(){
    for(final MapEntry<String, List<List<MapEntry<String, int>>>> entry in _compositionTable.compositions.entries){
      if(!_unitDescriptions[entry.key]!.isBase){
        localLogger.error("Composition to non base unit ${entry.key} cannot be declared");
        return false;
      }

      if(entry.value.any((element) => element.map((e) => e.key).any((alias) => !_unitDescriptions[alias]!.isBase))){
        localLogger.error("Compositions cannot use non base units as components");
        return false;
      }
    }
    return true;
  }

  static bool _validate(){
    bool success = true;

    _ensureShortestUnitDescriptionRepresentationFirst();

    success &= _checkUnitAliasesReferecedHaveDesc();
    if(!success){
      return false;
    }

    success &= _checkDimHasOneBase();
    success &= _checkConversionStaysWithinDim();
    success &= _checkConversionIsToBase();
    success &= _checkConversionHelpers();
    success &= _checkNonBaseIsConvertible();
    success &= _checkCompositionUsesBaseUnits();
    
    if(!success){
      localLogger.error("Unit system validation failed");
    }

    return success;
  }

  static bool _setDefaults(){
    _loadDefaults();
    if(!_validate()){
      localLogger.error("Default unitsystem data is not valid", doNoti: false);
      return false;
    }
    localLogger.info("Default unit system loaded");
    _syncToDisk();
    return true;
  }

  static Future<bool> loadFromDisk() async {
    _unitDescriptions.clear();
    _conversionTable.conversionsToBase.clear();
    _compositionTable.compositions.clear();
    Map data = await FileSystem.tryLoadMapFromLocalAsync(FileSystem.unitSystemDir, "unit_system.json");
    if(data.isEmpty){
      return _setDefaults();
    }
    bool success = true;
    try{
      for(Map desc in data["unit_descriptions"]){
        if(_unitDescriptions.containsKey(desc.keys.single)){
          localLogger.error("Duplicate unit description detected for alias ${desc.keys.single}");
          success = false;
        }
        _unitDescriptions[desc.keys.single] = UnitDescription(representations: desc.values.single["representations"].cast<String>(), isBase: desc.values.single["is_base"], dim: desc.values.single["dim"]);
      }
    } catch (ex){
      success = false;
      localLogger.error("Failed to load unit system descriptions: $ex", doNoti: false);
    }

    try{
      for(final Map conv in data["conversions"]){
        if(_conversionTable.conversionsToBase.containsKey(conv["from"])){
          localLogger.error("Duplicate unit conversion detected for alias ${conv["from"]}");
          success = false;
        }
        _conversionTable.conversionsToBase[conv["from"]] = ConversionHelper(to: conv["to"], power: conv["power"], multiplier: conv["multiplier"], offset: conv["offset"]);
      }
    }catch (ex){
      success = false;
      localLogger.error("Failed to load unit system conversion table: $ex", doNoti: false);
    }

    try{
      _compositionTable.load(data["compositions"]);
    }catch (ex){
      success = false;
      localLogger.error("Failed to load unit system composition table: $ex", doNoti: false);
    }


    if(!success){
      localLogger.warning("Failed to load unit system, falling back to defaults");
      _unitDescriptions.clear();
      _conversionTable.conversionsToBase.clear();
      _compositionTable.compositions.clear();
      _loadDefaults();
      if(!_validate()){
        localLogger.error("Default unitsystem data is not valid", doNoti: false);
        localLogger.error("Fallback to default unit system failed");
        return false;
      }
      return true;
    }

    if(!_validate()){
      localLogger.error("Unit system validation failed, falling back to defaults");
      _unitDescriptions.clear();
      _conversionTable.conversionsToBase.clear();
      _compositionTable.compositions.clear();
      _loadDefaults();
      if(!_validate()){
        localLogger.error("Default unitsystem data is not valid", doNoti: false);
        localLogger.error("Fallback to default unit system failed");
        return false;
      }
      return true;
    }
    return true;
  }
}
