import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/settings.dart';
import '../../../io/logger.dart';
import '../../../multiprocess/childprocess_api.dart';
import '../../../multiprocess/childprocess_controller.dart';
import '../../../ui/dialogs/characteristics_setup_dialog.dart';
import '../../../ui/dialogs/chart_grid_setup_dialog.dart';
import '../../../ui/dialogs/dbc_selector_dialog.dart';
import '../../../ui/dialogs/dialog_base.dart';
import '../../../ui/dialogs/edit_parameters_dialog.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/toolbar/toolbar_item.dart';
import '../../custom_chart/custom_chart_logic/custom_chart_window_type.dart';
import '../../log/log_logic/log_window_action_type.dart';
import '../../settings/settings_logic/settings_window_type.dart';
import '../../startup.dart';
import '../../window_type.dart';
import '../screen.dart';

class MainWindowToolbar extends StatelessWidget {
  const MainWindowToolbar({super.key});

  static Offset _getCenterOffset(final Size size){
    return WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.center(Offset.zero) - size.center(Offset.zero);
  }

  static void _importLogWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.LOG, WindowSetupInfo("Import Log", const Size(1000,700), _getCenterOffset(const Size(1000,700))));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setLogWindowTypePayload(LogWindowType.IMPORT)));
  }

  static void _importCustomChartWindow (){}

  static void _exportLogWindow (){}

  static void _calfileRunnerWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.LOG, WindowSetupInfo("Calculation", const Size(1000,700), _getCenterOffset(const Size(1000,700))));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setLogWindowTypePayload(LogWindowType.CALCULATION)));
  }

  static void _traceEditorWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.SETTINGS, WindowSetupInfo("Trace Editor", const Size(1000,700), _getCenterOffset(const Size(1000,700))));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsWindowTypePayload(SettingsWindowType.TRACE_EDITOR)));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsTraceEditorSetupPayload(TraceSettingsProvider.toJsonFormattable)));
  }

  static void _chartGridSetup (){
    if(mainWindowNavigatorKey.currentContext == null){
      localLogger.error("Could not show ChartGridSetupDialog because mainWindowNavigatorKey.currentContext was somehow null", doNoti: false);
      return;
    }
    showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
      return const DialogBase(
        title: "Chart grid setup",
        dialog: ChartGridSetupDialog(),
        minWidth: 600,
        maxHeight: 600,
      );
    });
  }

  static void _characteristicsSetup (){
    if(mainWindowNavigatorKey.currentContext == null){
      localLogger.error("Could not show ChartGridSetupDialog because mainWindowNavigatorKey.currentContext was somehow null", doNoti: false);
      return;
    }
    showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
      return const DialogBase(
        title: "Characteristics setup",
        dialog: CharacteristicsSetupDialog(),
        minWidth: 600,
        maxHeight: 600,
      );
    });
  }

  static void _statisticsViewWindow() async{
    int port = await ChildProcessController.addConnection(WindowType.CUSTOM_CHART, WindowSetupInfo("Statistics View", const Size(1000,700), _getCenterOffset(const Size(1000,700))));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setCustomChartWindowTypePayload(CustomChartWindowType.STATISTICS)));
  }

  static void _calfileCreatorWindow (){/* builtin kontextuális warningok pl ha ifexistben van channel majd később másik blockban újra van használva a channel meg ilyenek*/}

  static void _settingsWindow () async {
    int port = await ChildProcessController.addConnection(WindowType.SETTINGS, WindowSetupInfo("Settings", const Size(500,700), _getCenterOffset(const Size(500,700))));
    ChildProcessController.sendTo(Command(port, CommandType.DATA, setSettingsWindowTypePayload(SettingsWindowType.SETTINGS)));
  }

  static void _editParametersDialog (){
    if(mainWindowNavigatorKey.currentContext == null){
      localLogger.error("Could not show EditParametersDialog because mainWindowNavigatorKey.currentContext was somehow null", doNoti: false);
      return;
    }
    showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
      return const DialogBase(
        title: "Edit parameters",
        dialog: EditParametersDialog(),
        minWidth: 600,
      );
    });
  }

  // ignore: non_constant_identifier_names
  static void _DBCMenuDialog (){
    if(mainWindowNavigatorKey.currentContext == null){
      localLogger.error("Could not show DBCSelectorDialog because mainWindowNavigatorKey.currentContext was somehow null", doNoti: false);
      return;
    }
    showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
      return const DialogBase(
        title: "DBC Selection",
        dialog: DBCSelectorDialog(),
        minWidth: 700,
      );
    });
  }

  static void _logWindow (){}

  static void _lapDataDialog (){
    ChildProcessController.addConnection(WindowType.LAP_EDITOR, WindowSetupInfo("Lap Editor", const Size(700,600), _getCenterOffset(const Size(700,600))));
  }

  static const List<Widget> _mainWindowToolbarItems = [
    ToolbarItemWithDropdown(iconData: FontAwesomeIcons.fileImport, dropdownItems: [
      ToolbarDropdownItem(onPressed: _importLogWindow, text: "Import Log"),
      ToolbarDropdownItem(onPressed: _importCustomChartWindow, text: "Import Custom Chart"),
    ], iconHeight: toolbarItemSize, invertColors: false,),
    ToolbarItem(iconData: FontAwesomeIcons.fileExport,  onPressed: _exportLogWindow,),
    ToolbarItem(iconData: Icons.calculate, onPressed: _calfileRunnerWindow),
    ToolbarItem(iconData: FontAwesomeIcons.chartLine, onPressed: _traceEditorWindow),
    ToolbarItemWithDropdown(iconData: Icons.grid_view_sharp, dropdownItems: [
      ToolbarDropdownItem(onPressed: _chartGridSetup, text: "Chart grid"),
      ToolbarDropdownItem(onPressed: _characteristicsSetup, text: "Characteristics"),
      ToolbarDropdownItem(onPressed: _statisticsViewWindow, text: "Statistics View"),
    ], iconHeight: toolbarItemSize, invertColors: false,),
    ToolbarItem(iconData: Icons.create, onPressed: _calfileCreatorWindow),
    ToolbarItemWithDropdown(iconData: Icons.settings, dropdownItems: [
      ToolbarDropdownItem(onPressed: _settingsWindow, text: "General Settings"),
      ToolbarDropdownItem(onPressed: _editParametersDialog, text: "Edit Parameters"),
      ToolbarDropdownItem(onPressed: _DBCMenuDialog, text: "DBC Selection"),
    ], iconHeight: toolbarItemSize, invertColors: false,),
    ToolbarItem(iconData: Icons.receipt, onPressed: _logWindow),
    ToolbarItem(iconData: Icons.flag, onPressed: _lapDataDialog),
  ];

  static const List<ToolbarDropdownItem> _mainWindowToolbarItemsHidden = [
    ToolbarDropdownItem(onPressed: _importLogWindow, text: "Import Log"),
    ToolbarDropdownItem(onPressed: _importCustomChartWindow, text: "Import Custom Chart"),
    ToolbarDropdownItem(onPressed: _exportLogWindow, text: "Export Log"),
    ToolbarDropdownItem(onPressed: _calfileRunnerWindow, text: "Run Calfile"),
    ToolbarDropdownItem(onPressed: _traceEditorWindow, text: "Open Trace Editor"),
    ToolbarDropdownItem(onPressed: _chartGridSetup, text: "Chart grid"),
    ToolbarDropdownItem(onPressed: _characteristicsSetup, text: "Characteristics"),
    ToolbarDropdownItem(onPressed: _statisticsViewWindow, text: "Statistics View"),
    ToolbarDropdownItem(onPressed: _calfileCreatorWindow, text: "Create/Test Calfile"),
    ToolbarDropdownItem(onPressed: _settingsWindow, text: "General Settings"),
    ToolbarDropdownItem(onPressed: _editParametersDialog, text: "Edit Parameters"),
    ToolbarDropdownItem(onPressed: _DBCMenuDialog, text: "DBC Selection"),
    ToolbarDropdownItem(onPressed: _logWindow, text: "Log"),
    ToolbarDropdownItem(onPressed: _lapDataDialog, text: "Laps"),
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
              ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: _mainWindowToolbarItemsHidden.skip(_mainWindowToolbarItemsHiddenSkip(i)).toList(), iconHeight: toolbarItemSize, invertColors: false,)
              ]
          ),
        );
      }
    );
  }
}