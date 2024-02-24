import 'dart:io';

import 'package:dart_dbc_parser/dart_dbc_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../io/logger.dart';
import '../common.dart';
import '../theme/theme.dart';
import 'dialog_base.dart';

class DBCSelectorDialog extends StatefulWidget {
  const DBCSelectorDialog({super.key});

  @override
  State<DBCSelectorDialog> createState() => DBCSelectorDialogState();
}

class DBCSelectorDialogState extends State<DBCSelectorDialog> {
  late final List<String> canPathList;

  @override
  void initState() {
    canPathList = SettingsProvider.get("dbc.pathlist")?.selection ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      height: 400,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Selected DBC files", style: StyleManager.subTitleStyle,),
              ),
              const Spacer(),
              TextButton(
                onPressed: (() async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    dialogTitle: "Pick DBC files",
                    allowedExtensions: ["dbc"],
                    type: FileType.custom,
                    allowMultiple: true,
                  );
                  if(result != null){
                    if(result.paths.every((element) => element != null)){
                      for(int i = 0; i < result.paths.length; i++){
                        try{
                          DBCDatabase temp = await DBCDatabase.loadFromFile([File(result.paths[i]!)]);
                          if(temp.database.isNotEmpty && !canPathList.contains(result.paths[i]) ){
                            canPathList.add(result.paths[i]!);
                            SettingsProvider.update("dbc.pathlist", canPathList);
                            localLogger.info("Added new files into DBC database");
                          }
                          else{
                            // ignore: use_build_context_synchronously
                            showError(context, "DBC structure for ${result.paths[i]!.split('\\').last} is either not valid or this file was already added");
                          }
                        }
                        catch (exc) {
                          localLogger.warning("Failed to add some files into DBC database");
                        }
                      }
                    }
                  }
                  setState(() {
                    
                  });
                }),
                child: const Text("New")
              )
            ],
          ),
          SizedBox(
            height: 400 - dialogTitleBarHeight - 50,
            width: 700 - 2 * StyleManager.globalStyle.padding,
            child: ListView.builder(
              itemCount: canPathList.length,
              itemExtent: 50,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    SizedBox(
                      width: 600,
                      child: Text(
                        canPathList[index],
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        canPathList.removeAt(index);
                        SettingsProvider.update("dbc.pathlist", canPathList);
                        setState(() {});
                      },
                      icon: Icon(Icons.delete, color: StyleManager.globalStyle.primaryColor,),
                      splashRadius: 20,
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}