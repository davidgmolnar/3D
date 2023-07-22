import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:log_analyser/data/settings.dart';
import 'package:log_analyser/routes/settings/settings_logic/settings_window_type.dart';

import '../../../multiprocess/childprocess_api.dart';
import '../../../multiprocess/childprocess_controller.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/toolbar/toolbar_item.dart';
import '../../log/log_logic/log_window_action_type.dart';
import '../../startup.dart';
import '../../window_type.dart';

class MainWindowToolbar extends StatelessWidget {
  const MainWindowToolbar({super.key});

  static _importLogWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.LOG, WindowSetupInfo("Import Log", const Size(1000,700), const Offset(0,0)));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setLogWindowTypePayload(LogWindowType.IMPORT)));
  }
  static _importCALWindow (){}
  static _importUIWindow (){}

  static _exportLogWindow (){}

  static _calfileRunnerWindow (){}
  static _traceEditorWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.SETTINGS, WindowSetupInfo("Trace Editor", const Size(1000,700), const Offset(0,0)));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsWindowTypePayload(SettingsWindowType.TRACE_EDITOR)));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsTraceEditorSetupPayload(TraceSettingsProvider.toJsonFormattable)));
  }
  static _calfileCreatorWindow (){}
  static _settingsWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.SETTINGS, WindowSetupInfo("Settings", const Size(500,700), const Offset(0,0)));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsWindowTypePayload(SettingsWindowType.SETTINGS)));
  }
  static _logWindow (){}

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
    ToolbarItem(iconData: Icons.receipt, onPressed: _logWindow),
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
    ToolbarDropdownItem(onPressed: _logWindow, text: "Log"),
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