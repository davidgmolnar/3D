import 'package:flutter/material.dart';

import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../ui/input_widgets/buttons.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/window/window_titlebar.dart';
import '../../startup.dart';
import 'settings_bottom_bar.dart';
import 'settings_container.dart';

class TraceSettingWidget extends StatefulWidget{
  const TraceSettingWidget({super.key, required this.traceSetting, required this.measurement});

  final TraceSetting traceSetting;
  final String measurement;

  @override
  State<TraceSettingWidget> createState() => _TraceSettingWidgetState();
}

class _TraceSettingWidgetState extends State<TraceSettingWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: windowSetup?.size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: Text(widget.traceSetting.signal)
          ),
          Container(
            height: 40,
            width: 1,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))
            ),
          ),
          // Displayname
          SizedBox(
            width: 90,
            child: ButtonWithTwoText(
              isActive: widget.traceSetting.isVisible,
              textWhenActive: "Visible",
              textWhenInactive: "Invisible",
              onPressed: (){
                widget.traceSetting.isVisible = !widget.traceSetting.isVisible;
                TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).isVisible = widget.traceSetting.isVisible;
                setState(() {});
              },
            ),
          ),
          // Color picker
          // Scaling group
          // Span
          // Offset
        ],
      ),
    );
  }
}

class SettingsTraceEditor extends StatefulWidget{
  const SettingsTraceEditor({super.key});

  @override
  State<SettingsTraceEditor> createState() => _SettingsTraceEditorState();
}

class _SettingsTraceEditorState extends State<SettingsTraceEditor> {
  String shownMeasurement = "Select Measurement";
  
  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            padding: EdgeInsets.only(left: StyleManager.globalStyle.padding * 2),
            child: DropdownButton<String>(
              value: shownMeasurement,
              items: ["Select Measurement", ...TraceSettingsProvider.traceSettingNotifier.value.keys].map((e) => DropdownMenuItem<String>(value: e, child: Text(e),)).toList(),
              onChanged: (value) {
                if(value != null){
                  shownMeasurement = value;
                  setState(() {});
                }
              },
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - settingsBottomBarHeight - 50 - titlebarHeight,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: TraceSettingsProvider.itemCount(shownMeasurement),
              itemExtent: 50,
              itemBuilder: ((context, index) {
                return TraceSettingWidget(traceSetting: TraceSettingsProvider.traceSettingNotifier.value[shownMeasurement]![index], measurement: shownMeasurement,);
              })
            ),
          ),
          const SettingsBottomBar()
        ],
      ),
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}