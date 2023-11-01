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

class ButtonWithRotatingText<T> extends StatefulWidget{
  const ButtonWithRotatingText({super.key, required this.states, required this.onPressed, required this.initialState});

  final List<T> states;
  final Function onPressed;
  final T initialState;

  @override
  State<ButtonWithRotatingText> createState() => _ButtonWithRotatingTextState();
}

class _ButtonWithRotatingTextState extends State<ButtonWithRotatingText> {
  int __idx = 0;

  @override
  void initState() {
    __idx = widget.states.indexWhere((element) => element == widget.initialState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){
        __idx++;
        __idx %= widget.states.length;
        widget.onPressed(widget.states[__idx]);
      },
      child: Text(widget.states[__idx].toString(), style: TextStyle(color: StyleManager.globalStyle.primaryColor))
    );
  }
}