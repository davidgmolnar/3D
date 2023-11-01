import 'package:flutter/material.dart';

import '../input_widgets/buttons.dart';
import '../theme/theme.dart';
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
            Row(
              children: [
                ButtonWithRotatingText<int>(
                  states: List.generate(cursorInfoNotifier.value.cursors.length, (index) => index, growable: false),
                  initialState: __selectedCursor,
                  onPressed: (selected){
                    __selectedCursor = selected;
                    setState(() {});
                  },
                ),
                _type == _TopCursorType.DATA ? 
                  GlobalCursorData(selectedCursor: __selectedCursor,)
                  :
                  const CursorFunctionsDisplay()
              ],
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

class CursorFunctionsDisplay extends StatelessWidget {
  const CursorFunctionsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // TODO Peak Search
        // TODO Next Peak
        // TODO Next Peak Right
        // TODO Next Peak Left
        // TODO Pk-Pk Search << ehhez két markert kell kiválasztani
        // TODO Min Search
      ],
    );
  }
}
