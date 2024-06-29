import 'dart:math';

import 'package:flutter/material.dart';

import '../../../io/logger.dart';
import '../../../ui/charts/chart_logic/axis_data.dart';
import '../../../ui/theme/theme.dart';
import '../custom_chart_logic/statistics_processor.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewPlotContainer extends StatefulWidget {
  const StatisticsViewPlotContainer({super.key});

  @override
  State<StatisticsViewPlotContainer> createState() => _StatisticsViewPlotContainerState();
}

class _StatisticsViewPlotContainerState extends State<StatisticsViewPlotContainer> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_reDrawNeeded, ["plot.signal", "plot.type", "plot.configs", "data.meas"]);
    super.initState();
  }

  void _reDrawNeeded(){
    if(StatisticsViewController.notifier.value["plot.signal"] != null && StatisticsViewController.notifier.value["data.meas"] != null){
      StatisticsViewController.notifier.value["plot.datas"][StatisticsViewController.notifier.value["plot.type"]].recalc(
        StatisticsViewController.notifier.value["data.meas"],
        StatisticsViewController.notifier.value["plot.signal"],
        StatisticsViewController.notifier.value["plot.configs"][StatisticsViewController.notifier.value["plot.type"]]
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if(StatisticsViewController.notifier.value["plot.signal"] == null){
      return Container(
        height: 400,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
        )
      );
    }
    final double width = MediaQuery.of(context).size.width;
    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 399,
            width: width - 300,
            child: Center(
              child: CustomPaint(
                size: Size(width - 340, 380),
                painter: StatisticsViewController.notifier.value["plot.type"] == StatistiscsViewPlotType.HIST ?
                  HistogramPainter(hist: StatisticsViewController.notifier.value["plot.datas"][StatisticsViewController.notifier.value["plot.type"]] as Histogram)
                  :
                  StatisticsViewController.notifier.value["plot.type"] == StatistiscsViewPlotType.PDF ?
                  PDFPainter(pdf: StatisticsViewController.notifier.value["plot.datas"][StatisticsViewController.notifier.value["plot.type"]] as PDF)
                  :
                  CDFPainter(cdf: StatisticsViewController.notifier.value["plot.datas"][StatisticsViewController.notifier.value["plot.type"]] as CDF)
              ),
            ),
          ),
          StatisticsPlotConfigView(
            onChanged: _reDrawNeeded
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_reDrawNeeded);
    super.dispose();
  }
}

class StatisticsPlotConfigView extends StatelessWidget {
  const StatisticsPlotConfigView({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 300,
      decoration: BoxDecoration(
        color: StyleManager.globalStyle.secondaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(StyleManager.globalStyle.padding))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for(final MapEntry<String, num> param in StatisticsViewController.plotConfig.entries)
            StatisticsPlotConfigElement(
              param: param,
              minmax: StatisticsViewController.plotConfigMinMax,
              onChanged: (final double value){
                StatisticsViewController.updatePlotConfig(param.key, value);
                onChanged();
              }
            )
        ],
      ),
    );
  }
}

class StatisticsPlotConfigElement extends StatelessWidget {
  const StatisticsPlotConfigElement({super.key, required this.param, required this.minmax, required this.onChanged});

  final MapEntry<String, num> param;
  final Offset minmax;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${param.key}: ${param.value}",
          style: StyleManager.textStyle,
        ),
        Slider(
          min: minmax.dx,
          max: minmax.dy,
          value: param.value.toDouble(),
          onChanged: onChanged,
          activeColor: StyleManager.globalStyle.primaryColor,
          inactiveColor: StyleManager.globalStyle.bgColor,
        )
      ],
    );
  }
}

class HistogramPainter extends CustomPainter {
  final Histogram hist;

  HistogramPainter({super.repaint, required this.hist});

  @override
  void paint(Canvas canvas, Size size) {
    try{
    canvas.clipRect(Rect.fromPoints(const Offset(-10, -10), Offset(size.width + 10, size.height + 10)));

    final TextPainter textPainterBase = TextPainter(
      text: TextSpan(
        text: "DEFAULT TEXT",
        style: StyleManager.textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    final Paint paintBase = Paint()..color = StyleManager.globalStyle.primaryColor..style = PaintingStyle.stroke..strokeWidth = 0.5;

    const double inset = 10;

    // xaxis
    final num xAxisValueMin = hist.bins.isEmpty ? 0.0 : hist.bins.first.start;
    final num xAxisValueMax = hist.bins.isEmpty ? 1.0 : hist.bins.last.stop;
    final ValueAxisData xAxisData = ValueAxisData.from(xAxisValueMin, xAxisValueMax - xAxisValueMin, size.width - 2 * inset, null);
    
    final Path xAxisPath = Path();
    xAxisPath.moveTo(inset, -(inset - size.height));
    xAxisPath.lineTo(size.width - inset, -(inset - size.height));
    for(int i = 0; i < xAxisData.majorTickPositions.length; i++){
      xAxisPath.moveTo(xAxisData.majorTickPositions[i] + inset, -(inset - size.height));
      xAxisPath.lineTo(xAxisData.majorTickPositions[i] + inset, -(inset / 2 - size.height));

      final TextPainter tp = textPainterBase..text = TextSpan(
        text: xAxisData.majorTickValues[i].toString(),
        style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
      );
      tp.layout();
      final Offset majorPos = Offset(xAxisData.majorTickPositions[i] + inset, size.height);
      tp.paint(canvas, majorPos.translate(-tp.width / 2, -10));
    }
    for(final double tick in xAxisData.tickPositions){
      xAxisPath.moveTo(tick, -(inset - size.height));
      xAxisPath.lineTo(tick, -(3 * inset / 4 - size.height));
    }

    canvas.drawPath(xAxisPath, paintBase);
    canvas.rotate(1.5 * 3.14159265359);

    // yaxis
    const int yAxisValueMin = 0;
    final int yAxisValueMax = hist.bins.isEmpty ? 1 : hist.bins.fold(0, (previousValue, element) => max(previousValue, element.value.toInt()));
    final ValueAxisData yAxisData = ValueAxisData.from(yAxisValueMin, yAxisValueMax - yAxisValueMin, size.height - 2 * inset, null);

    final Path yAxisPath = Path();
    yAxisPath.moveTo(inset - size.height, inset);
    yAxisPath.lineTo(-inset, inset);
    for(int i = 0; i < yAxisData.majorTickPositions.length; i++){
      yAxisPath.moveTo(yAxisData.majorTickPositions[i] - size.height + inset, inset);
      yAxisPath.lineTo(yAxisData.majorTickPositions[i] - size.height + inset, inset / 2);

      final TextPainter tp = textPainterBase..text = TextSpan(
        text: yAxisData.majorTickValues[i].toString(),
        style: StyleManager.textStyle.copyWith(color: StyleManager.globalStyle.primaryColor),
      );
      tp.layout();
      final Offset majorPos = Offset(yAxisData.majorTickPositions[i] - size.height + inset, -5);
      tp.paint(canvas, majorPos.translate(-10, -tp.height / 2));
    }
    for(final double tick in yAxisData.tickPositions){
      yAxisPath.moveTo(tick - size.height + inset, inset);
      yAxisPath.lineTo(tick - size.height + inset, 3 * inset / 4);
    }

    canvas.drawPath(yAxisPath, paintBase);
    canvas.rotate(-1.5 * 3.14159265359);

    // bins
    if(hist.bins.isEmpty){
      return;
    }
    final Path histPath = Path();
    final List<Offset> histValuePoints = [];
    histValuePoints.add(Offset(hist.bins.first.start.toDouble(), 0));
    for(final HistogramBin bin in hist.bins){
      histValuePoints.add(Offset(
        bin.start.toDouble(),
        bin.value.toDouble()
      ));      
      histValuePoints.add(Offset(
        bin.stop.toDouble(),
        bin.value.toDouble()
      ));
    }
    histValuePoints.add(Offset(hist.bins.last.stop.toDouble(), 0));
    histValuePoints.add(histValuePoints.first);

    final double xOffset =  - xAxisValueMin.toDouble();
    final double xMult = (size.width - 2 * inset) / (xAxisValueMax - xAxisValueMin);
    final double yOffset = yAxisValueMin.toDouble();
    final double yMult = (size.height - 2 * inset) / (yAxisValueMax - yAxisValueMin);

    histPath.moveTo((histValuePoints.first.dx + xOffset) * xMult + inset, -((histValuePoints.first.dy + yOffset) * yMult - size.height + inset));
    for(final Offset point in histValuePoints.skip(1)){
      histPath.lineTo((point.dx + xOffset) * xMult + inset, -((point.dy + yOffset) * yMult - size.height + inset));
    }
    canvas.drawPath(histPath, paintBase..style = PaintingStyle.fill);

    }
    catch(ex, stack){
      localLogger.info("$ex $stack");
    }
  }

  @override
  bool shouldRepaint(HistogramPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(HistogramPainter oldDelegate) => false;
}

class PDFPainter extends CustomPainter {
  final PDF pdf;

  PDFPainter({super.repaint, required this.pdf});

  @override
  void paint(Canvas canvas, Size size) {
  }

  @override
  bool shouldRepaint(PDFPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(PDFPainter oldDelegate) => false;
}

class CDFPainter extends CustomPainter {
  final CDF cdf;

  CDFPainter({super.repaint, required this.cdf});

  @override
  void paint(Canvas canvas, Size size) {
  }

  @override
  bool shouldRepaint(CDFPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CDFPainter oldDelegate) => false;
}