import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

enum Units{
  mm,
  m,
  km,

  ms,
  s,
  min,
  h,

  g,

  N,
  kN,

  mA,
  A,

  mV,
  V,

  mW,
  W,
  kW,

  K,

  J,
  kJ,

  bar,

  rad // TODO ki kéne találni vmi kultúráltat a °, °C és a %-ra és akkor minden fasza
}

const Map<Units, List<Map<Units, int>>> convertTable = {  // TODO ezt fájlból
  Units.J: [{Units.N: 1, Units.m: 1}, {Units.W: 1, Units.s: 1}],
  Units.W: [{Units.J: 1, Units.s: -1}, {Units.V: 1, Units.A: 1}]
};

const Map<Units?, Map<Units?, double>> prefixTableToBase = {  // TODO ezt fájlból
  // Ha nincs benne akkor önmaga
  Units.mm: {Units.m: 0.001},
  Units.km: {Units.m: 1000},

  Units.ms: {Units.s: 0.001},
  Units.min: {Units.s: 60},
  Units.h: {Units.s: 3600},

  Units.kN: {Units.N: 1000},

  Units.mA: {Units.A: 0.001},

  Units.mV: {Units.V: 0.001},

  Units.mW: {Units.W: 0.001},
  Units.kW: {Units.W: 1000},

  Units.kJ: {Units.J: 1000},

  Units.rad: {null: pi / 180},
  null: {null: 180 / pi},
};

class Unit{
  final Map<Units, int> components;
  final double scalar;

  const Unit({required this.scalar, required this.components});

  factory Unit.fromUnit(Units unit){
    return Unit(components: {unit: 1}, scalar: 1);
  }

  static Unit? tryParse(final String? str){
    final Map<Units, int> components = {};
    if(str == null){
      return Unit(components: components, scalar: 1);
    }

    bool reachedDenominator = false;
    int i = 0;
    while(i < str.length){
      if(!reachedDenominator){
        if(str[i] == '/'){
          i++;
          reachedDenominator = true;
        }
        else if(i + 1 < str.length && str.substring(i, i + 1) == '1/'){
          i += 2;
          reachedDenominator = true;
        }
      }

      Units? matched;
      for(Units unit in Units.values){
        if(i + unit.name.length - 1 < str.length){
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

    return Unit(components: components, scalar: 1);
  }

  Map<Units, int> __simplified(){
    final Map<Units, int> copy = components;

    for(Units unit in convertTable.keys){
      for(Map<Units, int> convertOption in convertTable[unit]!){
        bool convertable = true;

        for(Units convertUnit in convertOption.keys){
          if(copy[convertUnit]!.abs() < convertOption[convertUnit]!.abs()){
            convertable = false;
            break;
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

    if(denominator.keys.isNotEmpty){
      text.add(TextSpan(
        text: '/',
        style: style
      ));
    }
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

      if(denominator[unit]! < -1){
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
        copy[unit] = copy[unit]! + other.components[unit]!;
        if(copy[unit] == 0){
          copy.remove(unit);
        }
      }
      else{
        copy[unit] = other.components[unit]!;
      }
    }
    return Unit(components: copy, scalar: scalar * other.scalar);
  }

  Unit operator /(final Unit other){
    final Map<Units, int> copy = components;
    for(Units unit in other.components.keys){
      if(copy.containsKey(unit)){
        copy[unit] = copy[unit]! - other.components[unit]!;
        if(copy[unit] == 0){
          copy.remove(unit);
        }
      }
      else{
        copy[unit] = -other.components[unit]!;
      }
    }
    return Unit(components: copy, scalar: scalar / other.scalar);
  }
}


Unit? unitMult(Unit? p0, Unit? p1){
  if(p0 != null && p1 != null){
    return p0 * p1;
  }
  else if(p0 != null){
    return p0;
  }
  else if(p1 != null){
    return p1;
  }
  else{
    return null;
  }
}

Unit? unitDiv(Unit? p0, Unit? p1){
  if(p0 != null && p1 != null){
    return p0 / p1;
  }
  else if(p0 != null){
    return p0;
  }
  else if(p1 != null){
    return const Unit(scalar: 1, components: {}) / p1;
  }
  else{
    return null;
  }
}