import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/updateable_valuenotifier.dart';

class Style{
  final Color bgColor;
  final double fontSize;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final double subTitleFontSize;
  final Color textColor;
  final double titleFontSize;
  final double padding;

  Style({
    required this.name,
    required this.textColor,
    required this.bgColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.fontSize,
    required this.subTitleFontSize,
    required this.titleFontSize,
    required this.padding,
  });
}

abstract class StyleManager{
  static final Map<String, Style> _styles = {
    "DARK": Style(
      name: "DARK",
      textColor: Colors.white,
      bgColor: const Color.fromARGB(255, 23, 24, 34),
      primaryColor: const Color.fromARGB(255, 22, 108, 189),
      secondaryColor: const Color.fromARGB(255, 42, 45, 62),
      fontSize: 14,
      subTitleFontSize: 20,
      titleFontSize: 30,
      padding: 8.0
    ),
    "BRIGHT": Style(
      name: "BRIGHT",
      textColor: Colors.black,
      bgColor: Colors.white,
      primaryColor: const Color.fromARGB(255, 12, 63, 110),
      secondaryColor: const Color.fromARGB(255, 137, 149, 221),
      fontSize: 14,
      subTitleFontSize: 20,
      titleFontSize: 30,
      padding: 8.0
    ),
  };

  static Style globalStyle = _styles["DARK"]!;

  static final UpdateableValueNotifier<String?> titleNotifier = UpdateableValueNotifier<String?>(null);

  static Function updater = (){};

  static void addStlye(Style style){
    if(!_styles.containsKey(style.name)){
      _styles[style.name] = style;
    }
  }

  static List<String> getStyleList() => _styles.keys.toList();

  static void changeStyle(String name){
    if(_styles.containsKey(name)){
      globalStyle = _styles[name]!;
      updater();
    }
  }
  
  static ThemeData? getThemeData(BuildContext context) => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: globalStyle.bgColor,
    backgroundColor: globalStyle.bgColor,
    textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(bodyColor: globalStyle.textColor),
    canvasColor: globalStyle.bgColor,
    primaryColor: globalStyle.primaryColor,
    iconTheme: Theme.of(context).iconTheme.copyWith(color: globalStyle.primaryColor),
    inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: globalStyle.primaryColor)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    appBarTheme: Theme.of(context).appBarTheme.copyWith(elevation: 0, backgroundColor: globalStyle.secondaryColor)
  );

  static TextStyle get textStyle => TextStyle(color: globalStyle.textColor, fontSize: globalStyle.fontSize);
  static TextStyle get subTitleStyle => TextStyle(color: globalStyle.textColor, fontSize: globalStyle.subTitleFontSize);
  static TextStyle get titleStyle => TextStyle(color: globalStyle.textColor, fontSize: globalStyle.titleFontSize);

  static WindowButtonColors get windowButtonColors => WindowButtonColors(iconNormal: globalStyle.primaryColor);
  static String get activeStyle => _styles.keys.where((element) => _styles[element] == globalStyle).first;
}
