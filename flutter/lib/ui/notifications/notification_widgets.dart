import 'dart:math';

import 'package:flutter/material.dart';

import '../../io/logger.dart';
import '../theme/theme.dart';
import 'notification_logic.dart' as noti;

const double _notificationHeight = 150;
const double _notificationWidth = 400;

final Map<LogLevel, Color> _levelColors = {
  LogLevel.INFO: Colors.green.shade800,
  LogLevel.WARNING: Colors.yellow.shade900,
  LogLevel.ERROR: Colors.red,
  LogLevel.CRITICAL: Colors.red,
};

class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({super.key});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  final Map<int, noti.Notification> notifications = {};
  final Map<int, noti.PositionController> controllers = {};

  @override
  void initState() {
    noti.NotificationController.register(onNotificationAdded);
    super.initState();
  }

  void onNotificationAdded(final noti.Notification noti){
    int notiKey = notifications.isEmpty ? 0 : notifications.keys.last + 1;
    notifications[notiKey] = noti;
    
    if(noti.isDecaying){
      Future.delayed(Duration(milliseconds: noti.durationMs),
        (){
          if(controllers.containsKey(notiKey)){
            controllers[notiKey]!.setLeft(_notificationWidth + 100);
            setState(() {});
          }
        }
      );
    }

    setState(() {});
  }

  void removeAt(final int removeKey){
    if(!controllers.containsKey(removeKey)){
      return;
    }
    final double remTopOffset = controllers[removeKey]!.getTop();

    for(final int notiKey in notifications.keys){
      if(controllers[notiKey]!.getTop() > remTopOffset){
        final double newTop = controllers[notiKey]!.getTop() - _notificationHeight - StyleManager.globalStyle.padding;
        controllers[notiKey]!.setTop(newTop);
      }
    }

    if(controllers.values.every((controller) => controller.getLeft() != 0)){
      notifications.clear();
      controllers.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: min(MediaQuery.of(context).size.height, notifications.length * _notificationHeight),
        width: _notificationWidth,
        child: Stack(
          children: [
            for(final int notiKey in notifications.keys)
              NotificationContainer(
                notification: notifications[notiKey]!,
                onInitialized: (controller){
                  controllers[notiKey] = controller;
                  controller.setTop((_notificationHeight + StyleManager.globalStyle.padding) * notifications.keys.toList().indexOf(notiKey));
                  },
                onRemoved: (){
                  removeAt(notiKey);
                  setState(() {});
                }
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    noti.NotificationController.deRegister();
    super.dispose();
  }
}

class NotificationContainer extends StatefulWidget {
  const NotificationContainer({super.key, required this.notification, required this.onRemoved, required this.onInitialized});

  final noti.Notification notification;
  final VoidCallback onRemoved;
  final Function(noti.PositionController) onInitialized;

  @override
  State<NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer> {
  double _top = 0;
  double _left = 0;

  @override
  void initState() {
    widget.onInitialized(noti.PositionController(getTop: getTop, getLeft: getLeft, setTop: setTop, setLeft: setLeft));
    super.initState();
  }

  double getTop(){
    return _top;
  }

  double getLeft(){
    return _left;
  }

  void setTop(final double top){
    _top = top;
    setState(() {});
  }

  void setLeft(final double left){
    _left = left;
    setState(() {});
  }
  

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          top: _top,
          left: _left,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          onEnd: () {
            if(_left != 0){
              widget.onRemoved();
              setState(() {});
            }
          },
          child: Container(
            height: _notificationHeight,
            width: _notificationWidth,
            color: _levelColors[widget.notification.entry.level]!,
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: StyleManager.globalStyle.padding),
                      child: Text(widget.notification.entry.level.name, style: StyleManager.subTitleStyle,),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: (){
                        _left = _notificationWidth + 100;
                        setState(() {});
                      },
                      icon: Icon(Icons.close, color: StyleManager.globalStyle.primaryColor,)
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                  child: Text(widget.notification.entry.message,
                    maxLines: 4,
                    overflow: TextOverflow.clip,
                  )
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}