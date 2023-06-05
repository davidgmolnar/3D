import 'package:flutter/material.dart';
import 'package:log_analyser/ui/theme.dart';

const double toolbarItemSize = 50;

class ToolbarItemWithDropdown extends StatefulWidget {
  const ToolbarItemWithDropdown({super.key, required this.iconData, required this.dropdownItems});

  final IconData iconData;
  final List<ToolbarDropdownItem> dropdownItems;

  @override
  State<ToolbarItemWithDropdown> createState() => ToolbarItemWithDropdownState();
}

class ToolbarItemWithDropdownState extends State<ToolbarItemWithDropdown> {
  final GlobalKey itemKey = GlobalKey();
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        isHover = true;
        setState(() {});
      },
      onExit: (event) {
        isHover = false;
        setState(() {});
      },
      child: GestureDetector(
        onTap: () async {
          if(widget.dropdownItems.isEmpty){
            return;
          }
          final render = itemKey.currentContext!.findRenderObject() as RenderBox;
          final String? result = await showMenu(
            color: StyleManager.globalStyle.secondaryColor,
            constraints: BoxConstraints(
              maxWidth: widget.dropdownItems.fold(0, (previousValue, element) => previousValue += element.text.length) * StyleManager.globalStyle.fontSize,
            ),
            context: context,
            position: RelativeRect.fromLTRB(
              render.localToGlobal(Offset.zero).dx,
              render.localToGlobal(Offset.zero).dy + toolbarItemSize,
              double.infinity,
              double.infinity
            ),
    
            items: widget.dropdownItems.map((e) =>
              PopupMenuItem(
                value: e.text,
                height: StyleManager.globalStyle.fontSize,
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1),)),
                  child: Text(e.text, style: StyleManager.textStyle,)),
              )
            ).toList()
          );
          if(result != null){
            widget.dropdownItems.firstWhere((element) => element.text == result).onPressed();
          }
        },
        child: Container(
          key: itemKey,
          width: toolbarItemSize,
          height: toolbarItemSize,
          color: isHover ? StyleManager.globalStyle.secondaryColor : StyleManager.globalStyle.bgColor,
          child: Icon(widget.iconData, size: toolbarItemSize - 2 * StyleManager.globalStyle.padding,),
        ),
      ),
    );
  }
}

class ToolbarItem extends StatefulWidget {
  const ToolbarItem({super.key, required this.iconData, required this.onPressed});

  final IconData iconData;
  final Function onPressed;

  @override
  State<ToolbarItem> createState() => ToolbarItemState();
}

class ToolbarItemState extends State<ToolbarItem> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        isHover = true;
        setState(() {});
      },
      onExit: (event) {
        isHover = false;
        setState(() {});
      },
      child: GestureDetector(
        onTap: () => widget.onPressed(),
        child: Container(
          width: toolbarItemSize,
          height: toolbarItemSize,
          color: isHover ? StyleManager.globalStyle.secondaryColor : StyleManager.globalStyle.bgColor,
          child: Icon(widget.iconData, size: toolbarItemSize - 2 * StyleManager.globalStyle.padding,),
        ),
      ),
    );
  }
}

class ToolbarDropdownItem{
  const ToolbarDropdownItem({required this.onPressed, required this.text});

  final Function onPressed;
  final String text;
}