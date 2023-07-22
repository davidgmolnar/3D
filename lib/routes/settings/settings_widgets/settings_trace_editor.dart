import 'package:flutter/material.dart';

import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../ui/input_widgets/buttons.dart';
import '../../../ui/input_widgets/text_fields.dart';
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
          ToggleableTextField<String>(
            initialValue: widget.traceSetting.displayName,
            parser: (p0) => p0,
            onFinished: (p0) {
              widget.traceSetting.displayName = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(displayName: p0);
            },
            width: 200,
          ),
          SizedBox(
            width: 90,
            child: ButtonWithTwoText(
              isInitiallyActive: widget.traceSetting.isVisible,
              textWhenActive: "Visible",
              textWhenInactive: "Invisible",
              onPressed: (p0){
                widget.traceSetting.isVisible = p0;
                TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(isVisible: p0);
              },
            ),
          ),
          // TODO Color picker
          ToggleableTextField<int>(
            initialValue: widget.traceSetting.scalingGroup,
            parser: (p0) => int.tryParse(p0),
            onFinished: (p0) {
              widget.traceSetting.scalingGroup = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(scalingGroup: p0);
            },
            width: 50,
          ),
          ToggleableTextField<num>(
            initialValue: widget.traceSetting.span,
            parser: (p0) => double.tryParse(p0),
            onFinished: (p0) {
              widget.traceSetting.span = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(span: p0);
            },
            width: 100,
          ),
          ToggleableTextField<num>(
            initialValue: widget.traceSetting.offset,
            parser: (p0) => double.tryParse(p0),
            onFinished: (p0) {
              widget.traceSetting.offset = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(offset: p0);
            },
            width: 100,
          ),
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

  void _sendToApp(){
    // TODO
  }

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
          SettingsBottomBar(
            onCancel: (){
              shutdown();
            },
            onApply: (){
              _sendToApp();
            },
            onApplyAndClose: (){
              _sendToApp();
              shutdown();
            },
          )
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