import 'dart:math';

double _roundToDecimalPlaces(double value, int places){ 
   num mod = pow(10, places); 
   return (value * mod).round().toDouble() / mod; 
}

const int _majorTickCount = 5;
const int _tickPerMajorTick = 4;

class ValueAxisData{
  final List<double> tickPositions;
  final List<double> majorTickPositions;
  final List<num> majorTickValues;
  final String? unit;

  const ValueAxisData(this.tickPositions, this.majorTickPositions, this.majorTickValues, this.unit);

  static ValueAxisData from(final num startValue, final num range, final double axisLength, final String? unit){
    final List<num> majorTickValues = List.generate(_majorTickCount, ((index) {
      return (range / (_majorTickCount + 1) * (index + 1) + startValue);
    }));

    final List<double> majorTickPositions = List.generate(_majorTickCount, ((index) {
      return _roundToDecimalPlaces(majorTickValues[index] / range * axisLength, 3);
    }));

    const initialTickCount = (_majorTickCount + 1) * _tickPerMajorTick;
    final List<double> tickPositions = List.generate(initialTickCount, ((index) {
      return _roundToDecimalPlaces(index * axisLength/initialTickCount, 3);
    }));

    tickPositions.removeWhere((element) => majorTickPositions.contains(element));

    return ValueAxisData(tickPositions, majorTickPositions, majorTickValues, unit);
  }
}