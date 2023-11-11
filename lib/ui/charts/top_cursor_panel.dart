import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../common.dart';
import '../input_widgets/buttons.dart';
import '../theme/theme.dart';
import '../toolbar/toolbar_item.dart';
import 'chart_logic/chart_controller.dart';
import 'cursor_displays.dart';

const double cursorDisplayHeight = 25;

enum _TopCursorType{
  // ignore: constant_identifier_names
  DATA,
  // ignore: constant_identifier_names
  FUNCTIONS
}

class TopCursorDisplay extends StatefulWidget {
  const TopCursorDisplay({super.key});


  @override
  State<TopCursorDisplay> createState() => _TopCursorDisplayState();
}

class _TopCursorDisplayState extends State<TopCursorDisplay> {
  _TopCursorType _type = _TopCursorType.DATA;
  int __selectedCursor = 0;

  @override
  void initState() {
    cursorInfoNotifier.addListener(update);
    super.initState();
  }

  void update(){
    if(__selectedCursor >= cursorInfoNotifier.value.cursors.length && cursorInfoNotifier.value.cursors.isNotEmpty){
      __selectedCursor = 0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cursorDisplayHeight,
      color: StyleManager.globalStyle.secondaryColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ButtonWithTwoText(
            isInitiallyActive: _type == _TopCursorType.DATA,
            textWhenActive: "Data",
            textWhenInactive: "Functions",
            onPressed: (isData) {
              _type = isData ? _TopCursorType.DATA : _TopCursorType.FUNCTIONS;
              setState(() {});
            },
          ),
          cursorInfoNotifier.value.cursors.isEmpty ?
            Text("No cursors set", style: StyleManager.textStyle,)
            :
            Expanded(
              child: Row(
                children: [
                  ButtonWithRotatingText<int>(
                    states: List.generate(cursorInfoNotifier.value.cursors.length, (index) => index, growable: false),
                    initialState: __selectedCursor,
                    onPressed: (selected){
                      __selectedCursor = selected;
                      setState(() {});
                    },
                  ),
                  Container(
                    height: cursorDisplayHeight,
                    width: 1,
                    color: StyleManager.globalStyle.primaryColor,
                  ),
                  _type == _TopCursorType.DATA ? 
                    GlobalCursorData(selectedCursor: __selectedCursor,)
                    :
                    Expanded(child: CursorFunctionsDisplay(selectedCursor: __selectedCursor,))
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    super.dispose();
  }
}

class GlobalCursorData extends StatelessWidget {
  const GlobalCursorData({super.key, required this.selectedCursor});

  final int selectedCursor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: EdgeInsets.only(left: StyleManager.globalStyle.padding),
          child: Text(cursorInfoNotifier.value.cursors[selectedCursor].isDelta ? "Delta" : "Absolute"),
        ),
        Padding(
          padding: EdgeInsets.only(left: StyleManager.globalStyle.padding),
          child: Text("Timestamp: ${cursorInfoNotifier.value.cursors[selectedCursor].timeStamp} ms"),
        ),
        if(cursorInfoNotifier.value.cursors[selectedCursor].isDelta)
          Padding(
            padding: EdgeInsets.only(left: StyleManager.globalStyle.padding),
            child: Text("dt: ${cursorInfoNotifier.value.dt(selectedCursor)} ms"),
          ),
      ],
    );
  }
}

class CursorFunctionsDisplay extends StatefulWidget {
  const CursorFunctionsDisplay({super.key, required this.selectedCursor});
  
  final int selectedCursor;
  static late int selected;
  static late String valueDescription;
  static late List<String> selectedCursorValuesDescription;

  static const List<ToolbarTextItem> _cursorFunctionButtons = [
    ToolbarTextItem(text: "Peak Search", onPressed: _cursorPeakSearch),
    //ToolbarTextItem(text: "Next Peak", onPressed: _cursorNextPeak),
    ToolbarTextItem(text: "Pk-Pk", onPressed: _cursorPeakToPeak),
    ToolbarTextItem(text: "Min Search", onPressed: _cursorMinSearch),
  ];

  static const List<ToolbarDropdownItem> _cursorFunctionButtonsDropDown = [
    ToolbarDropdownItem(text: "Peak Search", onPressed: _cursorPeakSearch),
    //ToolbarDropdownItem(text: "Next Peak", onPressed: _cursorNextPeak),
    ToolbarDropdownItem(text: "Pk-Pk", onPressed: _cursorPeakToPeak),
    ToolbarDropdownItem(text: "Min Search", onPressed: _cursorMinSearch),
  ];

  static void _cursorPeakSearch(){
    cursorInfoNotifier.update((value) {
      final List<String> parts = valueDescription.split('|');
      final ChartShowDuration shown = ChartController.shownDurationNotifier.value;
      value.cursors[CursorFunctionsDisplay.selected].timeStamp = timestampAtMax(parts[0], parts[1], shown.timeOffset, shown.timeOffset + shown.timeDuration);
      value.cursors[CursorFunctionsDisplay.selected].values = cursorDataAtTimeStamp(value.cursors[CursorFunctionsDisplay.selected].timeStamp, value.visibility);
    });
  }

  /*static void _cursorNextPeak(){
    
  }*/

  static void _cursorPeakToPeak(){
    if(!cursorInfoNotifier.value.cursors[CursorFunctionsDisplay.selected].isDelta){
      showErrorWithoutContext("Selected marker has to be a delta one");
      return;
    }
    cursorInfoNotifier.update((value) {
      final List<String> parts = valueDescription.split('|');
      final ChartShowDuration shown = ChartController.shownDurationNotifier.value;
      final int absIndex = value.cursors[CursorFunctionsDisplay.selected].deltaTarget!;
      value.cursors[CursorFunctionsDisplay.selected].timeStamp = timestampAtMax(parts[0], parts[1], shown.timeOffset, shown.timeOffset + shown.timeDuration);
      value.cursors[CursorFunctionsDisplay.selected].values = cursorDataAtTimeStamp(value.cursors[CursorFunctionsDisplay.selected].timeStamp, value.visibility);
      value.cursors[absIndex].timeStamp = timestampAtMin(parts[0], parts[1], shown.timeOffset, shown.timeOffset + shown.timeDuration);
      value.cursors[absIndex].values = cursorDataAtTimeStamp(value.cursors[absIndex].timeStamp, value.visibility);
    });
  }

  static void _cursorMinSearch(){
    cursorInfoNotifier.update((value) {
      final List<String> parts = valueDescription.split('|');
      final ChartShowDuration shown = ChartController.shownDurationNotifier.value;
      value.cursors[CursorFunctionsDisplay.selected].timeStamp = timestampAtMin(parts[0], parts[1], shown.timeOffset, shown.timeOffset + shown.timeDuration);
      value.cursors[CursorFunctionsDisplay.selected].values = cursorDataAtTimeStamp(value.cursors[CursorFunctionsDisplay.selected].timeStamp, value.visibility);
    });
  }

  @override
  State<CursorFunctionsDisplay> createState() => _CursorFunctionsDisplayState();
}

class _CursorFunctionsDisplayState extends State<CursorFunctionsDisplay> {

  @override
  void initState() {
    CursorFunctionsDisplay.selected = widget.selectedCursor;
    CursorFunctionsDisplay.selectedCursorValuesDescription = cursorInfoNotifier.value.getCursorValuesDescription(CursorFunctionsDisplay.selected);
    CursorFunctionsDisplay.valueDescription = CursorFunctionsDisplay.selectedCursorValuesDescription.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    CursorFunctionsDisplay.selected = widget.selectedCursor;
    return Row(
      children: [
        ButtonWithRotatingText(
          states: CursorFunctionsDisplay.selectedCursorValuesDescription,
          initialState: CursorFunctionsDisplay.valueDescription,
          onPressed: (select){
            CursorFunctionsDisplay.valueDescription = select;
            setState(() {});
          },
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: StyleManager.globalStyle.secondaryColor, width: 1),)),
                child: Row(
                  children: CursorFunctionsDisplay._cursorFunctionButtons.length * 100 < constraints.maxWidth ?
                    CursorFunctionsDisplay._cursorFunctionButtons
                    :
                    [
                    for(i = 0; i < (constraints.maxWidth - 100) ~/ 100; i++)
                      CursorFunctionsDisplay._cursorFunctionButtons[i],
                    ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: CursorFunctionsDisplay._cursorFunctionButtonsDropDown.skip(i).toList(), iconHeight: cursorDisplayHeight, invertColors: true,)
                    ]
                ),
              );
            }
          ),
        ),
      ],
    );
  }
}
