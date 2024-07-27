import 'package:flutter/material.dart';

import '../theme/theme.dart';

class StringInputDialog extends StatelessWidget {
  const StringInputDialog({super.key, required this.hintText, required this.onFinished});

  final String hintText;
  final Function(String) onFinished;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: (){
            onFinished(controller.text);
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.check, color: StyleManager.globalStyle.primaryColor,)
        ),
      ],
    );
  }
}