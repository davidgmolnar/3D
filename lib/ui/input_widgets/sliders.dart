import 'package:flutter/material.dart';

import '../theme/theme.dart';

class SlidingSwitch extends StatefulWidget {
  const SlidingSwitch({
    super.key,
    required this.labels,
    required this.active,
    required this.onChanged,
    required this.elementWidth,
  });

  final List<String> labels;
  final void Function(String) onChanged;
  final String active;
  final double elementWidth;

  @override
  State<SlidingSwitch> createState() => _SlidingSwitchState();
}

class _SlidingSwitchState extends State<SlidingSwitch> {
  int _activeIdx = 0;

  @override
  void initState() {
    _activeIdx = widget.labels.indexOf(widget.active);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
      ),
      width: widget.labels.length * widget.elementWidth,
      height: 30,
      child: Stack(
        fit: StackFit.expand,
        alignment: AlignmentDirectional.centerStart,
        children: [
          AnimatedPositioned(
            left: _activeIdx * widget.elementWidth,
            duration: const Duration(milliseconds: 200), 
            curve: Curves.easeInOutCubic,
            child: Container(
              width: widget.elementWidth,
              height: 30 - 2 * 1,
              color: StyleManager.globalStyle.primaryColor,
          )),

          for(int i = 0; i < widget.labels.length; i++)
            Positioned(left: i * widget.elementWidth, child: SizedBox(
              width: widget.elementWidth,
              height: 30 - 2 * 1,
              child: TextButton(
                onPressed: (() {
                  _activeIdx = i;
                  widget.onChanged(widget.labels[i]);
                  setState(() {});
                }),
                child: Text(
                  widget.labels[i],
                  style: StyleManager.textStyle,
                ),
              ),
            ))
        ],
      ),
    );
  }
}
