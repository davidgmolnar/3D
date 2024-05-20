import 'package:flutter/material.dart';

import '../../../data/settings.dart';
import '../../../data/settings_classes.dart';
import '../../../ui/theme/theme.dart';
import '../../../ui/toolbar/toolbar_item.dart';

class CustomChartToolbar extends StatefulWidget {
  const CustomChartToolbar({super.key});

  @override
  State<CustomChartToolbar> createState() => _CustomChartToolbarState();
}

class _CustomChartToolbarState extends State<CustomChartToolbar> {
  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: toolbarItemSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if(TraceSettingsProvider.traceSettingNotifier.value.values.isNotEmpty)
            for(TraceSetting trace in TraceSettingsProvider.traceSettingNotifier.value.values.first)
              TextButton(
                onPressed: (){
                  TraceSettingsProvider.traceSettingNotifier.update((value) {
                    final int i = value.values.first.indexWhere((element) => element.signal == trace.signal);
                    value.values.first[i].isVisible = !value.values.first[i].isVisible;
                  });
                },
                child: Text(trace.signal, style: StyleManager.subTitleStyle.copyWith(color: trace.color),)
              ),
        ],
      )
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}