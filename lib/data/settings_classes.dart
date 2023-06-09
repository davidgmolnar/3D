enum SettingType{
  // ignore: constant_identifier_names
  BOOL,
  // ignore: constant_identifier_names
  SELECTION,
  // ignore: constant_identifier_names
  MINMAX,
}

class Setting{
  final String identifier;
  final SettingType type;
  final List<String>? selection;
  final num? max;
  final num? min;
  num value;

  Setting({
    required this.identifier,
    required this.type,
    required this.selection,
    required this.max,
    required this.min,
    required this.value
  });

  bool trySet(num newValue){
    if(type == SettingType.BOOL){
      if(newValue >= 0 && newValue <= 1){
        value = newValue;
        return true;
      }
      return false;
    }
    else if(type == SettingType.MINMAX){
      if(newValue >= min! && newValue <= max!){
        value = newValue;
        return true;
      }
      return false;
    }
    else if(type == SettingType.SELECTION){
      if(newValue >= 0 && newValue <= selection!.length){
        value = newValue;
        return true;
      }
      return false;
    }
    return false;
  }

  static Setting? fromJson(Map<String, dynamic> json){
    if(!json.containsKey('type')){
      return null;
    }
    switch (SettingType.values[json['type']]) {
      case SettingType.BOOL:
        if(json.containsKey('identifier') && json.containsKey('identifier') is String && json.containsKey('value') && json['value'] is num){
          return Setting(identifier: json['identifier'], type: SettingType.BOOL, selection: null, max: null, min: null, value: json['value']);
        }
        else{
          return null;
        }
      case SettingType.SELECTION:
        if(json.containsKey('identifier') && json.containsKey('identifier') is String && json.containsKey('value') && json['value'] is num
          && json.containsKey('selection') && json['selection'] is List){
          if(json['selection'].isEmpty || !json['signals'].every((selectable) => selectable is String)){
            return null;
          }
          return Setting(identifier: json['identifier'], type: SettingType.SELECTION, selection: json['selection'].map<String>((e) => e.toString()).toList(), max: null, min: null, value: json['value']);
        }
        else{
          return null;
        }
      case SettingType.MINMAX:
        if(json.containsKey('identifier') && json.containsKey('identifier') is String && json.containsKey('value') && json['value'] is num
          && json.containsKey('max') && json['max'] is num && json.containsKey('min') && json['min'] is num){
          return Setting(identifier: json['identifier'], type: SettingType.MINMAX, selection: null, max: json['max'], min: json['min'], value: json['value']);
        }
        else{
          return null;
        }
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> ret = {};
    ret['identifier'] = identifier;
    ret['value'] = value;
    if(selection != null){
      ret['selection'] = selection;
    }
    if(max != null){
      ret['max'] = max;
    }
    if(min != null){
      ret['min'] = min;
    }
    return ret;
  }
}