import 'package:flutter/material.dart';

import '../theme/theme.dart';

class DropdownInputDialog extends StatelessWidget {
  const DropdownInputDialog({super.key, required this.hintText, required this.onFinished, required this.options});

  final String hintText;
  final List<String> options;
  final void Function(String?) onFinished;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: DropdownButton<String>(
          isExpanded: true,
          items: [DropdownMenuItem(value: null, child: Text(hintText, style: StyleManager.textStyle,)),
            ...options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: StyleManager.textStyle,)))
          ],
          onChanged: onFinished
        )
      ),
    );
  }
}