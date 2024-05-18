import 'package:flutter/material.dart';

import '../../../ui/toolbar/toolbar_item.dart';

class CustomChartToolbar extends StatelessWidget {
  const CustomChartToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: toolbarItemSize,
      child: Center(
        child: Text("TODO Toolbar to leave/enter sharingGroup, toggle each signal visibility with a row of TextButtons colored with the TraceSetting's color, etc"),
      ),
    );
  }
}