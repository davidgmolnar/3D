import 'dart:io';

Future<String?> getCurrentDirectory() async {
  String dir = Platform.resolvedExecutable;
  if(Platform.isWindows){  // Linux nem buzi
    dir = dir.replaceAll(r'\', '/');
  }
  dir = dir.split('/').reversed.toList().sublist(1).reversed.toList().join('/');
  if(Platform.isWindows){
    dir = dir.replaceAll('/', r'\');
    dir = dir + r'\';
    return dir;
  }
  else if(Platform.isLinux){
    dir = dir + r'/';
    return dir;
  }
  else{
    return null;
  }
}