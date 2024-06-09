import '../../io/logger.dart';

abstract class CSVReformatter{

  static const String _intermediateLineSep = "-|-";
  static const String _intermediateDecimalSep = "-\\-";

  static bool _isColumnDef(String s) {
    return RegExp(r'^[a-zA-Z0-9-_]+').hasMatch(s);
  }

  static bool _isNum(String s) {
    return RegExp(r'^[0-9-.]+').hasMatch(s) && !s.contains(',');
  }

  static List<String> convert(final String raw, final Function(LogEntry) onMessage, {final String targetLineSep = ',', final String targetDecimalSep = '.'}){
    final List<String> lines = raw.replaceAll('"', '').split('\n');
    if(lines.length < 3){
      return lines;
    }
    final String cols = lines[0].trim();
    final String firstDataLine = lines[2].trim();
    
    String lineSepFound = "";
    for(int i = 0; i < cols.length; i++){
      if(!_isColumnDef(cols[i])){
        lineSepFound += cols[i];
      }
      else if(lineSepFound.isNotEmpty){
        onMessage(LogEntry.info("Line sep found: '$lineSepFound'"));
        break;
      }
    }

    String decimalSepFound = "";
    final List<String> colValues = firstDataLine.split(lineSepFound);
    for(final String colValue in colValues){
      if(decimalSepFound.isNotEmpty){
        break;
      }
      if(!_isNum(colValue)){
        for(int i = 0; i < colValue.length; i++){
          if(!_isNum(colValue[i])){
            decimalSepFound += colValue[i];
          }
          else if(decimalSepFound.isNotEmpty){
            onMessage(LogEntry.info("Decimal sep found: '$decimalSepFound'"));
            break;
          }
        }
      }
    }

    if(lineSepFound.isNotEmpty && decimalSepFound.isNotEmpty){
      for (int i = 0; i < lines.length; i++){
        lines[i] = lines[i].replaceAll(lineSepFound, _intermediateLineSep);
        lines[i] = lines[i].replaceAll(decimalSepFound, _intermediateDecimalSep);
      }

      for (int i = 0; i < lines.length; i++){
        lines[i] = lines[i].replaceAll(_intermediateLineSep, targetLineSep);
        lines[i] = lines[i].replaceAll(_intermediateDecimalSep, targetDecimalSep);
      }
    }
    else if(lineSepFound.isNotEmpty){
      for (int i = 0; i < lines.length; i++){
        lines[i] = lines[i].replaceAll(lineSepFound, targetLineSep);
      }
    }
    else if(decimalSepFound.isNotEmpty){
      for (int i = 0; i < lines.length; i++){
        lines[i] = lines[i].replaceAll(decimalSepFound, targetDecimalSep);
      }
    }
    return lines;
  }
}