import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ButtonWithTwoText extends StatefulWidget{
  const ButtonWithTwoText({super.key, required this.onPressed, required this.isInitiallyActive, required this.textWhenActive, required this.textWhenInactive});

  final void Function(bool) onPressed;
  final bool isInitiallyActive;
  final String textWhenActive;
  final String textWhenInactive;

  @override
  State<ButtonWithTwoText> createState() => _ButtonWithTwoTextState();
}

class _ButtonWithTwoTextState extends State<ButtonWithTwoText> {
  bool active = false;

  @override
  void initState() {
    active = widget.isInitiallyActive;
    super.initState();
  }

  void _onPressed(){
    active = !active;
    widget.onPressed(active);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if(active){
      return TextButton(onPressed: _onPressed, child: Text(widget.textWhenActive, style: TextStyle(color: StyleManager.globalStyle.primaryColor)));
    }
    return TextButton(onPressed: _onPressed, child: Text(widget.textWhenInactive, style: TextStyle(color: StyleManager.globalStyle.primaryColor)));
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