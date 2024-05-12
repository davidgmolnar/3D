import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

const double dialogTitleBarHeight = 50.0;

class DialogTitleBar extends StatelessWidget{
  const DialogTitleBar({super.key, required this.parentContext, required this.title});

  final BuildContext parentContext;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dialogTitleBarHeight,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: StyleManager.globalStyle.primaryColor)), color: StyleManager.globalStyle.secondaryColor),
      child: Row(
        children: [
          Padding(padding: EdgeInsets.only(left: 4 * StyleManager.globalStyle.padding), child: Text(title, style: TextStyle(fontSize: StyleManager.globalStyle.subTitleFontSize),),),
          const Spacer(),
          IconButton(
            onPressed: (){
              Navigator.of(parentContext).pop();
            },
            splashRadius: 20.0,
            icon: Icon(Icons.close, color: StyleManager.globalStyle.primaryColor,)
          )
        ],
      ),
    );
  }
}

class DialogBase extends StatelessWidget{
  final String title;
  final Widget dialog;
  final double minWidth;
  final double? maxWidth;
  final double? maxHeight;

  const DialogBase({super.key, required this.title, required this.dialog, required this.minWidth, this.maxWidth, this.maxHeight});
  
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = max(size.width * 0.3, minWidth);
    if(maxWidth != null){
      width = min(width, maxWidth!);
    }
    return Dialog(
      elevation: 10,
      child: Container(
        height: maxHeight == null ? size.height : min(maxHeight!, size.height),
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: StyleManager.globalStyle.primaryColor, width: 1),
          color: StyleManager.globalStyle.bgColor
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogTitleBar(parentContext: context, title: title),
            dialog
          ],
        ),
      ),
    );
  }
}