import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../ui/toolbar_item.dart';

class MainWindowToolbar extends StatelessWidget {
  const MainWindowToolbar({super.key});

  static _importCSV (){}
  static _importBIN (){}
  static _importTXT (){}

  static _exportCSV (){}
  static _exportBIN (){}
  static _exportTXT (){}

  static _openCalfileWindow (){}
  static _openTraceEditorWindow (){}

  static List<Widget> mainWindowToolbarItems = const [
    ToolbarItemWithDropdown(iconData: FontAwesomeIcons.fileImport, dropdownItems: [
      ToolbarDropdownItem(onPressed: _importCSV, text: "Import .csv"),
      ToolbarDropdownItem(onPressed: _importBIN, text: "Import .bin"),
      ToolbarDropdownItem(onPressed: _importTXT, text: "Import .txt"),
    ],),
    ToolbarItemWithDropdown(iconData: FontAwesomeIcons.fileExport,  dropdownItems: [
      ToolbarDropdownItem(onPressed: _exportCSV, text: "Export .csv"),
      ToolbarDropdownItem(onPressed: _exportBIN, text: "Export .bin"),
      ToolbarDropdownItem(onPressed: _exportTXT, text: "Export .txt"),
    ],),
    ToolbarItem(iconData: Icons.calculate, onPressed: _openCalfileWindow),
    ToolbarItem(iconData: FontAwesomeIcons.chartLine, onPressed: _openTraceEditorWindow),
    ToolbarItemWithDropdown(iconData: Icons.grid_view_sharp, dropdownItems: [],),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: mainWindowToolbarItems.length * 50 < constraints.maxWidth ?
            mainWindowToolbarItems
            :
            [
            for(int i = 0; i < (constraints.maxWidth - 50) ~/ 50; i++)
              mainWindowToolbarItems[i],
            const ToolbarItemWithDropdown(iconData: Icons.more_horiz, dropdownItems: [],)
            ]
        );
      }
    );
  }
}