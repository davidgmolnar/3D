import 'package:flutter/material.dart';

import '../../../data/settings.dart';
import '../custom_chart_logic/statistics_view_controller.dart';

class StatisticsViewContainer extends StatelessWidget {
  const StatisticsViewContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 50,
          child: StatisticsViewToolbar()
        ),
        Expanded(
          child: StatisticsViewDataContainer()
        ),
        SizedBox(
          height: 500,
          child: StatisticsViewPlotContainer()
        ),
      ],
    );
  }
}

class StatisticsViewToolbar extends StatefulWidget {
  const StatisticsViewToolbar({super.key});

  @override
  State<StatisticsViewToolbar> createState() => _StatisticsViewToolbarState();
}

class _StatisticsViewToolbarState extends State<StatisticsViewToolbar> {
  @override
  void initState() {
    TraceSettingsProvider.traceSettingNotifier.addListener(_onTraceSettingUpdate);
    super.initState();
  }

  void _onTraceSettingUpdate(){

  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [],
    );
  }

  @override
  void dispose() {
    TraceSettingsProvider.traceSettingNotifier.removeListener(_onTraceSettingUpdate);
    super.dispose();
  }
}

class StatisticsViewDataContainer extends StatefulWidget {
  const StatisticsViewDataContainer({super.key});

  @override
  State<StatisticsViewDataContainer> createState() => _StatisticsViewDataContainerState();
}

class _StatisticsViewDataContainerState extends State<StatisticsViewDataContainer> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate);
    super.initState();
  }
  
  void _onControllerUpdate(){

  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

class StatisticsViewPlotContainer extends StatefulWidget {
  const StatisticsViewPlotContainer({super.key});

  @override
  State<StatisticsViewPlotContainer> createState() => _StatisticsViewPlotContainerState();
}

class _StatisticsViewPlotContainerState extends State<StatisticsViewPlotContainer> {
  @override
  void initState() {
    StatisticsViewController.notifier.addListener(_onControllerUpdate);
    super.initState();
  }

  void _onControllerUpdate(){

  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    StatisticsViewController.notifier.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

