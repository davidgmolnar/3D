import 'package:flutter/material.dart';

class _HideableListviewStatus{
  bool isOpened;
  bool goingToOpen;
  bool isHover = false;
  
  _HideableListviewStatus({
    required this.isOpened,
    required this.goingToOpen
  });
}

class HideableListviewStyle{
  final Color defaultTitleBoxColor;
  final Color hoverTitleBoxColor;
  final Color borderColor;
  final double borderWidth;
  final double titleBarHeight;
  final TextStyle titleBarStyle;
  final double elementHeight;
  final double padding;

  const HideableListviewStyle({
    required this.defaultTitleBoxColor,
    required this.hoverTitleBoxColor,
    required this.titleBarHeight,
    required this.titleBarStyle,
    required this.elementHeight,
    required this.padding,
    required this.borderColor,
    required this.borderWidth,
  });
}

class HideableListview<T> extends StatefulWidget {
  const HideableListview({
    super.key,
    required this.listElements,
    required this.title,
    required this.elementView,
    required this.initiallyOpened,
    required this.style,    
  });

  final List<T> listElements;
  final Widget Function(T) elementView;
  final String title;
  final bool initiallyOpened;
  final HideableListviewStyle style;

  @override
  State<HideableListview<T>> createState() => _HideableListviewState<T>();
}

class _HideableListviewState<T> extends State<HideableListview<T>> {
  late final _HideableListviewStatus status;

  @override
  void initState() {
    status = _HideableListviewStatus(isOpened: widget.initiallyOpened, goingToOpen: widget.initiallyOpened);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                status.goingToOpen ? {status.goingToOpen = false, status.isOpened = false} : status.goingToOpen = true;
                setState(() {});
              },
              child: MouseRegion(
                onEnter: (event) {
                  status.isHover = true;
                  setState(() {});
                },
                onExit: (event) {
                  status.isHover = false;
                  setState(() {});
                },
                child: Container(
                  height: widget.style.titleBarHeight,
                  width: constraints.minWidth,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(width: widget.style.borderWidth, color: widget.style.borderColor)),
                    color: status.isHover ? widget.style.hoverTitleBoxColor : widget.style.defaultTitleBoxColor
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(widget.style.padding),
                        child: Text(widget.title, style: widget.style.titleBarStyle,),
                      ),
                      Padding(
                        padding: EdgeInsets.all(widget.style.padding),
                        child: Icon(
                          status.goingToOpen ? Icons.keyboard_arrow_up_outlined : Icons.keyboard_arrow_down_outlined,
                          size: widget.style.titleBarHeight / 2,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutQuint,
              onEnd: () {
                status.isOpened = status.goingToOpen;
                setState(() {});
              },
              height: status.goingToOpen ? widget.listElements.length * widget.style.elementHeight : 0,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(width: widget.style.borderWidth, color: widget.style.borderColor))
              ),
              child: status.isOpened ?
                Column(
                  children: [
                    for(T element in widget.listElements)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.style.padding),
                        child: widget.elementView(element)
                      )
                  ],
                )
              :
              SizedBox(width: constraints.maxWidth,)
              ,
            )
          ],
        );
      },
    );
  }
}