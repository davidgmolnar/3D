import 'package:flutter/material.dart';

import '../../data/settings.dart';

class ChartScaler extends StatefulWidget {
  const ChartScaler({super.key});

  @override
  State<ChartScaler> createState() => _ChartScalerState();
}

class _ChartScalerState extends State<ChartScaler> {

  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(handleTraceSettingUpdate);
    super.initState();
  }

  void handleTraceSettingUpdate(){
    // if kell
    setState(() {});
  }

  void handleDrag(int group, double delta){
    TraceSettingsProvider.traceSettingNotifier.removeListener(handleTraceSettingUpdate);
    // TraceSettingsProvider.dragScalingGroup(group, delta)
    TraceSettingsProvider.traceSettingNotifier.addListener(handleTraceSettingUpdate);
  }

  void handleZoom(int group, double delta){
    TraceSettingsProvider.traceSettingNotifier.removeListener(handleTraceSettingUpdate);
    // TraceSettingsProvider.zoomScalingGroup(group, delta)
    TraceSettingsProvider.traceSettingNotifier.addListener(handleTraceSettingUpdate);
  }

  @override
  Widget build(BuildContext context) {
    // minden groupra egy child egy közös rowban yoffset és yscale állítás a tracesettingproviderben a handleDrag/handleZoommal, és setstate a childon belül
    return Container(width: 100, color: Colors.amber,);
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(handleTraceSettingUpdate);
    super.dispose();
  }
}