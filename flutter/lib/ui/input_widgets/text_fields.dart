import 'package:flutter/material.dart';

import '../../io/logger.dart';
import '../notifications/notification_logic.dart' as noti;
import '../theme/theme.dart';

class ToggleableTextField<T> extends StatefulWidget{
  const ToggleableTextField({super.key, required this.onFinished, required this.parser, required this.initialValue, required this.width});

  final void Function(T) onFinished;
  final T? Function(String) parser;
  final T initialValue;
  final double width;

  @override
  State<ToggleableTextField> createState() => _ToggleableTextFieldState<T>();
}

class _ToggleableTextFieldState<T> extends State<ToggleableTextField<T>> {
  bool selected = false;
  late String value;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState(){
    value = widget.initialValue.toString();
    super.initState();
  }

  void _onPressed(){
    final T? parsedValue = widget.parser(_controller.text);
    if(parsedValue == null){
      noti.NotificationController.add(noti.Notification.decaying(LogEntry.error("Value could not be parsed: $parsedValue"), 10000));
      return;
    }
    value = parsedValue.toString();
    selected = false;
    try{
      widget.onFinished(parsedValue);
    }catch(exc){
      localLogger.error("Exception when passing parsed value ${exc.toString()}", doNoti: false);
    }
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    if(!selected){
      return SizedBox(
        width: widget.width,
        child: TextButton(
          onPressed: (){
            selected = true;
            setState(() {});
          },
          child: Text(value, style: TextStyle(color: StyleManager.globalStyle.primaryColor))
        ),
      );
    }
    else{
      return Row(
        children: [
          SizedBox(
            width: widget.width,
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(hintText: value),
              onFieldSubmitted: (value) {
                _onPressed();
              },
            ),
          ),
        ],
      );
    }
  }
}