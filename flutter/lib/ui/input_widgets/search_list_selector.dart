import 'dart:math';

import 'package:flutter/material.dart';
import 'package:log_analyser/extensions.dart';

import '../../data/settings_classes.dart';
import '../dialogs/dialog_base.dart';
import '../theme/theme.dart';

class SearchListSelector extends StatelessWidget {
  const SearchListSelector({
    super.key,
    required this.selection,
    required this.hintText,
    required this.options,
    required this.onSelected,
  });

  final List<String> selection;
  final String hintText;
  final List<String> options;
  final Function(List<String>) onSelected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){
        showDialog<Widget>(
          context: context,
          builder: (BuildContext context){
            return DialogBase(
              title: hintText,
              minWidth: 500,
              maxHeight: 500,
              dialog: SearchListSelectorDialog(selection: selection, hintText: hintText, options: options, onSelected: onSelected,),
            );
          }
        );
      },
      child: Text(selection.isEmpty ? hintText : "${selection.length} items", style: StyleManager.textStyle,),
    );
  }
}

class SearchListSelectorDialog extends StatefulWidget {
  const SearchListSelectorDialog({
    super.key,
    required this.selection,
    required this.hintText,
    required this.options,
    required this.onSelected,
  });

  final List<String> selection;
  final String hintText;
  final List<String> options;
  final Function(List<String>) onSelected;

  @override
  State<SearchListSelectorDialog> createState() => _SearchListSelectorDialogState();
}

class _SearchListSelectorDialogState extends State<SearchListSelectorDialog> {
  TextEditingController controller = TextEditingController();
  SortLogic logic = SortLogic.STARTSWITH;
  List<String> selection = [];

  @override
  void initState() {
    selection.addAll(widget.selection);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> validSelection;
    if(logic == SortLogic.STARTSWITH){
      validSelection = widget.options.sorted((a, b) => a.compareTo(b))
        .where((key) => key.startsWith(controller.text)).toList()..removeWhere((element) => selection.contains(element));
    }
    else{
      validSelection = widget.options.sorted((a, b) => a.compareTo(b))
        .where((key) => key.contains(controller.text)).toList()..removeWhere((element) => selection.contains(element));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                    width: constraints.maxWidth - 2 * StyleManager.globalStyle.padding - 100,
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: widget.hintText
                      ),
                      onChanged:(value) {
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () {
                        if(logic == SortLogic.STARTSWITH){
                          logic = SortLogic.CONTAINS;
                        }
                        else{
                          logic = SortLogic.STARTSWITH;
                        }
                        setState(() {});
                      },
                      child: Text(logic == SortLogic.STARTSWITH ? "Starts with" : "Contains", style: StyleManager.textStyle,),
                    )
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              width: constraints.maxWidth - 2 * StyleManager.globalStyle.padding,
              height: min(500, MediaQuery.of(context).size.height) - 220 - 4 * StyleManager.globalStyle.padding,
              child: ListView.builder(
                itemCount: validSelection.length,
                itemExtent: 30,
                cacheExtent: 400,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      selection.add(validSelection[index]);
                      controller.text = "";
                      setState(() {});
                    },
                    leading: Text(validSelection[index], style: StyleManager.textStyle,),
                  );
                },
              ),
            ),
            Container(
              height: 98,
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))
              ),
              child: ListView.builder(
                itemCount: selection.length,
                itemExtent: 30,
                cacheExtent: 300,
                itemBuilder:(context, index) {
                  return ListTile(
                    onTap: () {
                      selection.removeAt(index);
                      setState(() {});
                    },
                    leading: Text(selection[index], style: StyleManager.textStyle,),
                  );
                },
              ),
            ),
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_left, color: StyleManager.globalStyle.primaryColor),
                    onPressed: (){
                        Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: StyleManager.globalStyle.primaryColor),
                    onPressed: () {
                      widget.onSelected(selection);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            )
          ],
        );
      }
    );
  }
}