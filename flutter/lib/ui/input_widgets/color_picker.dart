import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../dialogs/dialog_base.dart';
import '../theme/theme.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final Function(Color) onSelected;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color displayColor;

  @override
  void initState() {
    displayColor = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        showDialog<Widget>(
          context: context,
          builder: (BuildContext context){
            return DialogBase(
              title: "Pick a color",
              minWidth: 300,
              maxHeight: 300,
              maxWidth: 300,
              dialog: ColorPickerDialog(
                onSelected: (p0) {
                  widget.onSelected(p0);
                  displayColor = p0;
                  setState(() {});
                },
                active: displayColor
              ),
            );
          }
        );
      },
      child: Container(
        height: 30,
        width: 50,
        decoration: BoxDecoration(
          color: displayColor,
          border: Border.all(color: StyleManager.globalStyle.primaryColor, width: 1)
        ),
      )
    );
  }
}

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key, required this.onSelected, required this.active});

  final Function(Color) onSelected;
  final Color active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: (TraceSettingsProvider.colorBank.length / 5).ceil() * 32,
          child: ListView.builder(
            itemCount: (TraceSettingsProvider.colorBank.length / 5).ceil(),
            itemExtent: 32,
            itemBuilder: (context, index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for(int i = 0; i < 5; i++)
                    if(i + index * 5 < TraceSettingsProvider.colorBank.length)
                      GestureDetector(
                        onTap: () {
                          onSelected(TraceSettingsProvider.colorBank[i + index * 5]);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 30,
                          width: 50,
                          decoration: BoxDecoration(
                            color: TraceSettingsProvider.colorBank[i + index * 5],
                            border: Border.all(color: StyleManager.globalStyle.primaryColor, width: 1)
                          ),
                        ),
                      )
                ],
              );
            }
          ),
        );
      }
    );
  }
}