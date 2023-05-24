import 'package:flutter/material.dart';

import 'multiprocess/childprocess_api.dart';

void main(List<String> args) {
  try{
    if(args.isEmpty){
      localSocketPort = masterSocketPort;
    }
    else{
      localSocketPort = int.parse(args[1]);
    }
  }
  catch (exc){
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp();
  }
}
