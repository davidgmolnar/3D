import '../../../io/logger.dart';
import 'custom_chart_descriptor.dart';

//////////
/// 1-2-4-8 custom chart egy gridben, 1x1, 2x1, 2x2, 4x2  sor x oszlop
/// ChartShownDuration + cursor sharing group

class CustomChartGroup{
  final int sharingGroup;
  final List<CustomChartDescriptor> elements = [];

  CustomChartGroup({required this.sharingGroup});

  bool add({required final String m, required final String s}){
    final CustomChartDescriptor? custom = CustomChartDescriptor.from(m: m, s: s);
    if(custom != null){
      elements.add(custom);
      return true;
    }
    return false;
  }

  void saveChannels(){
    for(final CustomChartDescriptor element in elements){
      element.saveChannel();
    }
  }

  void loadChannels(){
    for(final CustomChartDescriptor element in elements){
      element.loadChannel();
    }
  }

  Map toJson(){
    return {
      "group": sharingGroup,
      "elements": elements.map((e) => {"meas": e.measurement, "sig": e.signal}).toList()
    };
  }

  static CustomChartGroup? fromJson(final Map json){
    if(!json.containsKey("group") || json["group"] is! int){
      return null;
    }
    if(!json.containsKey("elements") || json["elements"] is! List){
      return null;
    }
    if((json["elements"] as List).any((element) => element is! Map)){
      return null;
    }
    final CustomChartGroup group = CustomChartGroup(sharingGroup: json["group"]);
    for(final Map e in json["elements"]){
      if(!group.add(m: e["meas"], s: e["sig"])){
        localLogger.warning("Failed to include an element when parsing a CustomChartGroup");
      }
    }
    return group;
  }
}