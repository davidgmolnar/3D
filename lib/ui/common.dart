import 'package:flutter/material.dart';

import 'theme/theme.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

void rebuildAllChildren(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }
  (context as Element).visitChildren(rebuild);
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(BuildContext context, String message){
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: StyleManager.subTitleStyle,),
      backgroundColor: Colors.red,
    )
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorWithoutContext(String message){
  return snackbarKey.currentState!.showSnackBar(
    SnackBar(
      content: Text(message, style: StyleManager.subTitleStyle,),
      backgroundColor: Colors.red,
    )
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo(BuildContext context, String message){
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: StyleManager.subTitleStyle,),
      backgroundColor: Colors.green,
    )
  );
}