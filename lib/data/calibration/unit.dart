import 'dart:ui';

import 'package:flutter/material.dart';

enum Units{
  m,
  km,
  s,
  min,
  h,
  g,
  N,
  A,
  mA,
  V,
  mV,
  W,
  mW,
  K,
  J,
  bar,
  rad // TODO ki kéne találni vmi kultúráltat a °, °C és a %-ra és akkor minden fasza
}

const Map<Units, List<Map<Units, int>>> convertTable = {
  Units.J: [{Units.N: 1, Units.m: 1}, {Units.W: 1, Units.s: 1}],
  Units.W: [{Units.J: 1, Units.s: -1}, {Units.V: 1, Units.A: 1}]
};

class Unit{
  final Map<Units, int> components;

  const Unit({required this.components});

  factory Unit.fromSI(Units unit){
    return Unit(components: {unit: 1});
  }

  static Unit? tryParse(final String str){
    final Map<Units, int> components = {};

    bool reachedDenominator = false;
    int i = 0;
    while(i < str.length){
      if(str[i] == '/'){
        i++;
        reachedDenominator = true;
        continue;
      }

      Units? matched;
      for(Units unit in Units.values){
        if(i + unit.name.length < str.length){
          if(str.substring(i, i + unit.name.length) == unit.name){
            if(matched == null){
              matched = unit;
            }
            else{
              if(matched.name.length < unit.name.length){
                matched = unit;
              }
            }
          }
        }
      }

      if(matched == null){
        return null;
      }

      i += matched.name.length;

      if(i < str.length){
        final int? exp = int.tryParse(str[i]);
        if(exp != null){
          i++;
          components[matched] = reachedDenominator ? -exp : exp;
        }
        else{
          components[matched] = reachedDenominator ? -1 : 1;
        }
      }
    }

    return Unit(components: components);
  }

  Map<Units, int> __simplified(){
    final Map<Units, int> copy = components;

    for(Units unit in convertTable.keys){
      for(Map<Units, int> convertOption in convertTable[unit]!){
        bool convertable = true;

        for(Units convertUnit in convertOption.keys){

          if(convertOption[convertUnit]! > 0){
            if(copy[convertUnit]! < convertOption[convertUnit]!){
              convertable = false;
              break;
            }
          }
          else{
            if(copy[convertUnit]! > convertOption[convertUnit]!){
              convertable = false;
              break;
            }
          }

        }

        if(convertable){
          for(Units convertUnit in convertOption.keys){
            copy[convertUnit] = copy[convertUnit]! - convertOption[convertUnit]!;
          }

          if(copy.containsKey(unit)){
            copy[unit] = copy[unit]! + 1;
          }
          else{
            copy[unit] = 1;
          }
        }
      }
    }

    return copy;
  }

  RichText asRichText(TextStyle style){
    final Map<Units, int> copied = __simplified();
    Map<Units, int> nominator = {};
    Map<Units, int> denominator = {};

    for(Units unit in copied.keys){
      if(copied[unit]! > 0){
        nominator[unit] = copied[unit]!;
      }
      else{
        denominator[unit] = copied[unit]!;
      }
    }

    final List<TextSpan> text = [];
    for(Units unit in nominator.keys){
      text.add(TextSpan(
        text: unit.name,
        style: style
      ));

      if(nominator[unit]! > 1){
        text.add(TextSpan(
          text: nominator[unit]!.toString(),
          style: style.copyWith(fontFeatures: [const FontFeature.superscripts()]),
        ));
      }
    }

    text.add(TextSpan(
      text: '/',
      style: style
    ));
    if(denominator.keys.length > 1){
      text.add(TextSpan(
        text: '(',
        style: style
      ));
    }

    for(Units unit in denominator.keys){
      text.add(TextSpan(
        text: unit.name,
        style: style
      ));

      if(denominator[unit]! > 1){
        text.add(TextSpan(
          text: (-denominator[unit]!).toString(),
          style: style.copyWith(fontFeatures: [const FontFeature.superscripts()]),
        ));
      }
    }
    
    if(denominator.keys.length > 1){
      text.add(TextSpan(
        text: ')',
        style: style
      ));
    }

    return RichText(
      text: TextSpan(
        children: text
      )
    );
  }

  Unit operator *(final Unit other){
    final Map<Units, int> copy = components;
    for(Units unit in other.components.keys){
      if(copy.containsKey(unit)){
        copy[unit] = other.components[unit]! + copy[unit]!;
        if(copy[unit] == 0){
          copy.remove(unit);
        }
      }
      else{
        copy[unit] = other.components[unit]!;
      }
    }
    return Unit(components: copy);
  }

  Unit operator /(final Unit other){
    final Map<Units, int> copy = components;
    for(Units unit in other.components.keys){
      if(copy.containsKey(unit)){
        copy[unit] = other.components[unit]! - copy[unit]!;
        if(copy[unit] == 0){
          copy.remove(unit);
        }
      }
      else{
        copy[unit] = -other.components[unit]!;
      }
    }
    return Unit(components: copy);
  }
}