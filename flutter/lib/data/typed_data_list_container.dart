import 'dart:math';
import 'dart:typed_data';

import 'package:dart_dbc_parser/signal/dbc_signal.dart';

class TypedDataListContainer<T extends TypedData>{
  static const List<Type> floatLike = [Float32List, Float64List];

  late T _list;
  late int _capacity;
  int _size = 0;

  TypedDataListContainer({
    required T list,
  }){
    _list = list;
    _capacity = list.lengthInBytes ~/ list.elementSizeInBytes;
  }

  int get size => _size;
  int get capacity => _capacity;
  Iterable get iterable => (_list as List);
  num get last => (_list as List)[size - 1];
  num get first => (_list as List)[0];
  set last(num v){
    if(floatLike.contains(T)){
      (_list as List)[size - 1] = v;
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
    if(T == Uint8List){
      Uint8List tmp = Uint8List(newCapacity)..setRange(0, _size, (_list as Uint8List));
      _list = tmp as T;
    }
    else if(T == Uint16List){
      Uint16List tmp = Uint16List(newCapacity)..setRange(0, _size, (_list as Uint16List));
      _list = tmp as T;
    }
    else if(T == Uint32List){
      Uint32List tmp = Uint32List(newCapacity)..setRange(0, _size, (_list as Uint32List));
      _list = tmp as T;
    }
    else if(T == Uint64List){
      Uint64List tmp = Uint64List(newCapacity)..setRange(0, _size, (_list as Uint64List));
      _list = tmp as T;
    }
    else if(T == Int8List){
      Int8List tmp = Int8List(newCapacity)..setRange(0, _size, (_list as Int8List));
      _list = tmp as T;
    }
    else if(T == Int16List){
      Int16List tmp = Int16List(newCapacity)..setRange(0, _size, (_list as Int16List));
      _list = tmp as T;
    }
    else if(T == Int32List){
      Int32List tmp = Int32List(newCapacity)..setRange(0, _size, (_list as Int32List));
      _list = tmp as T;
    }
    else if(T == Int64List){
      Int64List tmp = Int64List(newCapacity)..setRange(0, _size, (_list as Int64List));
      _list = tmp as T;
    }
    else if(T == Float32List){
      Float32List tmp = Float32List(newCapacity)..setRange(0, _size, (_list as Float32List));
      _list = tmp as T;
    }
    else if(T == Float64List){
      Float64List tmp = Float64List(newCapacity)..setRange(0, _size, (_list as Float64List));
      _list = tmp as T;
    }
    _capacity = newCapacity;
  }

  void clear(){
    (_list as List).clear();
    _capacity = 0;
    _size = 0;
  }

  void pushBack(num value){
    if(!floatLike.contains(T)){
      value = value.toInt();
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

  void set(TypedDataListContainer<TypedData> other){
    (_list as List).clear();
    _list = other as T;
    _capacity = other.capacity;
    _size = other.size;
  }

  void shrinkToFit(){
    if(_size >= _capacity){
      return;
    }
    if(T == Uint8List){
      Uint8List tmp = Uint8List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Uint16List){
      Uint16List tmp = Uint16List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Uint32List){
      Uint32List tmp = Uint32List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Uint64List){
      Uint64List tmp = Uint64List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Int8List){
      Int8List tmp = Int8List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Int16List){
      Int16List tmp = Int16List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Int32List){
      Int32List tmp = Int32List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Int64List){
      Int64List tmp = Int64List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Float32List){
      Float32List tmp = Float32List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
    else if(T == Float64List){
      Float64List tmp = Float64List.view(_list.buffer, _list.offsetInBytes, _size);
      _list = tmp as T;
    }
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
}