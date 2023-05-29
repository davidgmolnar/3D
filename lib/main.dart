import 'routes/startup.dart';

void main(List<String> args) {
  if(!tryStartup(args)){
    return;
  }
  runSelectedApp();
}