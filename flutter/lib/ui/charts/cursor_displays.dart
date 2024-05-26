import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../data/settings.dart';
import '../../data/updateable_valuenotifier.dart';
import '../../multiprocess/childprocess.dart';
import '../../routes/custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../routes/window_type.dart';
import '../input_widgets/buttons.dart';
import '../input_widgets/sliders.dart';
import '../theme/theme.dart';
import 'chart_logic/chart_controller.dart';

const double cursorHorizontalDragBuffer = 2; // setting,

enum DeltaDisplayType{
  // ignore: constant_identifier_names
  ABSDIFF,
  // ignore: constant_identifier_names
  DERIVATE,
  // ignore: constant_identifier_names
  INTEGRAL
}

const Map<DeltaDisplayType, String> deltaDisplayTypeNames = {
  DeltaDisplayType.ABSDIFF: "Y Diff",
  DeltaDisplayType.DERIVATE: "Derivate",
  DeltaDisplayType.INTEGRAL: "Integral",
};

class CursorData{
  double timeStamp;
  Map<String, Map<String, num>> values;
  bool isDelta;
  int? deltaTarget;
  DeltaDisplayType deltaType = DeltaDisplayType.ABSDIFF;

  CursorData({
    required this.timeStamp,
    required this.values,
    required this.isDelta,
    required this.deltaTarget,
  });

  factory CursorData.fromCurrent(final double timeStamp, final Map<String, Map<String, num>> values){
    return CursorData(timeStamp: timeStamp, values: values, isDelta: false, deltaTarget: null);
  }
}

class CursorInfo{
  final List<CursorData> cursors = [];
  Map<String, List<String>> visibility = {};

  int get countDeltas => cursors.fold(0, (previousValue, cursor) => previousValue + (cursor.isDelta ? 1 : 0));

  int get countAbsolutes => cursors.fold(0, (previousValue, cursor) => previousValue + (cursor.isDelta ? 0 : 1));

  List<int> get allAbsolutes {
    final List<int> absolutes = [];
    for(int i = 0; i < cursors.length; i++){
      if(!cursors[i].isDelta){
        absolutes.add(i);
      }
    }
    return absolutes;
  }

  Map<String, Map<String, num>> calcDelta(final int index){
    // TODO ez vmiért újraszámolódik akkor is ha a chartshownduration notifyol
    final Map<String, Map<String, num>> ret = {};
    final int absIdx = cursors[index].deltaTarget!;
    for(String meas in cursors[absIdx].values.keys){
      ret[meas] = {};
      for(String signal in cursors[absIdx].values[meas]!.keys){
        if(cursors[index].deltaType == DeltaDisplayType.ABSDIFF){
          ret[meas]![signal] = cursors[index].values[meas]![signal]! - cursors[absIdx].values[meas]![signal]!;
        }
        else if(cursors[index].deltaType == DeltaDisplayType.DERIVATE){
          ret[meas]![signal] = (cursors[index].values[meas]![signal]! - cursors[absIdx].values[meas]![signal]!) / (cursors[index].timeStamp - cursors[absIdx].timeStamp);
          if(windowType != WindowType.CUSTOM_CHART || customChartWindowType != CustomChartWindowType.CHARACTERISTICS){
            ret[meas]![signal] = ret[meas]![signal]! * 1000.0; // 1/ms to 1/s
          }
        }
        else if(cursors[index].deltaType == DeltaDisplayType.INTEGRAL){
          ret[meas]![signal] = signalIntegral(meas, signal, cursors[index].timeStamp, cursors[absIdx].timeStamp);
        }
      }
    }
    return ret;
  }

  double dt(final int index){
    if(!cursors[index].isDelta){
      return 0;
    }
    final int absIdx = cursors[index].deltaTarget!;
    return cursors[index].timeStamp - cursors[absIdx].timeStamp;
  }

  List<String> getCursorValuesDescription(int index){
    final List<String> desc = [];
    for(String meas in visibility.keys){
      desc.addAll(visibility[meas]!.map((signal) => "$meas|$signal"));
    }
    return desc;
  }
}

final UpdateableValueNotifier<CursorInfo> cursorInfoNotifier = UpdateableValueNotifier<CursorInfo>(CursorInfo());

class CursorTooltip extends StatelessWidget {
  const CursorTooltip({super.key, required this.cursorIndex, required this.pos});

  final int cursorIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    if(pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: pos! + cursorHorizontalDragBuffer,
      child: Container(
        width: 280,
        color: StyleManager.globalStyle.secondaryColor.withOpacity(0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                  child: Text("${cursorInfoNotifier.value.cursors[cursorIndex].isDelta ? "D" : "M"}$cursorIndex"),
                ),
                ButtonWithTwoText(
                  key: UniqueKey(),
                  isInitiallyActive: cursorInfoNotifier.value.cursors[cursorIndex].isDelta,
                  textWhenActive: "Delta Marker",
                  textWhenInactive: "Abs Marker",
                  onPressed: (p0) {
                    cursorInfoNotifier.update((value) {
                      if(cursorInfoNotifier.value.cursors[cursorIndex].isDelta){
                        value.cursors[cursorIndex].isDelta = false;
                      }
                      else{
                        final bool wouldBeTheLast = cursorInfoNotifier.value.countAbsolutes == 1;
                        if(!wouldBeTheLast){
                          value.cursors[cursorIndex].isDelta = !value.cursors[cursorIndex].isDelta;
                          value.cursors[cursorIndex].deltaTarget = value.cursors.indexWhere((cursorData) => !cursorData.isDelta);
                        }
                      }
                    });
                  },
                ),
                if(cursorInfoNotifier.value.cursors[cursorIndex].isDelta)
                  ButtonWithRotatingText<int>(
                    states: cursorInfoNotifier.value.allAbsolutes,
                    initialState: cursorInfoNotifier.value.cursors[cursorIndex].deltaTarget!,
                    onPressed: (selected) {
                      cursorInfoNotifier.update((value) {
                        value.cursors[cursorIndex].deltaTarget = selected;
                      });
                    }
                  ),
                IconButton(
                  onPressed: (){
                    cursorInfoNotifier.update((value) {
                      final bool flipOneDelta = cursorInfoNotifier.value.countAbsolutes == 1 && !value.cursors[cursorIndex].isDelta && value.cursors.length > 1;
                      value.cursors.removeAt(cursorIndex);
                      if(flipOneDelta){
                        value.cursors.firstWhere((cursor) => cursor.isDelta).isDelta = false;
                      }
                      if(windowType == WindowType.CUSTOM_CHART && customChartWindowType == CustomChartWindowType.GRID && isInSharingGroup){
                        ChildProcess.sendCustomChartUpdate(setCustomChartMarkerRemovePayload(cursorIndex));
                      }
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  splashRadius: 20,
                )
              ],
            ),
            if(cursorInfoNotifier.value.cursors[cursorIndex].isDelta)
              SlidingSwitch(
                labels: deltaDisplayTypeNames.values.toList(growable: false),
                active: deltaDisplayTypeNames[cursorInfoNotifier.value.cursors[cursorIndex].deltaType]!,
                onChanged: (selected) {
                  cursorInfoNotifier.update((value) {
                    value.cursors[cursorIndex].deltaType = deltaDisplayTypeNames.keys.firstWhere((element) => deltaDisplayTypeNames[element] == selected);
                  });
                },
                elementWidth: 90,
              ),
            cursorInfoNotifier.value.cursors[cursorIndex].isDelta ? 
              CursorDataDisplay(values: cursorInfoNotifier.value.calcDelta(cursorIndex))
              :
              CursorDataDisplay(values: cursorInfoNotifier.value.cursors[cursorIndex].values)
          ]
        ),
      )
    );
  }
}

class CursorDataDisplay extends StatelessWidget {
  const CursorDataDisplay({super.key, required this.values});

  final Map<String, Map<String, num>> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView(
        children: [
          for(String meas in values.keys)
            Column(
              children: [
                Container(
                  height: 30,
                  padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                  color: StyleManager.globalStyle.primaryColor.withOpacity(0.2),
                  alignment: Alignment.centerLeft,
                  child: Text(meas, style: StyleManager.subTitleStyle,),
                ),
                for(String signal in values[meas]!.keys)
                  SizedBox(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: StyleManager.globalStyle.padding),
                          child: Text(signal, style: TextStyle(color: TraceSettingsProvider.colorOfSignal(signal), fontSize: StyleManager.globalStyle.fontSize)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                          child: Text(representNumber(values[meas]![signal].toString(), maxDigit: 9), style: TextStyle(color: TraceSettingsProvider.colorOfSignal(signal), fontSize: StyleManager.globalStyle.fontSize)),
                        )
                      ],
                    )
                  )
              ],
            )
        ],
      )
    );
  }
}

class Cursor extends StatelessWidget {
  const Cursor({super.key, required this.cursorIndex, required this.pos,});

  final int cursorIndex;
  final double? pos;

  @override
  Widget build(BuildContext context) {
    // ez painteres line ha absolute marker, dotted ha delta marker
    if(pos == null){
      return const SizedBox();
    }
    return Positioned(
      left: pos,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            cursorInfoNotifier.update((cursorInfo) {
              cursorInfo.cursors[cursorIndex].timeStamp += ChartController.moveInCursonTime(details.delta.dx);
              cursorInfo.cursors[cursorIndex].values = cursorDataAtTimeStamp(cursorInfo.cursors[cursorIndex].timeStamp, cursorInfo.visibility);

              if(windowType == WindowType.CUSTOM_CHART && customChartWindowType == CustomChartWindowType.GRID && isInSharingGroup){
                ChildProcess.sendCustomChartUpdate(setCustomChartMarkerMovePayload(cursorIndex, cursorInfo.cursors[cursorIndex].timeStamp));
              }
            });
          },
          child: SizedBox(
            width: 1 + 2 * cursorHorizontalDragBuffer,
            child: Center(
              child: Container(
                width: 1,
                height: 2000, // inkorrekt de ez van
                color: StyleManager.globalStyle.textColor,
              )
            )
          ),
        ),
      ),
    );
  }
}

class CursorOverlay extends StatefulWidget {
  const CursorOverlay({super.key});

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {

  @override
  void initState() {
    cursorInfoNotifier.addListener(update);
    ChartController.shownDurationNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for(int i = 0; i < cursorInfoNotifier.value.cursors.length; i++)
          CursorTooltip(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.cursors[i].timeStamp),),
        for(int i = 0; i < cursorInfoNotifier.value.cursors.length; i++)
          Cursor(cursorIndex: i, pos: ChartController.timeStampToPosition(cursorInfoNotifier.value.cursors[i].timeStamp),),
      ]);
  }

  @override
  void dispose() {
    cursorInfoNotifier.removeListener(update);
    ChartController.shownDurationNotifier.removeListener(update);
    super.dispose();
  }
}