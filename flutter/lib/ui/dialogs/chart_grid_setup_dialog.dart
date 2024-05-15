import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../io/file_system.dart';
import '../../io/importer.dart';
import '../../routes/custom_chart/custom_chart_logic/custom_group.dart';
import '../common.dart';
import '../input_widgets/sliders.dart';
import '../theme/theme.dart';

class ChartGridSetupDialog extends StatefulWidget {
  const ChartGridSetupDialog({super.key});

  @override
  State<ChartGridSetupDialog> createState() => _ChartGridSetupState();
}

class _ChartGridSetupState extends State<ChartGridSetupDialog> {
  bool createNew = true;
  List<FileSystemEntity> chartGridFiles = [];

  @override
  void initState() {
    chartGridFiles = FileSystem.tryListElementsInLocalSync(FileSystem.customTimeSeriesGroupDir);
    createNew = chartGridFiles.isEmpty;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SlidingSwitch(
              labels: const ["New", "Load"],
              active: createNew ? "New" : "Load",
              elementWidth: constraints.maxWidth / 2,
              onChanged: (p0) {
                createNew = p0 == "New" ? true : false;
                setState(() {});
              },
            ),
            createNew ?
              const ChartGridCreate()
              :
              ChartGridLoad(chartGridFiles: chartGridFiles)
          ],
        );
      },
    );
  }
}

class ChartGridCreate extends StatefulWidget {
  const ChartGridCreate({super.key});

  @override
  State<ChartGridCreate> createState() => _ChartGridCreateState();
}

class _ChartGridCreateState extends State<ChartGridCreate> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _numRow = TextEditingController();
  final TextEditingController _numCol = TextEditingController();

  final List<String?> _meas = [];
  final List<List<String?>> _signals = [];

  bool canFillElements = false;

  void _checkRowCol(){
    int? maybeRow = int.tryParse(_numRow.text);
    int? maybeCol = int.tryParse(_numCol.text);
    int prevLen = _meas.length;
    canFillElements = maybeRow != null && maybeCol != null && maybeRow <= 4 && maybeCol <= 4;
    _meas.clear();
    _signals.clear();
    if(canFillElements){
      int elemNum = maybeRow! * maybeCol!;
      for(int i = 0; i < elemNum; i++){
        _meas.add(null);
        _signals.add([null]);
      }
    }

    if(_meas.length != prevLen){
      setState(() {});
    }
  }

  CustomTimeseriesChartGroup? _save({bool isStarting = false}){
    if(_name.text.isEmpty){
      showErrorWithoutContext("Please specify a name");
      return null;
    }
    if(!canFillElements){
      showErrorWithoutContext("Please specify row and col numbers");
      return null;
    }
    List<FileSystemEntity> groups = FileSystem.tryListElementsInLocalSync(FileSystem.customTimeSeriesGroupDir);
    int nextSharingGroup = groups.length;
    CustomTimeseriesChartGroup group = CustomTimeseriesChartGroup(sharingGroup: nextSharingGroup, name: _name.text, numRow: int.parse(_numRow.text), numCol: int.parse(_numCol.text));

    bool fail = false;
    for(int i = 0; i < _meas.length; i++){
      if(_meas[i] == null || _signals[i].any((element) => element == null)){
        showErrorWithoutContext("Element at index $i was not filled out");
      }
      else if(!group.add(m: _meas[i]!, s: _signals[i].whereType<String>().toList())){
        showErrorWithoutContext("Could not add ${_meas[i]}/${_signals[i]} as it was already added");
        fail = true;
      }
    }

    if(fail){
      return null;
    }
    if(groups.any((element) => element.uri.path.split('/').last.split('.').first == _name.text)){
      showErrorWithoutContext("A group with name ${_name.text} already exists");
      return null;
    }
    group.save();
    if(!isStarting){
      showInfoWithoutContext("Group successfully saved");
    }
    return group;
  }

  void _start(){
    CustomTimeseriesChartGroup? group = _save(isStarting: true);
    if(group == null){
      return;
    }

    group.saveChannels();
    // for each element
    //    ChildProcessController.addConnection
    //    send windowsetupinfo
    //    send descriptor

  }

  void _clear(){
    _name.clear();
    _numRow.clear();
    _numCol.clear();
    _checkRowCol();
  }

  void _cancel(BuildContext context){
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: StyleManager.globalStyle.primaryColor, width: 1))),
          child: Row(
            children: [
              const Spacer(),
              Container(
                height: 50,
                width: 400,
                padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: "Name of group"),
                ),
              ),
              const Spacer(flex: 3,),
              Container(
                height: 50,
                width: 50,
                padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                child: TextFormField(
                  controller: _numRow,
                  decoration: const InputDecoration(hintText: "Row"),
                  onChanged: (value) {
                    int? maybeInt = int.tryParse(value);
                    if(value.isNotEmpty && (maybeInt == null || maybeInt > 4)){
                      showError(context, "Invalid row count. Row count must be an integer in range (0: 4]");
                    }
                    _checkRowCol();
                  },
                ),
              ),
              const Text("X"),
              Container(
                height: 50,
                width: 50,
                padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                child: TextFormField(
                  controller: _numCol,
                  decoration: const InputDecoration(hintText: "Col"),
                  onChanged: (value) {
                    int? maybeInt = int.tryParse(value);
                    if(value.isNotEmpty && (maybeInt == null || maybeInt > 4)){
                      showError(context, "Invalid col count. Row count must be an integer in range (0: 4]");
                    }
                    _checkRowCol();
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        canFillElements ? 
          SizedBox(
            height: min(600, MediaQuery.of(context).size.height) - 151 - 4 * StyleManager.globalStyle.padding,
            child: ListView.builder(
              cacheExtent: 1000,
              itemCount: _meas.length,
              itemBuilder: (context, index) {
                int rowNum = index ~/ int.parse(_numRow.text);
                int colNum = index % int.parse(_numRow.text);
                return Padding(
                  padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                  child: SizedBox(
                    height: 50.0 * _signals[index].length + 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: StyleManager.globalStyle.padding + 4),
                          child: Text("$rowNum:$colNum", style: StyleManager.subTitleStyle,),
                        ),
                        SizedBox(
                          width: 100,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _meas[index],
                            items: [const DropdownMenuItem<String>(value: null, child: Text("Select")), ...signalData.keys.map((meas) => DropdownMenuItem<String>(value: meas, child: Text(meas)))],
                            onChanged: (value) {
                              _meas[index] = value;
                              setState(() {});
                            },
                          ),
                        ),
                        Column(
                          children: [
                            for(int i = 0; i < _signals[index].length; i++)
                              SizedBox(
                                width: 300,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _signals[index][i],
                                  items: [const DropdownMenuItem<String>(value: null, child: Text("Select")), ...?signalData[_meas[index]]?.keys.map((signal) => DropdownMenuItem<String>(value: signal, child: Text(signal)))],
                                  onChanged: (value) {
                                    _signals[index][i] = value;
                                    setState(() {});
                                  },
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _signals[index].add(null);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.add, color: StyleManager.globalStyle.primaryColor,)
                                ),
                                IconButton(
                                  onPressed: () {
                                    if(_signals[index].length == 1){
                                      return;
                                    }
                                    _signals[index].removeLast();
                                    setState(() {});
                                  }, 
                                  icon: Icon(Icons.remove, color: StyleManager.globalStyle.primaryColor,)
                                ),
                              ],
                            )
                          ]
                        ),
                      ],
                    )
                  )
                );
              }
            ),
          )
          :
          SizedBox(
            height: min(600, MediaQuery.of(context).size.height) - 151 - 4 * StyleManager.globalStyle.padding,
            child: const Center(
              child: Text("Define Row x Col"),
            )
          ),
        Container(
          padding: EdgeInsets.only(bottom: StyleManager.globalStyle.padding),
          height: 50,
          color: StyleManager.globalStyle.secondaryColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _save,
                child: Text("Save", style: StyleManager.subTitleStyle.copyWith(color: StyleManager.globalStyle.primaryColor)),
              ),
              TextButton(
                onPressed: _start,
                child: Text("Start", style: StyleManager.subTitleStyle.copyWith(color: StyleManager.globalStyle.primaryColor)),
              ),
              TextButton(
                onPressed: _clear,
                child: Text("Clear", style: StyleManager.subTitleStyle.copyWith(color: StyleManager.globalStyle.primaryColor)),
              ),
              TextButton(
                onPressed: () => _cancel(context),
                child: Text("Cancel", style: StyleManager.subTitleStyle.copyWith(color: StyleManager.globalStyle.primaryColor)),
              )
            ]
          ),
        )
      ],
    );
  }
}

class ChartGridLoad extends StatelessWidget {
  const ChartGridLoad({super.key, required this.chartGridFiles});

  final List<FileSystemEntity> chartGridFiles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: min(600, MediaQuery.of(context).size.height) - 151 - 4 * StyleManager.globalStyle.padding,
      child: ListView.builder(
        cacheExtent: 1000,
        itemCount: chartGridFiles.length,
        itemBuilder: (context, index) {
          return ChartGridElementCard(file: chartGridFiles[index]);
        }
      ),
    );
  }
}

class ChartGridElementCard extends StatefulWidget {
  const ChartGridElementCard({super.key, required this.file});

  final FileSystemEntity file;

  @override
  State<ChartGridElementCard> createState() => _ChartGridElementCardState();
}

class _ChartGridElementCardState extends State<ChartGridElementCard> {
  late final CustomTimeseriesChartGroup? group;
  bool opened = false;

  @override
  void initState() {
    Map json = Importer.jsonFromBytes(
      File(widget.file.path).readAsBytesSync()
    );
    group = CustomTimeseriesChartGroup.fromJson(json, widget.file.uri.path.split('/').last.split('.').first);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(group == null){
      return Center(
        child: Text("Error when parsing ${widget.file.path}", style: StyleManager.textStyle,),
      );
    }

    if(opened){
      // Name
      // row x col
      // shevron down to open in detail
      // delete button
      // return
    }

    // Name
    // row x col
    // shevron up to close detail
    // delete button
    // every group diplayed

  }
}