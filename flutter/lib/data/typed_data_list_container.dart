import 'dart:typed_data';

class TypedDataListContainer<T extends TypedData>{
  static const List<Type> allowedTypes = [Uint8List, Uint16List, Uint32List, Uint64List, Int8List, Int16List, Int32List, Int64List, Float32List, Float64List];
  static const List<Type> floatLike = [Float32List, Float64List];

  late T _list;
  late int _capacity;
  int _size = 0;

  TypedDataListContainer({
    required T list,
  }){
    assert(allowedTypes.contains(T));
    _list = list;
    _capacity = list.lengthInBytes ~/ list.elementSizeInBytes;
  }

  int get size => _size;
  int get capacity => _capacity;
  Iterable get iterable => (_list as List);

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

  void pushBack(num value){
    if(_capacity > _size){
      (_list as List)[_size] = value;
      _size++;
    }
    else{
      reserve(_capacity + 100);
      (_list as List)[_size] = value;
      _size++;
    }
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

  dynamic operator[](int index){
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