import 'dart:typed_data';

import '../io/exporter.dart';
import '../io/importer.dart';
import 'calculation/unit.dart';
import 'typed_data_list_container.dart';

class SignalContainer{
  TypedDataListContainer values;
  TypedDataListContainer timestamps;
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

  Uint8List toBytes(){
    List<int> bytes = [];
    final Uint8List v = values.toBytes();
    final Uint8List t = timestamps.toBytes();
    final Uint8List dbcn = Exporter.utf8Decoder.convert(dbcName);
    final Uint8List dn = Exporter.utf8Decoder.convert(displayName);

    final Uint64List vs = Uint64List.fromList([v.length]);
    final Uint64List ts = Uint64List.fromList([t.length]);
    final Uint64List dbcns = Uint64List.fromList([dbcn.length]);
    final Uint64List dns = Uint64List.fromList([dn.length]);

    bytes.addAll(vs.buffer.asUint8List(vs.offsetInBytes, vs.lengthInBytes));
    bytes.addAll(v);

    bytes.addAll(ts.buffer.asUint8List(ts.offsetInBytes, ts.lengthInBytes));
    bytes.addAll(t);
    
    bytes.addAll(dbcns.buffer.asUint8List(dbcns.offsetInBytes, dbcns.lengthInBytes));
    bytes.addAll(dbcn);

    bytes.addAll(dns.buffer.asUint8List(dns.offsetInBytes, dns.lengthInBytes));
    bytes.addAll(dn);

    // TODO unit

    return Uint8List.fromList(bytes);
  }

  static SignalContainer fromBytes(final Uint8List bytes){
    final ByteData data = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final ByteBuffer buf = bytes.buffer;
    int point = 0;

    final int vSize = data.getUint64(point, Endian.host);
    point += 8;
    final Uint8List vData = buf.asUint8List(point, vSize);
    final TypedDataListContainer values = TypedDataListContainer.fromBytes(vData, outerOffset: point);
    point += vSize;

    final int tSize = data.getUint64(point, Endian.host);
    point += 8;
    final Uint8List tData = buf.asUint8List(point, tSize);
    final TypedDataListContainer timestamps = TypedDataListContainer.fromBytes(tData, outerOffset: point);
    point += tSize;

    final int dbcnSize = data.getUint64(point, Endian.host);
    point += 8;
    final Uint8List dbcnData = buf.asUint8List(point, dbcnSize);
    point += dbcnSize;

    final int dnSize = data.getUint64(point, Endian.host);
    point += 8;
    final Uint8List dnData = buf.asUint8List(point, dnSize);
    point += dnSize;

    return SignalContainer(
      values: values,
      timestamps: timestamps as TypedDataListContainer<Uint32List>,
      dbcName: Importer.safeUTF8Decode(dbcnData),
      displayName: Importer.safeUTF8Decode(dnData),
      unit: null
    );    
  }
}