import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../io/logger.dart';
import '../../../multiprocess/childprocess.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../ui/input_widgets/buttons.dart';
import '../../../ui/input_widgets/color_picker.dart';
import '../../../ui/input_widgets/sliders.dart';
import '../../../ui/input_widgets/text_fields.dart';
import '../../../ui/structures/hideable_listview.dart';
import '../../../ui/theme/theme.dart';
import '../../startup.dart';
import 'settings_bottom_bar.dart';
import 'settings_container.dart';

class TraceSettingWidget extends StatefulWidget{
  const TraceSettingWidget({super.key, required this.traceSetting, required this.measurement, required this.onVisibilityChanged});

  final TraceSetting traceSetting;
  final String measurement;
  final Function(bool, String) onVisibilityChanged;

  @override
  State<TraceSettingWidget> createState() => _TraceSettingWidgetState();
}

class _TraceSettingWidgetState extends State<TraceSettingWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: UniqueKey(),
      height: 50,
      width: windowSetup?.size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 250,
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
            width: 250,
          ),
          SizedBox(
            width: 90,
            child: ButtonWithTwoText(
              isInitiallyActive: widget.traceSetting.isVisible,
              textWhenActive: "Visible",
              textWhenInactive: "Invisible",
              onPressed: (p0) {
                widget.traceSetting.isVisible = p0;
                TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(isVisible: p0);
                widget.onVisibilityChanged(p0, widget.traceSetting.signal);
              },
            ),
          ),
          ToggleableTextField<int>(
            initialValue: widget.traceSetting.scalingGroup,
            parser: (p0) => int.tryParse(p0),
            onFinished: (p0) {
              final Offset? scaling = TraceSettingsProvider.scalingForGroup(p0);
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(
                scalingGroup: p0,
                offset: scaling?.dx,
                span: scaling?.dy
              );
              widget.traceSetting.scalingGroup = p0;
            },
            width: 60, // 50
          ),
          ColorPicker(
            selected: widget.traceSetting.color,
            onSelected: (p0) {
              widget.traceSetting.color = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(color: p0);
            },
          ),
          ToggleableTextField<num>(
            initialValue: widget.traceSetting.offset.roundToDecimalPlaces(6),
            parser: (p0) => double.tryParse(p0),
            onFinished: (p0) {
              widget.traceSetting.offset = p0;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(offset: p0);
              setState(() {});
            },
            width: 120,
          ),
          ToggleableTextField<num>(
            initialValue: (widget.traceSetting.offset + widget.traceSetting.span).roundToDecimalPlaces(6),
            parser: (p0) {
              double? newMax = double.tryParse(p0);
              if(newMax != null && newMax <= widget.traceSetting.offset){
                localLogger.error("Max must be larger than min");
                return null;
              }
              return newMax;
            },
            onFinished: (p0) {
              widget.traceSetting.span = p0 - widget.traceSetting.offset;
              TraceSettingsProvider.traceSettingNotifier.value[widget.measurement]!.firstWhere((element) => element.signal == widget.traceSetting.signal,).update(span: p0 - widget.traceSetting.offset);
            },
            width: 120,
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
  String filter = "";
  SortLogic sortLogic = SortLogic.STARTSWITH;
  List<TraceSettingWidget> allTraceSettings = [];
  List<TraceSettingWidget> visibleFiltered = [];
  List<TraceSettingWidget> hiddenFiltered = [];
  final TextEditingController _textEditingController = TextEditingController();
  
  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    if(TraceSettingsProvider.traceSettingNotifier.value.keys.length == 1){
      shownMeasurement = TraceSettingsProvider.traceSettingNotifier.value.keys.single;
      filter = "";
      _textEditingController.text = "";
      _loadList();
      _refreshList();
    }
    super.initState();
  }

  void update() {
    if(TraceSettingsProvider.traceSettingNotifier.value.keys.length == 1){
      shownMeasurement = TraceSettingsProvider.traceSettingNotifier.value.keys.single;
      filter = "";
      _textEditingController.text = "";
      _loadList();
      _refreshList();
    }
    setState(() {});
  }

  void _sendToApp(){
    ChildProcess.send(Response(localSocketPort, ResponseType.FINISHED, {"type": ResponseFinishableType.TRACE_EDITOR_DATA.index, "data": TraceSettingsProvider.toJsonFormattable}));
  }

  void _moveTraceSetting(final bool vis, final String signal){
    if(vis){
      final idx = hiddenFiltered.indexWhere((element) => element.traceSetting.signal == signal);
      visibleFiltered.add(hiddenFiltered[idx]);
      hiddenFiltered.removeAt(idx);
    }
    else{
      final idx = visibleFiltered.indexWhere((element) => element.traceSetting.signal == signal);
      hiddenFiltered.add(visibleFiltered[idx]);
      visibleFiltered.removeAt(idx);
    }
    setState(() {});
  }

  void _loadList(){
    if(shownMeasurement != "Select Measurement"){
      allTraceSettings = TraceSettingsProvider.traceSettingNotifier.value[shownMeasurement]!.map(
        (e) => TraceSettingWidget(traceSetting: e, measurement: shownMeasurement, onVisibilityChanged: _moveTraceSetting,)).toList();
    }
    else{
      allTraceSettings = [];
    }
  }

  void _refreshList(){
    if(shownMeasurement != "Select Measurement"){
      if(sortLogic == SortLogic.STARTSWITH){
        visibleFiltered = allTraceSettings.where(
          (traceSettingWidget) => traceSettingWidget.traceSetting.isVisible && (filter.isEmpty || traceSettingWidget.traceSetting.signal.toUpperCase().startsWith(filter.toUpperCase()))
        ).toList();
        hiddenFiltered = allTraceSettings.where(
          (traceSettingWidget) => !traceSettingWidget.traceSetting.isVisible && (traceSettingWidget.traceSetting.signal.toUpperCase().startsWith(filter.toUpperCase()))
        ).toList();
      }
      else if(sortLogic == SortLogic.CONTAINS){
        visibleFiltered = allTraceSettings.where(
          (traceSettingWidget) => traceSettingWidget.traceSetting.isVisible && (filter.isEmpty || traceSettingWidget.traceSetting.signal.toUpperCase().contains(filter.toUpperCase()))
        ).toList();
        hiddenFiltered = allTraceSettings.where(
          (traceSettingWidget) => !traceSettingWidget.traceSetting.isVisible && (traceSettingWidget.traceSetting.signal.toUpperCase().contains(filter.toUpperCase()))
        ).toList();
      }
    }
    else{
      visibleFiltered = [];
      hiddenFiltered = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          filter = "";
                          _textEditingController.text = "";
                          _loadList();
                          _refreshList();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                    height: 50,
                    width: constraints.maxWidth - 600,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Select a signal",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      controller: _textEditingController,
                      onChanged:(value) {
                        filter = value;
                        _refreshList();
                        setState(() {});
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                    child: SlidingSwitch(
                      labels: const ["Startswith", "Contains"],
                      active: "Startswith",
                      onChanged: (selected) {
                        sortLogic = selected == "Startswith" ? SortLogic.STARTSWITH : SortLogic.CONTAINS;
                        _refreshList();
                        setState(() {});
                      },
                      elementWidth: 100,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: constraints.maxHeight - settingsBottomBarHeight - 50,
              width: constraints.maxWidth,
              child: ListView(
                children: [
                  HideableListview(
                    title: "Visible signals",
                    listElements: visibleFiltered,
                    initiallyOpened: true,
                    style: HideableListviewStyle(
                      defaultTitleBoxColor: StyleManager.globalStyle.bgColor,
                      hoverTitleBoxColor: StyleManager.globalStyle.secondaryColor,
                      titleBarHeight: 50,
                      titleBarStyle: StyleManager.subTitleStyle,
                      elementHeight: 50,
                      padding: StyleManager.globalStyle.padding,
                      borderColor: StyleManager.globalStyle.secondaryColor,
                      borderWidth: 1
                    ),
                  ),
                  HideableListview(
                    title: "Hidden signals",
                    initiallyOpened: true,
                    listElements: hiddenFiltered,
                    style: HideableListviewStyle(
                      defaultTitleBoxColor: StyleManager.globalStyle.bgColor,
                      hoverTitleBoxColor: StyleManager.globalStyle.secondaryColor,
                      titleBarHeight: 50,
                      titleBarStyle: StyleManager.subTitleStyle,
                      elementHeight: 50,
                      padding: StyleManager.globalStyle.padding,
                      borderColor: StyleManager.globalStyle.secondaryColor,
                      borderWidth: 1
                    ),
                  ),
                ],
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
        );
      }
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}