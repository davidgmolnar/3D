import 'package:flutter/material.dart';
import 'package:log_analyser/routes/settings/settings_widgets/settings_bottom_bar.dart';

import '../../../data/settings.dart';

class SettingsTraceEditor extends StatefulWidget{
  const SettingsTraceEditor({super.key});

  @override
  State<SettingsTraceEditor> createState() => _SettingsTraceEditorState();
}

class _SettingsTraceEditorState extends State<SettingsTraceEditor> {

  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(update);
    super.initState();
  }

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          itemCount: TraceSettingsProvider.itemCount,
          itemExtent: 75,
          itemBuilder: ((context, index) {
            // TODO from flattened TraceSettingsProvider
            return Container();
          })
        ),
        const SettingsBottomBar()
      ],
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(update);
    super.dispose();
  }
}