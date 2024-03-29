import 'dart:typed_data';

import 'calculation/unit.dart';
import 'typed_data_list_container.dart';

class SignalContainer{
  TypedDataListContainer values;
  TypedDataListContainer<Uint32List> timestamps;
  final String dbcName;
  String displayName;
  Unit? unit;

  SignalContainer({
    required this.values,
    required this.timestamps,
    required this.dbcName,
    required this.displayName,
    this.unit
  });
}