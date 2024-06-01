import 'package:flutter/material.dart';

import '../../../io/file_system.dart';
import '../../../io/logger.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../multiprocess/childprocess_controller.dart';
import '../../startup.dart';
import '../../window_type.dart';
import 'custom_chart_window_type.dart';
import 'custom_descriptor.dart';

//////////
/// 1-2-4-8 custom chart egy gridben, 1x1, 2x1, 2x2, 4x2  sor x oszlop
/// ChartShownDuration + cursor sharing group

abstract class CustomGroup<T extends CustomDescriptor>{
  final String name;
  final int sharingGroup;
  final int numRow;
  final int numCol;
  final List<T> elements = [];
  
  CustomGroup({required this.sharingGroup, required this.name, required this.numRow, required this.numCol});

  bool add({required final String m, required final List<String> s});
  
  void save();
  void saveChannels();
  void loadChannels();
  
  void launch();

  Map toJson();
}

class CustomTimeseriesChartGroup implements CustomGroup<CustomTimeseriesChartDescriptor>{ 
  @override
  final String name;
  @override
  final int sharingGroup;
  @override
  final int numRow;
  @override
  final int numCol;
  @override
  final List<CustomTimeseriesChartDescriptor> elements = [];

  CustomTimeseriesChartGroup({required this.sharingGroup, required this.name, required this.numRow, required this.numCol});

  @override
  bool add({required final String m, required final List<String> s}){
    final CustomTimeseriesChartDescriptor? custom = CustomTimeseriesChartDescriptor.from(m: m, s: s);
    if(custom != null && !elements.contains(custom) && numRow * numCol > elements.length){
      elements.add(custom);
      return true;
    }
    return false;
  }


  @override
  void saveChannels(){
    for(final CustomTimeseriesChartDescriptor element in elements){
      element.saveChannels();
    }
  }


  @override
  void loadChannels(){
    for(final CustomTimeseriesChartDescriptor element in elements){
      element.loadChannels();
    }
  }

  @override
  Future<void> launch() async {
    save();
    saveChannels();
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("CustomTimeseriesChartGroup.launch was called on a non-main process", doNoti: false);
      return;
    }

    final Size screenSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final Size elementSize = Size(screenSize.width / numCol, screenSize.height / numRow);
    for(int i = 0; i < elements.length; i++){
      final int col = i ~/ numRow;
      final int row = i % numRow;
      final Offset position = Offset(
        screenSize.width / numCol * col,
        screenSize.height / numRow * row
      );
      final int port = await ChildProcessController.addConnection(
        WindowType.CUSTOM_CHART,
        WindowSetupInfo("$name - R$row - C$col",
                        elementSize,
                        position
        )
      );
      ChildProcessController.sendTo(Command(
        port,
        CommandType.DATA,
        setCustomChartWindowTypePayload(CustomChartWindowType.GRID)
      ));
      ChildProcessController.sendTo(Command(
        port,
        CommandType.DATA,
        setCustomChartDescriptorPayload(
          name,
          i
        )
      ));

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Map toJson(){
    return {
      "group": sharingGroup,
      "numRow": numRow,
      "numCol": numCol,
      "elements": elements.map((e) => {"meas": e.measurement, "sig": e.signals}).toList()
    };
  }

  static CustomTimeseriesChartGroup? fromJson(final Map json, final String name){
    if(!json.containsKey("group") || json["group"] is! int){
      return null;
    }
    if(!json.containsKey("numRow") || json["numRow"] is! int || json["numRow"] > 4){
      return null;
    }
    if(!json.containsKey("numCol") || json["numCol"] is! int || json["numCol"] > 4){
      return null;
    }
    if(!json.containsKey("elements") || json["elements"] is! List){
      return null;
    }
    if((json["elements"] as List).any((element) => element is! Map)){
      return null;
    }
    final CustomTimeseriesChartGroup group = CustomTimeseriesChartGroup(sharingGroup: json["group"], name: name, numRow: json["numRow"], numCol: json["numCol"]);
    for(final Map e in json["elements"]){
      if(!group.add(m: e["meas"], s: e["sig"].cast<String>())){
        localLogger.warning("Failed to include an element when parsing a CustomChartGroup");
      }
    }
    return group;
  }
  
  @override
  void save() {
    FileSystem.trySaveMapToLocalSync(FileSystem.customTimeSeriesGroupDir, "$name.3DCTCG", toJson());
  }

  static Future<CustomTimeseriesChartGroup?> load(final String name) async {
    final Map json = await FileSystem.tryLoadMapFromLocalAsync(FileSystem.customTimeSeriesGroupDir, "$name.3DCTCG", deleteWhenDone: false);
    return fromJson(json, name);
  }
}

// TODO characteristics
// one xaxis channel
// multiple yaxis channels