import 'dart:typed_data';

import '../../../data/data.dart';
import '../../../data/settings.dart';
import '../../../data/signal_container.dart';
import '../../../io/file_system.dart';
import '../../../io/fscache.dart';
import '../../../io/logger.dart';
import '../../window_type.dart';
import 'custom_chart_window_type.dart';

abstract class StatisticsViewLoadHelper{
  static void registerToCache(){
    FSCache.addListener(_onCacheTraceVisibleChanged, [FSCache.visibleTraceSettingsPath]);
  }

  static void _onCacheTraceVisibleChanged(){
    final Map<String, List<String>> visibleTraceSettingsDesc = FSCache.read<Map>(FSCache.visibleTraceSettingsPath)?.cast<String, List<String>>() ?? {};
    TraceSettingsProvider.traceSettingNotifier.value.clear();
    TraceSettingsProvider.reload(visibleTraceSettingsDesc);
  }

  static void saveVisible(final String meas){
    if(windowType != WindowType.MAIN_WINDOW){
      localLogger.error("StatisticsViewLoadHelper.saveVisible was called on a non-main process", doNoti: false);
    }

    final List<String> signalsToSave = TraceSettingsProvider.visibleSignals[meas] ?? [];
    for(final String signal in signalsToSave){
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

  static load(final String meas){
    if(windowType != WindowType.CUSTOM_CHART && customChartWindowType != CustomChartWindowType.STATISTICS){
      localLogger.error("StatisticsViewLoadHelper.load was called on a non-statistics process", doNoti: false);
      return;
    }

    signalData.clear();
    signalData[meas] = {};

    final List<String> singalsToLoad = TraceSettingsProvider.visibleSignals[statisticsSelectedMeas] ?? [];
    for(final String signal in singalsToLoad){
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
  }
}

abstract class StatisticsViewLogic{

}