import 'package:flutter/material.dart';

class ChartScaler extends StatelessWidget {
  const ChartScaler({super.key, required this.chartUpdater});

  final Function chartUpdater;

  @override
  Widget build(BuildContext context) {
    return Container(width: 100, color: Colors.amber,);
  }
}