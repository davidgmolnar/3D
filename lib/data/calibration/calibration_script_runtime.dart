import 'dart:io';

import '../../io/file_system.dart';
import '../../io/logger.dart';
import '../data.dart';
import 'calibration_script_execution.dart';
import 'calibration_script_parsing.dart';

const String __calibPath = "Calibration/";

class CalibrationScriptRuntime{

  static bool __canRun(final List<String> requiredChannels, final String measurement, {Function(double, String?)? progressIndication}){
    if(signalData.containsKey(measurement)){
      if(requiredChannels.every((channel){
        return signalData[measurement]!.containsKey(channel);
      })){
        return true;
      }

      final List<String> unmetChannels = requiredChannels.where((channel){
        return !signalData[measurement]!.containsKey(channel);
      }).toList();

      final LogEntry entry = LogEntry.error("Cannot run calibration file on measurement $measurement as it has unmet required channels: $unmetChannels");
      localLogger.add(entry);
      if(progressIndication != null){
        progressIndication(0, entry.asString("CALIBRATION"));
      }

    }
    final LogEntry entry = LogEntry.error("Cannot run calibration file on measurement $measurement as it does not exist");
    localLogger.add(entry);
    if(progressIndication != null){
      progressIndication(0, entry.asString("CALIBRATION"));
    }
    return false;
  }

  static Future<void> __recommendRun(final List<String> requiredChannels, {Function(double, String?)? progressIndication}) async {
    final List<FileSystemEntity> elements = await FileSystem.tryListElementsInLocalAsync(__calibPath);
    final Set<String> requirements = requiredChannels.toSet();
    for(FileSystemEntity file in elements.whereType<File>()){
      final String filename = file.uri.path.split('/').last;
      Map calibrationJson = await FileSystem.tryLoadMapFromLocalAsync(__calibPath, filename);
      final Set<String> results = calibrationJson["resultChannels"].toSet();
      final Set<String> intersect = requirements.intersection(results);
      if(intersect.isNotEmpty){
        final LogEntry entry = LogEntry.info("Running calibration file ${calibrationJson['filename']} would create some required channels: ${intersect.toList()}");
        localLogger.add(entry);
        if(progressIndication != null){
          progressIndication(0, entry.asString("CALIBRATION"));
        }
      }
      results.clear();
      intersect.clear();
    }
  }

  static Future<bool> __wasCompiled(final String filename, {Function(double, String?)? progressIndication}) async {
    final List<FileSystemEntity> elements = await FileSystem.tryListElementsInLocalAsync(__calibPath);
    return elements.any((element) => element is File && element.uri.path.split('/').last == "$filename.comp");
  }

  static Future<void> run(final File file, final CalibrationOptions options, {Function(double, String?)? progressIndication, int? indicationCount}) async {
    final bool doIndication = progressIndication != null && indicationCount != null;

    final CompiledCalibration? calibration = await runCompilationOnly(file, options.cleanRebuild, progressIndication: progressIndication);
    if(calibration == null){
      return;
    }

    if(doIndication){
      progressIndication(0, null);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if(!__canRun(calibration.requiredChannels, options.measurement, progressIndication: progressIndication)){
      await __recommendRun(calibration.requiredChannels, progressIndication: progressIndication);
      return;
    }
    
    try{
      CalibrationScriptProcessor.exec(calibration.instructions, options, progressIndication: progressIndication, indicationCount: indicationCount);
    }
    catch(ex){
      final LogEntry entry = LogEntry.error("Exception when running script: ${ex.toString()}");
      localLogger.add(entry);
      if(doIndication){
        progressIndication(1, entry.asString(localLogger.loggerName));
      }
    }
  }

  static Future<CompiledCalibration?> runCompilationOnly(final File file, final bool cleanRebuild, {Function(double, String?)? progressIndication}) async {
    final bool doIndication = progressIndication != null;

    late final CompiledCalibration calibration;
    bool needsCompilation = true;
    final String filename = file.uri.path.split('/').last;
    if(await __wasCompiled(filename, progressIndication: progressIndication)){
      if(cleanRebuild){
        await FileSystem.tryDeleteFromLocalAsync(__calibPath, filename);
      }
      else{
        Map calibrationJson = await FileSystem.tryLoadMapFromLocalAsync(__calibPath, filename);
        if(calibrationJson.isNotEmpty){
          CompiledCalibration? calibrationTmp = CompiledCalibration.fromJson(calibrationJson);
          if(calibrationTmp != null && await CalibrationScriptParser.validate(calibrationTmp) && calibrationTmp.fileLastModified == await file.lastModified()){
            calibration = calibrationTmp;
            needsCompilation = false;
          }
          else{
            await FileSystem.tryDeleteFromLocalAsync(__calibPath, filename);
          }
        }
      }
    }

    bool calibrationValid = true;
    if(needsCompilation){
      calibration = await CalibrationScriptParser.run(file);
      localLogger.addAll(calibration.context);
      calibrationValid &= await CalibrationScriptParser.validate(calibration);
      calibrationValid &= calibration.context.any((entry) => entry.level == LogLevel.ERROR || entry.level == LogLevel.CRITICAL);
    }


    if(calibrationValid){
      FileSystem.trySaveMapToLocalAsync(__calibPath, "$filename.comp", calibration.toJson());
      return calibration;
    }
    else{
      LogEntry entry = LogEntry.error("Build failed");
      FileSystem.tryDeleteFromLocalAsync(__calibPath, filename);
      localLogger.add(entry);
      if(doIndication){
        progressIndication(1, entry.asString("CALIBRATION"));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return null;
    }
  }
}
