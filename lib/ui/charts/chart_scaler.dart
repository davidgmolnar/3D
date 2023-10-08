import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../theme/theme.dart';
import 'chart_logic/axis_data.dart';

const double _chartScalerWidth = 20;

class ChartScalerContainer extends StatefulWidget {
  const ChartScalerContainer({super.key});

  @override
  State<ChartScalerContainer> createState() => _ChartScalerContainerState();
}

class _ChartScalerContainerState extends State<ChartScalerContainer> {
  Set<int> visibleGroups = {};

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(handleTraceSettingUpdate);
    super.dispose();
  }

  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(handleTraceSettingUpdate);
    visibleGroups = TraceSettingsProvider.scalingGroupSet;
    super.initState();
  }

  void handleTraceSettingUpdate(){
    if(visibleGroups != TraceSettingsProvider.scalingGroupSet){
      visibleGroups = TraceSettingsProvider.scalingGroupSet;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(StyleManager.globalStyle.padding),
          width: visibleGroups.length * _chartScalerWidth + 2 * StyleManager.globalStyle.padding + 1,
          height: constraints.maxHeight,
          decoration: BoxDecoration(border: Border(right: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleGroups.length,
            itemBuilder: ((context, index) {
              return ChartScaler(scalingGroup: visibleGroups.toList()[index], axisHeight: constraints.maxHeight,);
            })
          ),
        );
      },
    );
  }
}

class ChartScaler extends StatefulWidget {
  const ChartScaler({super.key, required this.scalingGroup, required this.axisHeight});

  final double axisHeight;
  final int scalingGroup;

  @override
  State<ChartScaler> createState() => _ChartScalerState();
}

class _ChartScalerState extends State<ChartScaler> {
  late ValueAxisData valueAxisData;

  @override
  void initState() {
    final Map<String, dynamic> traceDataForGroup = TraceSettingsProvider.getValueAxisDataForGroup(widget.scalingGroup);
    valueAxisData = ValueAxisData.from(traceDataForGroup['offset'], traceDataForGroup['span'], widget.axisHeight, traceDataForGroup['unit']);
    super.initState();
  }

  void handleDrag(double delta){
    TraceSettingsProvider.dragScalingGroup(widget.scalingGroup, delta);
    final Map<String, dynamic> traceDataForGroup = TraceSettingsProvider.getValueAxisDataForGroup(widget.scalingGroup);
    valueAxisData = ValueAxisData.from(traceDataForGroup['offset'], traceDataForGroup['span'], widget.axisHeight, traceDataForGroup['unit']);
    setState(() {});
  }

  void handleZoom(double delta){
    TraceSettingsProvider.zoomScalingGroup(widget.scalingGroup, delta);
    final Map<String, dynamic> traceDataForGroup = TraceSettingsProvider.getValueAxisDataForGroup(widget.scalingGroup);
    valueAxisData = ValueAxisData.from(traceDataForGroup['offset'], traceDataForGroup['span'], widget.axisHeight, traceDataForGroup['unit']);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if(event is PointerScrollEvent){
          handleZoom(event.scrollDelta.dy);
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          handleDrag(details.primaryDelta ?? 0);
        },
        child: Container(
          width: _chartScalerWidth,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(width: 1, color: TraceSettingsProvider.colorOfScalingGroup(widget.scalingGroup)))),
          child: CustomPaint(painter: ChartScalerPainter(valueAxisData: valueAxisData, color: TraceSettingsProvider.colorOfScalingGroup(widget.scalingGroup))),
        ),
      ),
    );
  }
}

class ChartScalerPainter extends CustomPainter{
  ChartScalerPainter({required this.valueAxisData, required this.color});

  final Color color;
  final ValueAxisData valueAxisData;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.rotate(1.5 * 3.14159265359);
    canvas.translate(-size.height, 0);
    final TextPainter textPainterBase = TextPainter(
      text: TextSpan(
        text: "DEFAULT TEXT",
        style: StyleManager.textStyle,
      ),
      textDirection: TextDirection.ltr,
    );

    final Paint paintBase = Paint()..color = color;
    
    int i = 0;
    for(final num label in valueAxisData.majorTickValues){
      final TextPainter tp = textPainterBase..text = TextSpan(
        text: label.toString(),
        style: StyleManager.textStyle.copyWith(color: color),
      );
      tp.layout();
      final Offset majorPos = Offset(valueAxisData.majorTickPositions[i] - StyleManager.globalStyle.padding, 0);
      tp.paint(canvas, majorPos.translate(-tp.width / 2, -1));
      i++;

      canvas.drawLine(majorPos.translate(0, size.width), majorPos.translate(0, size.width - 3), paintBase);
    }

    for(final double tickPos in valueAxisData.tickPositions){

    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}