import 'dart:math';
import 'dart:typed_data';

import 'package:dart_dbc_parser/signal/dbc_signal.dart';

class TypedDataListContainer<T extends TypedData>{
  static const List<Type> floatLike = [Float32List, Float64List];

  static final Map<Type, TypedData Function(ByteBuffer, int, int)> _viewCtors = {
    Uint8List: (p0, p1, p2) => Uint8List.view(p0, p1, p2),
    Uint16List: (p0, p1, p2) => Uint16List.view(p0, p1, p2),
    Uint32List: (p0, p1, p2) => Uint32List.view(p0, p1, p2),
    Uint64List: (p0, p1, p2) => Uint64List.view(p0, p1, p2),
    Int8List: (p0, p1, p2) => Int8List.view(p0, p1, p2),
    Int16List: (p0, p1, p2) => Int16List.view(p0, p1, p2),
    Int32List: (p0, p1, p2) => Int32List.view(p0, p1, p2),
    Int64List: (p0, p1, p2) => Int64List.view(p0, p1, p2),
    Float32List: (p0, p1, p2) => Float32List.view(p0, p1, p2),
    Float64List: (p0, p1, p2) => Float64List.view(p0, p1, p2)
  };

  static final Map<Type, TypedData Function(int, int, TypedData)> _realloc = {
    Uint8List: (p0, p1, p2) => Uint8List(p0)..setRange(0, p1, (p2 as Uint8List)),
    Uint16List: (p0, p1, p2) => Uint16List(p0)..setRange(0, p1, (p2 as Uint16List)),
    Uint32List: (p0, p1, p2) => Uint32List(p0)..setRange(0, p1, (p2 as Uint32List)),
    Uint64List: (p0, p1, p2) => Uint64List(p0)..setRange(0, p1, (p2 as Uint64List)),
    Int8List: (p0, p1, p2) => Int8List(p0)..setRange(0, p1, (p2 as Int8List)),
    Int16List: (p0, p1, p2) => Int16List(p0)..setRange(0, p1, (p2 as Int16List)),
    Int32List: (p0, p1, p2) => Int32List(p0)..setRange(0, p1, (p2 as Int32List)),
    Int64List: (p0, p1, p2) => Int64List(p0)..setRange(0, p1, (p2 as Int64List)),
    Float32List: (p0, p1, p2) => Float32List(p0)..setRange(0, p1, (p2 as Float32List)),
    Float64List: (p0, p1, p2) => Float64List(p0)..setRange(0, p1, (p2 as Float64List))
  };

  static final Map<Type, TypedDataListContainer Function(TypedData)> _ctors = {
    Uint8List: (p0) => TypedDataListContainer<Uint8List>(list: p0 as Uint8List),
    Uint16List: (p0) => TypedDataListContainer<Uint16List>(list: p0 as Uint16List),
    Uint32List: (p0) => TypedDataListContainer<Uint32List>(list: p0 as Uint32List),
    Uint64List: (p0) => TypedDataListContainer<Uint64List>(list: p0 as Uint64List),
    Int8List: (p0) => TypedDataListContainer<Int8List>(list: p0 as Int8List),
    Int16List: (p0) => TypedDataListContainer<Int16List>(list: p0 as Int16List),
    Int32List: (p0) => TypedDataListContainer<Int32List>(list: p0 as Int32List),
    Int64List: (p0) => TypedDataListContainer<Int64List>(list: p0 as Int64List),
    Float32List: (p0) => TypedDataListContainer<Float32List>(list: p0 as Float32List),
    Float64List: (p0) => TypedDataListContainer<Float64List>(list: p0 as Float64List),
  };

  static const Map<Type, int> _typeSignatures = {
    Uint8List: 0,
    Uint16List: 1,
    Uint32List: 2,
    Uint64List: 3,
    Int8List: 4,
    Int16List: 5,
    Int32List: 6,
    Int64List: 7,
    Float32List: 8,
    Float64List: 9
  };

  static const Map<Type, int> _elemBytes = {
    Uint8List: 1,
    Uint16List: 2,
    Uint32List: 4,
    Uint64List: 8,
    Int8List: 1,
    Int16List: 2,
    Int32List: 4,
    Int64List: 8,
    Float32List: 4,
    Float64List: 8
  };

  late T _list;
  late int _capacity;
  int _size = 0;

  // TODO a realloc és viewctor kikerülhetne final memberbe és akkor nem menet közben kell kihashelni

  TypedDataListContainer({
    required T list,
  }){
    _list = list;
    _capacity = list.lengthInBytes ~/ list.elementSizeInBytes;
    _size = _capacity;
  }

  int get size => _size;
  int get capacity => _capacity;
  Iterable<num> get iterable => (_list as List<num>);
  num get last => (_list as List)[size - 1];
  num get first => (_list as List)[0];
  set last(num v){
    if(floatLike.contains(T)){
      (_list as List)[size - 1] = v.toDouble();
    }
    else{
      (_list as List)[size - 1] = v.toInt();
    }
  }
  bool get isNotEmpty => size != 0;

  static double __getEffectiveMin(final DBCSignal signal, final bool hasMinMax){
    if(hasMinMax){
      return signal.min;
    }

    if(signal.signalSignedness == DBCSignalSignedness.UNSIGNED){
      return signal.factor.sign == -1.0 ?
        (pow(2, signal.lenght) - 1) * signal.factor + signal.offset
        :
        signal.offset;
    }
    else{
      return signal.factor.sign == -1.0 ?
        (pow(2, signal.lenght - 1) - 1) * signal.factor + signal.offset
        :
        -pow(2, signal.lenght - 1) * signal.factor + signal.offset;
    }
  }

  static double __getEffectiveMax(final DBCSignal signal, final bool hasMinMax){
    if(hasMinMax){
      return signal.max;
    }

    if(signal.signalSignedness == DBCSignalSignedness.UNSIGNED){
      return signal.factor.sign == -1.0 ?
        signal.offset
        :
        (pow(2, signal.lenght) - 1) * signal.factor + signal.offset;
    }
    else{
      return signal.factor.sign == -1.0 ?
        -pow(2, signal.lenght - 1) * signal.factor + signal.offset
        :
        (pow(2, signal.lenght - 1) - 1) * signal.factor + signal.offset;
    }
  }

  static TypedDataListContainer emptyFromDBC(final DBCSignal signal){
    final bool hasMinMax = (signal.max != 0 || signal.min != 0) && signal.min < signal.max;
    final double effectiveMin = __getEffectiveMin(signal, hasMinMax);
    final double effectiveMax = __getEffectiveMax(signal, hasMinMax);
    if(signal.factor == signal.factor.roundToDouble() && signal.offset == signal.offset.roundToDouble()){
      if(effectiveMin >= 0){
        if(effectiveMax <= 255){
          return TypedDataListContainer<Uint8List>(list: Uint8List(0));
        }
        else if(effectiveMax <= 65535){
          return TypedDataListContainer<Uint16List>(list: Uint16List(0));
        }
        else if(effectiveMax <= 4294967295){
          return TypedDataListContainer<Uint32List>(list: Uint32List(0));
        }
        else{
          return TypedDataListContainer<Uint64List>(list: Uint64List(0));
        }
      }
      else{
        if(effectiveMin >= -128 && effectiveMax <= 127){
          return TypedDataListContainer<Int8List>(list: Int8List(0));
        }
        else if(effectiveMin >= -32768 && effectiveMax <= 32767){
          return TypedDataListContainer<Int16List>(list: Int16List(0));
        }
        else if(effectiveMin >= -2147483648 && effectiveMax <= 2147483647){
          return TypedDataListContainer<Int32List>(list: Int32List(0));
        }
        else{
          return TypedDataListContainer<Int64List>(list: Int64List(0));
        }
      }
    }
    else{
      const double f32Threshold = 1e8;
      if(effectiveMin > -f32Threshold && effectiveMax < f32Threshold){
        return TypedDataListContainer<Float32List>(list: Float32List(0));
      }
      else{
        return TypedDataListContainer<Float64List>(list: Float64List(0));
      }
    }
  }

  void reserve(int newCapacity){
    _list = _realloc[T]!(newCapacity, _size, _list) as T;
    _capacity = newCapacity;
  }

  void clear(){
    _size = 0;
    reserve(0);
  }

  void pushBack(num value){
    if(!floatLike.contains(T)){
      value = value.toInt();
    }
    else{
      value = value.toDouble();
    }
    if(_capacity > _size){
      (_list as List)[_size] = value;
      _size++;
    }
    else{
      reserve(_capacity + 10000);
      (_list as List)[_size] = value;
      _size++;
    }
  }

  /*void addAll(TypedDataListContainer<TypedData> other){
    reserve(_capacity + other.size);
    (_list as List).setRange(_size, _capacity, other.iterable);
  }*/

  void shrinkToFit(){
    if(_size >= _capacity){
      return;
    }
    _list = _viewCtors[T]!(_list.buffer, _list.offsetInBytes, _size) as T;
    _capacity = _size;
  }

  List<E> toList<E>(){
    return (_list as List<E>);
  }

  num operator[](int index){
    if(index >= _size){
      throw Exception("Invalid index $index to a list of length $_size");
    }
    if(floatLike.contains(T)){
      return (_list as List)[index] as double;
    }
    else{
      return (_list as List)[index] as int;
    }
  }

  Uint8List toBytes(){
    final List<int> bytes = [];
    final Uint64List s = Uint64List.fromList([_size]);
    bytes.addAll(s.buffer.asUint8List(s.offsetInBytes, s.lengthInBytes));
    bytes[7] = _typeSignatures[T]!;
    bytes.addAll(_viewCtors[T]!(_list.buffer, _list.offsetInBytes, _size).buffer.asUint8List(_list.offsetInBytes, _elemBytes[T]! * _size));
    return Uint8List.fromList(bytes);
  }

  static TypedDataListContainer fromBytes(final Uint8List bytes, {final int outerOffset = 0}){
    final ByteData data = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final ByteBuffer buf = bytes.buffer;
    int point = 0;

    final int desc = data.getUint64(point, Endian.host);
    final int typeSig = (desc >> 56) & 0xFF;
    final int elemNum = desc & 0xFFFFFFFFFFFFFF;
    final Type t = _typeSignatures.keys.firstWhere((element) => _typeSignatures[element] == typeSig);
    point += 8;
    TypedData list = _viewCtors[t]!(buf, point + outerOffset, elemNum);
    return _ctors[t]!(list);
  }
}