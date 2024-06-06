import '../../io/logger.dart';

abstract class CSVReformatter{

  static bool _isAlphanum(String s) {
    return RegExp(r'^[a-zA-Z0-9]+').hasMatch(s);
  }

  static bool _isNum(String s) {
    return RegExp(r'^[0-9]+').hasMatch(s);
  }

  static List<String> convert(final String raw, final Function(LogEntry) onMessage, {final String targetLineSep = ',', final String targetDecimalSep = '.'}){
    raw.replaceAll('"', '');

    final List<String> lines = raw.split('\n');
    final String cols = lines[0].trim();
    final String firstDataLine = lines[2].trim();  // TODO check lines size
    
    String lineSepFound = "";
    for(int i = 0; i < cols.length; i++){
      if(!_isAlphanum(cols[i])){
        lineSepFound += cols[i];
      }
      else if(lineSepFound.isNotEmpty){
        break;                                     // TODO onMessage
      }
    }

    String decimalSepFound = "";
    final List<String> colValues = firstDataLine.split(lineSepFound);
    for(final String colValue in colValues){
      if(!_isNum(colValue)){
        for(int i = 0; i < colValue.length; i++){
          if(!_isNum(colValue[i])){
            decimalSepFound += colValue[i];
          }
          else if(decimalSepFound.isNotEmpty){
            break;                                     // TODO onMessage
          }
        }
      }
    }

    final bool hasLineSep = lineSepFound.isNotEmpty;  // one col
    final bool hasDecimalSep = decimalSepFound.isNotEmpty;  // all ints
  }
}