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
  final Map<int, double> topOffsets = {};
  final Map<int, double> leftOffsets = {};
  final Map<int, int> decayScheduler = {};

  @override
  void initState() {
    noti.NotificationController.register(onNotificationAdded);
    onNotificationAdded(noti.Notification.decaying(LogEntry.info("Lorem ipsum"), 2000));
    onNotificationAdded(noti.Notification.decaying(LogEntry.warning("Lorem ipsum"), 4000));
    onNotificationAdded(noti.Notification.decaying(LogEntry.error("Lorem ipsum"), 6000));
    super.initState();
  }

  void onNotificationAdded(final noti.Notification noti){
    int notiKey = notifications.isEmpty ? 0 : notifications.keys.last + 1;
    notifications[notiKey] = noti;
    if(topOffsets.isEmpty){
      topOffsets[notiKey] = 0;
    }
    else{
      topOffsets[notiKey] = topOffsets.values.last + _notificationHeight;
    }
    topOffsets[notiKey] = topOffsets[notiKey]! + StyleManager.globalStyle.padding;
    leftOffsets[notiKey] = 0;

    if(noti.isDecaying){
      int decayKey = decayScheduler.isEmpty ? 0 : decayScheduler.keys.last + 1;
      decayScheduler[decayKey] = notiKey;
      Future.delayed(Duration(milliseconds: noti.durationMs),
        (){
          if(decayScheduler.containsKey(decayKey)){
            leftOffsets[decayScheduler[decayKey]!] = _notificationWidth + 100;
            setState(() {});
          }
        }
      );
    }

    setState(() {});
  }

  void removeAt(final int removeKey){
    final noti.Notification? removed = notifications.remove(removeKey);
    if(removed == null){
      return;
    }
    final double remTopOffset = topOffsets.remove(removeKey)!;
    leftOffsets.remove(removeKey);

    int? maybeIsScheduled;
    for(final int decayKey in decayScheduler.keys){
      if(decayScheduler[decayKey]! == removeKey){
        maybeIsScheduled = decayKey;
      }
    }

    if(maybeIsScheduled != null){
      decayScheduler.remove(maybeIsScheduled);
    }

    for(final int notiKey in notifications.keys){
      if(topOffsets[notiKey]! > remTopOffset){
        topOffsets[notiKey] = topOffsets[notiKey]! - _notificationHeight - StyleManager.globalStyle.padding;
      }
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
              AnimatedPositioned(
                top: topOffsets[notiKey],
                left: leftOffsets[notiKey],
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                onEnd: () {
                  if(leftOffsets[notiKey] != 0){
                    leftOffsets[notiKey] = 0;
                    removeAt(notiKey);
                    setState(() {});
                  }
                },
                child: NotificationContainer(
                  notification: notifications[notiKey]!,
                  onRemoved: (){
                    leftOffsets[notiKey] = _notificationWidth + 100;
                    setState(() {});
                  }
                ),
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
  const NotificationContainer({super.key, required this.notification, required this.onRemoved});

  final noti.Notification notification;
  final VoidCallback onRemoved;

  @override
  State<NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                  widget.onRemoved();
                },
                icon: Icon(Icons.close, color: StyleManager.globalStyle.primaryColor,)
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.all(StyleManager.globalStyle.padding),
            child: Text(widget.notification.entry.message,
              maxLines: 5,
              overflow: TextOverflow.clip,
            )
          )
        ],
      ),
    );
  }
}