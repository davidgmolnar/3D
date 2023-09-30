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
    // minden groupra egy child egy közös rowban yoffset és yscale állítás a tracesettingproviderben a handleDrag/handleZoommal, és setstate a childon belül
    return Container(
      padding: EdgeInsets.all(StyleManager.globalStyle.padding),
      width: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleGroups.length,
        itemBuilder: ((context, index) {
          return ChartScaler(scalingGroup: visibleGroups.toList()[index]);
        })
      ),
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(handleTraceSettingUpdate);
    super.dispose();
  }
}

class ChartScaler extends StatefulWidget {
  const ChartScaler({super.key, required this.scalingGroup});

  final int scalingGroup;

  @override
  State<ChartScaler> createState() => _ChartScalerState();
}

class _ChartScalerState extends State<ChartScaler> {
  late ValueAxisData valueAxisData;

  @override
  void initState() {
    //valueAxisData = ValueAxisData.from(startValue, range, axisLength, unit)
    // TODO fel kell iratkozni a ChartControllerre a magasság miatt, de csak akkor update ha magasság változott, az időbeliség ide nem kell
    // Nem kell feliratkozni a TraceSettingsProviderre
    super.initState();
  }

  void handleDrag(int group, double delta){
    TraceSettingsProvider.dragScalingGroup(group, delta);
    //valueAxisData = ValueAxisData.from(startValue, range, axisLength, unit)
    setState(() {});
  }

  void handleZoom(int group, double delta){
    TraceSettingsProvider.zoomScalingGroup(group, delta);
    //valueAxisData = ValueAxisData.from(startValue, range, axisLength, unit)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if(event is PointerScrollEvent){
          handleZoom(widget.scalingGroup, event.scrollDelta.dy);
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          handleDrag(widget.scalingGroup, details.primaryDelta ?? 0);
        },
        child: Container(
          width: _chartScalerWidth,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(width: 1, color: TraceSettingsProvider.colorOfScalingGroup(widget.scalingGroup)))),
          //child: CustomPaint(painter: ChartScalerPainter(valueAxisData: valueAxisData)),
        ),
      ),
    );
  }
}

class ChartScalerPainter extends CustomPainter{

  final ValueAxisData valueAxisData;

  ChartScalerPainter({required this.valueAxisData});

  @override
  void paint(Canvas canvas, Size size) {
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}