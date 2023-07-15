import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ToggleableTextField extends StatefulWidget{
  const ToggleableTextField({super.key, required this.onFinished, required this.parser, required this.initialValue});

  final Function onFinished;
  final Function parser; // int.tryParse, double.tryParse etc
  final String initialValue;

  @override
  State<ToggleableTextField> createState() => _ToggleableTextFieldState();
}

class _ToggleableTextFieldState extends State<ToggleableTextField> {
  bool selected = false;
  late String value;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState(){
    value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(!selected){
      return TextButton(
        onPressed: (){
          selected = true;
        },
        child: Text(value, style: TextStyle(color: StyleManager.globalStyle.primaryColor))
      );
    }
    else{
      return Row(
        children: [
          TextFormField(
            controller: _controller
          ),
          IconButton(
            onPressed: (){
              final dynamic parsedValue = widget.parser(_controller.text);
              if(parsedValue == null){
                // TODO showerror
                return;
              }
              value = parsedValue.toString();
              selected = false;
              widget.onFinished(parsedValue);
              setState((){});
            },
            icon: Icon(Icons.check, color: StyleManager.globalStyle.primaryColor),
            splashRadius: 20
          )
        ],
      );
    }
  }
}