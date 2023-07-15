import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ButtonWithTwoText extends StatefulWidget{
  const ButtonWithTwoText({super.key, required this.onPressed, required this.isActive, required this.textWhenActive, required this.textWhenInactive});

  final Function onPressed;
  final bool isActive;
  final String textWhenActive;
  final String textWhenInactive;

  @override
  State<ButtonWithTwoText> createState() => _ButtonWithTwoTextState();
}

class _ButtonWithTwoTextState extends State<ButtonWithTwoText> {
  @override
  Widget build(BuildContext context) {
    if(widget.isActive){
      return TextButton(onPressed: () => widget.onPressed(), child: Text(widget.textWhenActive, style: TextStyle(color: StyleManager.globalStyle.primaryColor)));
    }
    return TextButton(onPressed: () => widget.onPressed(), child: Text(widget.textWhenInactive, style: TextStyle(color: StyleManager.globalStyle.primaryColor)));
  }
}

class ButtonWithRotatingText extends StatefulWidget{
  const ButtonWithRotatingText({super.key, required this.states, required this.onPressed});

  final List<String> states;
  final Function onPressed;

  @override
  State<ButtonWithRotatingText> createState() => _ButtonWithRotatingTextState();
}

class _ButtonWithRotatingTextState extends State<ButtonWithRotatingText> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){
        idx++;
        widget.onPressed(idx);
      },
      child: Text(widget.states[idx], style: TextStyle(color: StyleManager.globalStyle.primaryColor))
    );
  }
}