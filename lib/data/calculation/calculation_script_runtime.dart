import 'dart:io';

import '../../io/file_system.dart';
import '../../io/logger.dart';
import '../data.dart';
import '../settings.dart';
import 'calculation_script_execution.dart';
import 'calculation_script_parsing.dart';

const String __calibPath = "Calculation/";

class CalculationScriptRuntime{

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

      final LogEntry entry = LogEntry.error("Cannot run calculation file on measurement $measurement as it has unmet required channels: $unmetChannels");
      localLogger.add(entry);
      if(progressIndication != null){
        progressIndication(0, entry.asString("CALCULATION"));
      }
      return false;

    }
    final LogEntry entry = LogEntry.error("Cannot run calculation file on measurement $measurement as it does not exist, available measurements are: ${signalData.keys}");
    localLogger.add(entry);
    if(progressIndication != null){
      progressIndication(0, entry.asString("CALCULATION"));
    }
    return false;
  }

  static Future<void> __recommendRun(final List<String> requiredChannels, {Function(double, String?)? progressIndication}) async {
    final List<FileSystemEntity> elements = await FileSystem.tryListElementsInLocalAsync(__calibPath);
    final Set<String> requirements = requiredChannels.toSet();
    for(FileSystemEntity file in elements.whereType<File>()){
      final String filename = file.uri.path.split('/').last;
      Map calculationJson = await FileSystem.tryLoadMapFromLocalAsync(__calibPath, "$filename.comp");
      final Set<String> results = calculationJson["resultChannels"]?.toSet() ?? {};
      final Set<String> intersect = requirements.intersection(results);
      if(intersect.isNotEmpty){
        final LogEntry entry = LogEntry.info("Running calculation file ${calculationJson['filename']} would create some required channels: ${intersect.toList()}");
        localLogger.add(entry);
        if(progressIndication != null){
          progressIndication(0, entry.asString("CALCULATION"));
        }
      }
      results.clear();
      intersect.clear();
    }
  }

  static bool __wasCompiled(final String filename){
    return FileSystem.tryListElementsInLocalSync(__calibPath).any(
      (element) => element is File && element.uri.path.split('/').last == filename
    );
  }

  static Future<void> run(final File file, final CalculationOptions options, {Function(double, String?)? progressIndication, int? indicationCount}) async {
    final bool doIndication = progressIndication != null && indicationCount != null;

    final CompiledCalculation? calculation = await runCompilationOnly(file, options.cleanRebuild, progressIndication: progressIndication);
    if(calculation == null){
      return;
    }

    if(doIndication){
      progressIndication(0, null);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if(!__canRun(calculation.requiredChannels, options.measurement, progressIndication: progressIndication)){
      await __recommendRun(calculation.requiredChannels, progressIndication: progressIndication);
      return;
    }
    
    try{
      await CalculationScriptProcessor.exec(calculation.instructions, options, progressIndication: progressIndication, indicationCount: indicationCount);
    }
    catch(ex){
      final LogEntry entry = LogEntry.error("Exception when running script: ${ex.toString()}");
      localLogger.add(entry);
      if(doIndication){
        progressIndication(1, entry.asString(localLogger.loggerName));
      }
    }

    __updateTraceSettings(options.measurement, calculation.resultChannels);
  }

  static Future<CompiledCalculation?> runCompilationOnly(final File file, final bool cleanRebuild, {Function(double, String?)? progressIndication}) async {
    final bool doIndication = progressIndication != null;

    late final CompiledCalculation calculation;
    bool needsCompilation = true;
    final String filename = file.uri.path.split('/').last;
    if(__wasCompiled("$filename.comp")){
      if(cleanRebuild){
        await FileSystem.tryDeleteFromLocalAsync(__calibPath, "$filename.comp");
      }
      else{
        Map calculationJson = await FileSystem.tryLoadMapFromLocalAsync(__calibPath, "$filename.comp");
        if(calculationJson.isNotEmpty){
          CompiledCalculation? calculationTmp = CompiledCalculation.fromJson(calculationJson);
          if(calculationTmp != null && await CalculationScriptParser.validate(calculationTmp) && calculationTmp.fileLastModified == await file.lastModified()){
            calculation = calculationTmp;
            needsCompilation = false;

            LogEntry entry = LogEntry.info("Found valid previously compiled version");
            localLogger.add(entry);
            if(doIndication){
              progressIndication(1, entry.asString("CALCULATION"));
              await Future.delayed(const Duration(milliseconds: 10));
            }

            return calculation;
          }
          else{
            LogEntry entry = LogEntry.error("Invalidated previously compiled version, recompiling");
            localLogger.add(entry);
            if(doIndication){
              progressIndication(1, entry.asString("CALCULATION"));
              await Future.delayed(const Duration(milliseconds: 10));
            }
            await FileSystem.tryDeleteFromLocalAsync(__calibPath, "$filename.comp");
          }
        }
      }
    }

    bool calculationValid = true;
    if(needsCompilation){
      calculation = await CalculationScriptParser.run(file);
      localLogger.addAll(calculation.context);
      calculationValid &= await CalculationScriptParser.validate(calculation);

      if(!calculationValid){
        LogEntry entry = LogEntry.error("Build validation failed");
        localLogger.add(entry);
        if(doIndication){
          progressIndication(1, entry.asString("CALCULATION"));
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      calculationValid &= !calculation.context.any((entry) => entry.level == LogLevel.ERROR || entry.level == LogLevel.CRITICAL);
      if(!calculationValid){
        LogEntry entry = LogEntry.error("Build had some errors:");
        localLogger.add(entry);
        if(doIndication){
          progressIndication(1, entry.asString("CALCULATION"));
          await Future.delayed(const Duration(milliseconds: 10));
        }

        for(LogEntry entry in calculation.context){
          if(entry.level == LogLevel.ERROR || entry.level == LogLevel.CRITICAL){
            localLogger.add(entry);
            if(doIndication){
              progressIndication(1, entry.asString("CALCULATION"));
              await Future.delayed(const Duration(milliseconds: 10));
            }
          }
        }
      }
    }


    if(calculationValid){
      FileSystem.trySaveMapToLocalAsync(__calibPath, "$filename.comp", calculation.toJson());
      
      LogEntry entry = LogEntry.info("Successfully compiled $filename");
      localLogger.add(entry);
      if(doIndication){
        progressIndication(1, entry.asString("CALCULATION"));
        await Future.delayed(const Duration(milliseconds: 10));
      }

      return calculation;
    }
    else{
      LogEntry entry = LogEntry.error("Build failed");
      FileSystem.tryDeleteFromLocalAsync(__calibPath, "$filename.comp");
      localLogger.add(entry);
      if(doIndication){
        progressIndication(1, entry.asString("CALCULATION"));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return null;
    }
  }

  static void __updateTraceSettings(final String measurement, final List<String> signals){
    if(!signalData.containsKey(measurement)){
      localLogger.error("Measurement $measurement referenced by __updateTraceSettings did not exist");
      return;
    }
    TraceSettingsProvider.updateEntriesFrom(measurement, signals);
  }
}
