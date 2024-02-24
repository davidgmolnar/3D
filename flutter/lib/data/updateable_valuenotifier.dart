import 'package:flutter/foundation.dart';

class UpdateableValueNotifier<T> extends ValueNotifier<T>{
  UpdateableValueNotifier(super.value);
  
  void update(void Function(T value) updater){
    updater(value);
    notifyListeners();
  }

  void updateWithoutNotify(void Function(T value) updater){
    updater(value);
  }
}