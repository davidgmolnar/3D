import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/data.dart';
import '../../io/file_system.dart';
import '../../io/importer.dart';
import '../../routes/custom_chart/custom_chart_logic/custom_descriptor.dart';
import '../../routes/main_window/screen.dart';
import '../common.dart';
import '../input_widgets/sliders.dart';
import '../theme/theme.dart';
import 'dialog_base.dart';

class CharacteristicsSetupDialog extends StatefulWidget {
  const CharacteristicsSetupDialog({super.key});

  @override
  State<CharacteristicsSetupDialog> createState() => _CharacteristicsSetupState();
}

class _CharacteristicsSetupState extends State<CharacteristicsSetupDialog> {
  bool createNew = true;

  @override
  void initState() {
    createNew = FileSystem.tryListElementsInLocalSync(FileSystem.customCharacteristicsGroupDir).isEmpty;
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
              const CharacteristicsCreate()
              :
              const CharacteristicsLoad()
          ],
        );
      },
    );
  }
}

class CharacteristicsCreate extends StatefulWidget {
  const CharacteristicsCreate({super.key});

  @override
  State<CharacteristicsCreate> createState() => _CharacteristicsCreateState();
}

class _CharacteristicsCreateState extends State<CharacteristicsCreate> {
  final TextEditingController _name = TextEditingController();
  String? _meas;
  String? _baseSignal;

  final List<String?> _compSignals = [null];

  bool canFillElements = false;

  CustomCharacteristicsDescriptor? _save({bool isStarting = false}){
    if(_name.text.isEmpty){
      showErrorWithoutContext("Please specify a name");
      return null;
    }
    if(_meas == null){
      showErrorWithoutContext("Please specify a measurement");
      return null;
    }
    if(_baseSignal == null){
      showErrorWithoutContext("Please specify a base signal");
      return null;
    }
    if(_compSignals.isEmpty || _compSignals.any((element) => element == null)){
      showErrorWithoutContext("Please specify all comparison signals");
      return null;
    }

    CustomCharacteristicsDescriptor group = CustomCharacteristicsDescriptor(name: _name.text, measurement: _meas!, baseSignal: _baseSignal!, compSignals: _compSignals.cast<String>());
    
    if(FileSystem.tryListElementsInLocalSync(FileSystem.customCharacteristicsGroupDir).any((element) => element.uri.path.split('/').last.split('.').first == _name.text)){
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
    CustomCharacteristicsDescriptor? group = _save(isStarting: true);
    if(group == null){
      return;
    }

    group.launch();
  }

  void _clear(){
    _name.clear();
    _meas = null;
    _baseSignal = null;
    _compSignals.clear();
    _compSignals.add(null);
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
                width: 350,
                padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: "Name of group"),
                ),
              ),
              const Spacer(flex: 3,),
              SizedBox(
                width: 150,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _meas,
                  items: [const DropdownMenuItem<String>(value: null, child: Text("Select Meas")), ...signalData.keys.map((meas) => DropdownMenuItem<String>(value: meas, child: Text(meas)))],
                  onChanged: (value) {
                    _meas = value;
                    setState(() {});
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ), 
        SizedBox(
          height: min(600, MediaQuery.of(context).size.height) - 151 - 4 * StyleManager.globalStyle.padding,
          child: ListView(
            cacheExtent: 1000,
            children: [
              Padding(
                padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                child: SizedBox(
                  height: 50.0 * _compSignals.length + 50,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 250,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _baseSignal,
                          items: [const DropdownMenuItem<String>(value: null, child: Text("Select base")), ...?signalData[_meas]?.keys.map((signal) => DropdownMenuItem<String>(value: signal, child: Text(signal)))],
                          onChanged: (value) {
                            _baseSignal = value;
                            setState(() {});
                          },
                        ),
                      ),
                      Column(
                        children: [
                          for(int i = 0; i < _compSignals.length; i++)
                            SizedBox(
                              width: 250,
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _compSignals[i],
                                items: [const DropdownMenuItem<String>(value: null, child: Text("Select comp")), ...?signalData[_meas]?.keys.map((signal) => DropdownMenuItem<String>(value: signal, child: Text(signal)))],
                                onChanged: (value) {
                                  _compSignals[i] = value;
                                  setState(() {});
                                },
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  _compSignals.add(null);
                                  setState(() {});
                                },
                                icon: Icon(Icons.add, color: StyleManager.globalStyle.primaryColor,)
                              ),
                              IconButton(
                                onPressed: () {
                                  if(_compSignals.length == 1){
                                    return;
                                  }
                                 _compSignals.removeLast();
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
              )
            ]
          ),
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
                child: Text("Launch", style: StyleManager.subTitleStyle.copyWith(color: StyleManager.globalStyle.primaryColor)),
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

class CharacteristicsLoad extends StatefulWidget {
  const CharacteristicsLoad({super.key});

  @override
  State<CharacteristicsLoad> createState() => _CharacteristicsLoadState();
}

class _CharacteristicsLoadState extends State<CharacteristicsLoad> {
  List<FileSystemEntity> characteristicsFiles = [];

  @override
  void initState() {
    characteristicsFiles = FileSystem.tryListElementsInLocalSync(FileSystem.customCharacteristicsGroupDir);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: min(600, MediaQuery.of(context).size.height) - 100 - 4 * StyleManager.globalStyle.padding,
      child: ListView.builder(
        cacheExtent: 1000,
        itemCount: characteristicsFiles.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: StyleManager.globalStyle.secondaryColor))),
            child: CharacteristicsCard(
              file: characteristicsFiles[index],
              onDeleted: () {
                characteristicsFiles[index].deleteSync();
                characteristicsFiles.removeAt(index);
                setState(() {});
              },
            ),
          );
        }
      ),
    );
  }
}

class CharacteristicsCard extends StatefulWidget {
  const CharacteristicsCard({super.key, required this.file, required this.onDeleted});

  final FileSystemEntity file;
  final VoidCallback onDeleted;

  @override
  State<CharacteristicsCard> createState() => _CharacteristicsCardState();
}

class _CharacteristicsCardState extends State<CharacteristicsCard> {
  CustomCharacteristicsDescriptor? char;
  bool opened = false;

  @override
  void initState() {
    Map json = Importer.jsonFromBytes(
      File(widget.file.path).readAsBytesSync()
    );
    char = CustomCharacteristicsDescriptor.fromJson(json, widget.file.uri.path.split('/').last.split('.').first);
    super.initState();
  }

  void _onSelected(BuildContext context){
    if(char == null){
      return;
    }
    List<String> usableMeasurements = signalData.keys.where((meas) => [char!.baseSignal, ...char!.compSignals].every((signal) => signalData[meas]?.containsKey(signal) ?? false)).toList();

    if(usableMeasurements.isEmpty){
      showError(context, "This Characteristics cannot be launched due to missing channels");
      return;
    }
    if(usableMeasurements.length == 1){
      char = CustomCharacteristicsDescriptor(name: char!.name, measurement: usableMeasurements.first, baseSignal: char!.baseSignal, compSignals: char!.compSignals);
      char!.launch();
      return;
    }

    Navigator.of(context).pop();
    showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
      return DialogBase(
        title: "Chart grid launch",
        dialog: CharacteristicsLaunchSelected(char: char!, usableMeasurements: usableMeasurements),
        minWidth: 600,
        maxHeight: 600,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if(char == null){
      return Center(
        child: Text("Error when parsing ${widget.file.path}", style: StyleManager.textStyle,),
      );
    }

    if(!opened){
      return Row(
        children: [
          Padding(
            padding: EdgeInsets.all(StyleManager.globalStyle.padding),
            child: Text(char!.name, style: StyleManager.subTitleStyle,),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.all(StyleManager.globalStyle.padding),
            child: Text(char!.measurement, style: StyleManager.subTitleStyle,),
          ),
          const Spacer(),
          IconButton(
            onPressed: (){
              opened = true;
              setState(() {});
            },
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: StyleManager.globalStyle.primaryColor,)
          ),
          IconButton(
            onPressed: () => _onSelected(context),
            icon: Icon(Icons.play_arrow_rounded, color: StyleManager.globalStyle.primaryColor,)
          ),
          IconButton(
            onPressed: widget.onDeleted,
            icon: Icon(Icons.delete, color: StyleManager.globalStyle.primaryColor,)
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: Text(char!.name, style: StyleManager.subTitleStyle,),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: Text(char!.measurement, style: StyleManager.subTitleStyle,),
            ),
            const Spacer(),
            IconButton(
              onPressed: (){
                opened = false;
                setState(() {});
              },
              icon: Icon(Icons.keyboard_arrow_up_rounded, color: StyleManager.globalStyle.primaryColor,)
            ),
            IconButton(
              onPressed: () => _onSelected(context),
              icon: Icon(Icons.play_arrow_rounded, color: StyleManager.globalStyle.primaryColor,)
            ),
            IconButton(
              onPressed: widget.onDeleted,
              icon: Icon(Icons.delete, color: StyleManager.globalStyle.primaryColor,)
            ),
          ],
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: Text(char!.baseSignal, style: StyleManager.subTitleStyle,),
            ),
            const Spacer(),
            Column(
              children: [
                for(final String comp in char!.compSignals)
                  Padding(
                    padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                    child: Text(comp, style: StyleManager.subTitleStyle,),
                  ),
              ],
            )
          ],
        )
      ],
    );

  }
}

class CharacteristicsLaunchSelected extends StatefulWidget {
  const CharacteristicsLaunchSelected({super.key, required this.char, required this.usableMeasurements});

  final CustomCharacteristicsDescriptor char;
  final List<String> usableMeasurements;

  @override
  State<CharacteristicsLaunchSelected> createState() => _CharacteristicsLaunchSelectedState();
}

class _CharacteristicsLaunchSelectedState extends State<CharacteristicsLaunchSelected> {
  String? chosenMeasurement;

  void _tryLaunch(BuildContext context){
    if(chosenMeasurement == null){
      showError(context, "The measurement was not set");
      return;
    }
    CustomCharacteristicsDescriptor modif = CustomCharacteristicsDescriptor(name: widget.char.name, measurement: chosenMeasurement!, baseSignal: widget.char.baseSignal, compSignals: widget.char.compSignals);
    modif.launch();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: Text(widget.char.name, style: StyleManager.subTitleStyle,),
            ),
            const Spacer(),
            Container(
              width: 100,
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: DropdownButton<String>(
                isExpanded: true,
                value: chosenMeasurement,
                items: [const DropdownMenuItem<String>(value: null, child: Text("Select")), ...widget.usableMeasurements.map((meas) => DropdownMenuItem<String>(value: meas, child: Text(meas)))],
                onChanged: (value) {
                  chosenMeasurement = value;
                  setState(() {});
                },
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _tryLaunch(context),
              icon: Icon(Icons.play_arrow_rounded, color: StyleManager.globalStyle.primaryColor,)
            ),
            IconButton(
              onPressed: (){
                Navigator.of(context).pop();
                showDialog<Widget>(context: mainWindowNavigatorKey.currentContext!, builder: (BuildContext context){
                  return const DialogBase(
                    title: "Chart grid setup",
                    dialog: CharacteristicsSetupDialog(),
                    minWidth: 600,
                    maxHeight: 600,
                  );
                });
              },
              icon: Icon(Icons.keyboard_arrow_left_rounded, color: StyleManager.globalStyle.primaryColor,)
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(StyleManager.globalStyle.padding),
              child: Text(widget.char.baseSignal, style: StyleManager.textStyle,),
            ),
            const Spacer(),
            Column(
              children: [
                for(final String sig in widget.char.compSignals)
                  Padding(
                    padding: EdgeInsets.all(StyleManager.globalStyle.padding),
                    child: Text(sig, style: StyleManager.textStyle,),
                  ),
              ],
            )
          ],
        ),
      ],
    );
  }
}