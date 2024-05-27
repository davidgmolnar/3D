import 'package:flutter/material.dart';

import '../../data/calculation/const_eval.dart';
import '../../data/calculation/constants.dart';
import '../../io/logger.dart';
import '../input_widgets/text_fields.dart';
import '../notifications/notification_logic.dart' as noti;
import '../theme/theme.dart';

class EditSingleParameter extends StatelessWidget {
  const EditSingleParameter({super.key, required this.parameterKey, required this.updater});

  final String parameterKey;
  final Function updater;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
            child: Text("$parameterKey:", style: StyleManager.textStyle,),
          ),
          const Spacer(),
          Const.parameterIsBasic(parameterKey) ?
          Container(
            width: 350,
            padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
            child: Center(child: Text(Const.parameters[parameterKey].toString(), style: StyleManager.textStyle,)),
          )
          :
          ToggleableTextField<String>(
            initialValue: Const.parameters[parameterKey].toString(),
            parser: (p0) {
              num? maybeNum = num.tryParse(p0);
              if(maybeNum != null){
                return maybeNum.toString();
              }

              final Evaluation maybeEval = ConstEval.run(p0);
              if(maybeEval.failResult != null){
                noti.NotificationController.add(noti.Notification.decaying(LogEntry.error(maybeEval.failResult!), 10000));
                return null;
              }
              else{
                return maybeEval.value.toString();
              }
            },
            onFinished: (p0) {
              num? maybeNum = num.tryParse(p0);
              if(maybeNum != null){
                Const.addParameter(parameterKey, maybeNum);
                updater();
                return;
              }
              else{
                return;
              }
            },
            width: 350,
          ),
          Const.parameterIsBasic(parameterKey) ?
          const SizedBox(width: 50,)
          :
          IconButton(
            onPressed: () {
              Const.removeParameter(parameterKey);
              updater();
            },
            iconSize: 25,
            padding: const EdgeInsets.all(0),
            icon: Icon(Icons.delete, color: StyleManager.globalStyle.primaryColor,)
          )
        ],
      ),
    );
  }
}

class EditParametersDialog extends StatefulWidget {
  const EditParametersDialog({super.key});

  @override
  State<EditParametersDialog> createState() => _EditParametersDialogState();
}

class _EditParametersDialogState extends State<EditParametersDialog> {
  String newParameter = "New parameter name";
  
  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: Const.parameters.length + 1,
        itemExtent: 30,
        itemBuilder: (context, index) {
          if(index == Const.parameters.length){
            return Row(
              children: [
                ToggleableTextField<String>(
                  onFinished: (p0){
                    newParameter = p0;
                  },
                  parser: (p0) => p0,
                  initialValue: newParameter,
                  width: 200),
                TextButton(
                  onPressed: (){
                    if(Const.parameters.keys.contains(newParameter.toUpperCase())){                      
                      noti.NotificationController.add(noti.Notification.decaying(LogEntry.error("Parameter already exists"), 10000));
                      return;
                    }
                    Const.addParameter(newParameter, 0);
                    newParameter = "New parameter name";
                    update();
                  },
                  child: Text("Add", style: StyleManager.textStyle,)
                ),
              ],
            );
          }
          return EditSingleParameter(parameterKey: Const.parameters.keys.elementAt(index), updater: update,);
        }
      ),
    );
  }
}