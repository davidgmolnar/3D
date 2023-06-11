import 'dart:ui';

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

  Map<String, dynamic> get asJson => 
    type == SettingType.BOOL ?
    {
      'identifier': identifier,
      'value' : value,
      'type': type.index
    }
    : type == SettingType.SELECTION ?
    {
      'identifier': identifier,
      'value': value,
      'selection': selection,
      'type': type.index
    }
    : type == SettingType.MINMAX ?
    {
      'identifier': identifier,
      'value': value,
      'max': max,
      'min': min,
      'type': type.index,
    }
    :
    {
      'type': -1
    };
}

class TraceSetting{
  final String signal;
  Color color;
  int scalingGroup;
  bool isVisible = false;
  num offset = 0;
  num span = 1;

  TraceSetting({
    required this.signal,
    required this.color,
    required this.scalingGroup,
  });

  void update({Color? color, bool? isVisible, num? offset, num? span}){
    this.color = color ?? this.color;
    this.isVisible = isVisible ?? this.isVisible;
    this.offset = offset ?? this.offset;
    this.span = span ?? this.span;
  }

  static TraceSetting? fromJson(Map<String,dynamic> json){
    if(!json.containsKey('signal') || json['signal'] !is String){
      return null;
    }
    else if(!json.containsKey('color') || json['color'] !is List || json['color'].length != 4 || !json['color'].every((element) => element is int)){
      return null;
    }
    else if(!json.containsKey('isVisible') || json['isVisible'] !is int || json['isVisible'] < 0 || json['isVisible'] > 1){
      return null;
    }
    else if(!json.containsKey('offset') || json['offset'] !is num){
      return null;
    }
    else if(!json.containsKey('span') || json['span'] !is num){
      return null;
    }
    else if(!json.containsKey('scalingGroup') || json['scalingGroup'] !is int){
      return null;
    }
    else{
      final Color color = Color.fromARGB(json['color'][0], json['color'][1], json['color'][2], json['color'][3]);
      return TraceSetting(signal: json['signal'], color: color, scalingGroup: json['scalingGroup'])..isVisible = json['isVisible']..offset = json['offset']..span = json['span'];
    }
  }

  Map<String,dynamic> get asJson => {
    'signal': signal,
    'color': [color.alpha, color.red, color.green, color.blue],
    'isVisible': isVisible ? 1 : 0,
    'offset': offset,
    'span': span,
    'scalingGroup': scalingGroup
  };
}