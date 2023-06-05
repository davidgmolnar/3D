import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:log_analyser/multiprocess/childprocess_api.dart';
import 'package:log_analyser/ui/theme.dart';

import '../../../multiprocess/childprocess_controller.dart';
import '../../../ui/toolbar_item.dart';
import '../../window_type.dart';

class MainWindowToolbar extends StatelessWidget {
  const MainWindowToolbar({super.key});

  static _importLogWindow (){}
  static _importCALWindow (){}
  static _importUIWindow (){}

  static _exportLogWindow (){}

  static _calfileRunnerWindow (){}
  static _traceEditorWindow (){}
  static _calfileCreatorWindow (){}
  static _settingsWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.SETTINGS);
    ChildProcessController.sendTo(Command(port, CommandType.DATA, {"yoo": "miafasz"}));
  }

  static const List<Widget> _mainWindowToolbarItems = [
    ToolbarItemWithDropdown(iconData: FontAwesomeIcons.fileImport, dropdownItems: [
      ToolbarDropdownItem(onPressed: _importLogWindow, text: "Import Log"),
      ToolbarDropdownItem(onPressed: _importCALWindow, text: "Import Calfile"),
      ToolbarDropdownItem(onPressed: _importUIWindow, text: "Import UI file"),
    ],),
    ToolbarItem(iconData: FontAwesomeIcons.fileExport,  onPressed: _exportLogWindow,),
    ToolbarItem(iconData: Icons.calculate, onPressed: _calfileRunnerWindow),
    ToolbarItem(iconData: FontAwesomeIcons.chartLine, onPressed: _traceEditorWindow),
    ToolbarItemWithDropdown(iconData: Icons.grid_view_sharp, dropdownItems: [],),
    ToolbarItem(iconData: Icons.create, onPressed: _calfileCreatorWindow),
    ToolbarItem(iconData: Icons.settings, onPressed: _settingsWindow),
  ];

  static const List<ToolbarDropdownItem> _mainWindowToolbarItemsHidden = [
    ToolbarDropdownItem(onPressed: _importLogWindow, text: "Import Log"),
    ToolbarDropdownItem(onPressed: _importCALWindow, text: "Import Calfile"),
    ToolbarDropdownItem(onPressed: _importUIWindow, text: "Import UI file"),
    ToolbarDropdownItem(onPressed: _exportLogWindow, text: "Export Log"),
    ToolbarDropdownItem(onPressed: _calfileRunnerWindow, text: "Run Calfile"),
    ToolbarDropdownItem(onPressed: _traceEditorWindow, text: "Open Trace Editor"),
    ToolbarDropdownItem(onPressed: _calfileCreatorWindow, text: "Create/Test Calfile"),
    ToolbarDropdownItem(onPressed: _settingsWindow, text: "Settings"),
  ];

  static int _mainWindowToolbarItemsHiddenSkip(int i) => 
    _mainWindowToolbarItems.take(i).fold(0, (previousValue, element) {
      previousValue += element is ToolbarItemWithDropdown ? element.dropdownItems.length : 1;
      return previousValue;
    });

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: StyleManager.globalStyle.secondaryColor, width: 1),)),
          child: Row(
            children: _mainWindowToolbarItems.length * 50 < constraints.maxWidth ?
              _mainWindowToolbarItems
              :
              [
              for(i = 0; i < (constraints.maxWidth - 50) ~/ 50; i++)
                _mainWindowToolbarItems[i],
              ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: _mainWindowToolbarItemsHidden.skip(_mainWindowToolbarItemsHiddenSkip(i)).toList(),)
              ]
          ),
        );
      }
    );
  }
}