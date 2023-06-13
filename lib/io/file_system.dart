import 'dart:io';

String? _currentDirectory;

Future<String?> get getCurrentDirectory async {
  if(_currentDirectory != null){
    return _currentDirectory;
  }
  String dir = Platform.resolvedExecutable;
  if(Platform.isWindows){  // Linux nem buzi
    dir = dir.replaceAll(r'\', '/');
  }
  dir = dir.split('/').reversed.toList().sublist(1).reversed.toList().join('/');
  if(Platform.isWindows){
    dir = dir.replaceAll('/', r'\');
    dir = dir + r'\';
    _currentDirectory = dir;
    return dir;
  }
  else if(Platform.isLinux){
    dir = dir + r'/';
    _currentDirectory = dir;
    return dir;
  }
  else{
    return null;
  }
}