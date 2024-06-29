import 'dart:typed_data';

import '../../../data/data.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/fscache.dart';
import '../../../io/logger.dart';
import '../../window_type.dart';
import 'custom_chart_window_type.dart';
import 'statistics_view_controller.dart';

abstract class StatisticsViewLoadHelper{
  static void registerToCache(){
    FSCache.addListener(_onCacheTraceVisibleChanged, [FSCache.visibleTraceSettingsNamePath]);
    FSCache.addListener(_onCacheTraceAllChanged, [FSCache.allTraceSettingsNamePath]);
    _onCacheTraceVisibleChanged();
    _onCacheTraceAllChanged();
    localLogger.info("Register complete", doNoti: false);
  }

  static void _onCacheTraceVisibleChanged(){
    final Map<String, List> visibleTraceSettingsName = FSCache.read<Map>(FSCache.visibleTraceSettingsNamePath)?.cast<String, List>() ?? {};
    StatisticsViewController.notifier.value["data.visible_names"].clear();
    for(final String key in visibleTraceSettingsName.keys){
      StatisticsViewController.notifier.value["data.visible_names"][key] = visibleTraceSettingsName[key]!.cast<String>();
    }
    StatisticsViewController.notifier.updateKey("data.visible_names");
  }

  static void _onCacheTraceAllChanged(){
    final Map<String, List> allTraceSettingsDesc = FSCache.read<Map>(FSCache.allTraceSettingsNamePath)?.cast<String, List>() ?? {};    
    StatisticsViewController.notifier.value["data.all_names"].clear();
    for(final String key in allTraceSettingsDesc.keys){
      StatisticsViewController.notifier.value["data.all_names"][key] = allTraceSettingsDesc[key]!.cast<String>();
    } 
  }

  static void saveVisible(final String meas, final List<String> signals){
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("StatisticsViewLoadHelper.saveVisible was called on a non-main process", doNoti: false);
    }

    for(final String signal in signals){
      try{
        FileSystem.trySaveBytesToLocalSync(
          FileSystem.channelDir,
          "${meas}_$signal.3DCHANNEL",
          signalData[meas]![signal]!.toBytes()
        );
      }
      catch(ex){
        localLogger.error("Something went wrong when setting up statistics view: ${ex.runtimeType} ${ex.toString()}");
      }
    }
  }

  static load(final String meas, final List<String> singals){
    if(windowType != WindowType.CUSTOM_CHART && customChartWindowType != CustomChartWindowType.STATISTICS){
      localLogger.error("StatisticsViewLoadHelper.load was called on a non-statistics process", doNoti: false);
      return;
    }

    signalData.clear();
    signalData[meas] = {};

    for(final String signal in singals){
      final Uint8List bytes = FileSystem.tryLoadBytesFromLocalSync(
        FileSystem.channelDir,
        "${meas}_$signal.3DCHANNEL",
        deleteWhenDone: false
      );
      if(bytes.isEmpty){
        localLogger.error("Failed to import channel file: ${meas}_$signal.3DCHANNEL", doNoti: false);
      }
      else{
        localLogger.info("Imported channel file: ${meas}_$signal.3DCHANNEL", doNoti: false);
      }

      final SignalContainer sig = SignalContainer.fromBytes(bytes);
      signalData[meas]![signal] = sig;
    }

    StatisticsViewController.notifier.updateGroup(["data.meas", "data.signal"]);
  }
}