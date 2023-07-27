import 'dart:typed_data';

import '../io/logger.dart';

const int _fragmentLength = 8000;

class _FragmentBuffer{
  int nextBufferId = 0;
  List<Uint8List> buffer = [];

  _FragmentBuffer(this.nextBufferId, this.buffer);
}

/// Header
/// [Fragment Flag 0][Message ID 1-7]
/// [Fragment ID 0-7]
/// [Fragment ID 0-7]
/// [Fragment ID 0-7]
abstract class Protocol{
  static int _nextMessageId = 0;
  static int get _getNextMessageId {
    _nextMessageId++;
    return _nextMessageId %= 128;
  }

  static final Logger _protocolLogger = Logger(mainLogPath, "PROTOCOL");

  static final Map<int, _FragmentBuffer> _fragmentBuffer = {};

  static List<Uint8List> encode(Uint8List data){
    if(data.length < _fragmentLength){
      return [Uint8List.fromList([_getNextMessageId,0,0,0,...data.toList()])];
    }
    else{
      final List<Uint8List> messages = [];
      int fragmentID = 0;
      for(int offset = 0; offset < data.length - _fragmentLength; offset += _fragmentLength){
        Uint8List header = Uint8List(4);
        ByteData headerByteData = header.buffer.asByteData();
        headerByteData.setUint8(0, 128 + _getNextMessageId);
        headerByteData.setUint8(1, (fragmentID >> 16) & 0xFF);
        headerByteData.setUint16(2, fragmentID & 0xFFFF);
        fragmentID++;
        messages.add(Uint8List.fromList(header.toList()..addAll(data)));
      }
      return messages;
    }
  }

  static Uint8List? decode(Uint8List data){
    ByteData byteData = data.buffer.asByteData();
    int byte0 = byteData.getUint8(0);
    int messageID = byte0 & 0x7F;
    if(byte0 < 128){
      if(_fragmentBuffer.containsKey(messageID)){
        List<int> fullMessage = _fragmentBuffer[messageID]!.buffer.fold<List<int>>([], (previousValue, element) => previousValue..addAll(element));
        _fragmentBuffer.remove(messageID);
        return Uint8List.fromList(fullMessage);
      }
      return data.sublist(4);
    }
    int fragmentID = byteData.getUint8(1) << 16 + byteData.getUint16(2);
    if(_fragmentBuffer.containsKey(messageID)){
      if(_fragmentBuffer[messageID]!.nextBufferId == fragmentID){
        _fragmentBuffer[messageID]!.buffer.add(data.sublist(4));
        _fragmentBuffer[messageID]!.nextBufferId++;
        return null;
      }
      _protocolLogger.warning("Fragment ID $fragmentID was received, but ${_fragmentBuffer[messageID]!.nextBufferId} was expected");
    }
    else if(fragmentID == 0){
      _fragmentBuffer[messageID] = _FragmentBuffer(1, [data.sublist(4)]);
    }
    else{
      _protocolLogger.warning("Received new message with starting fragment ID $fragmentID.");
    }
    return null;
  }
}