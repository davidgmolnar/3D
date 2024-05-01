import 'dart:convert';
import 'dart:typed_data';

abstract class Exporter {

  static Utf8Encoder utf8Decoder = const Utf8Encoder();

  static JsonEncoder jsonEncoder = const JsonEncoder();

  static Uint8List jsonToBytes(Map jsonEncodeable) => utf8Decoder.convert(jsonEncoder.convert(jsonEncodeable));
  
}