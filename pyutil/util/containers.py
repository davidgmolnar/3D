from typing import Any, Callable


class Vector(list):

    ###################################
    # Constructors
    ###################################

    def __init__(self, v=()):
        list.__init__(self, v)

    @staticmethod
    def filled(length: int, fill):
        v = Vector()
        for _ in range(length):
            v.append(fill)
        return v

    @staticmethod
    def generate(length: int, generator: Callable[[int], Any]):
        v = Vector()
        for i in range(length):
            v.append(generator(i))
        return v

    ###################################
    # Properties
    ###################################

    @property
    def first(self):
        return self[0]

    @first.setter
    def first(self, x):
        if len(self):
            self[0] = x
        else:
            self.append(x)

    @property
    def last(self):
        return self[-1]

    @last.setter
    def last(self, x):
        if len(self):
            self[-1] = x
        else:
            self.append(x)

    @property
    def length(self) -> int:
        return len(self)

    @property
    def isEmpty(self) -> bool:
        return len(self) == 0

    @property
    def isNotEmpty(self) -> bool:
        return len(self) != 0

    @property
    def reversed(self):
        return Vector(self.__reversed__())

    ###################################
    # Methods
    ###################################

    def any(self, test: Callable[[Any], bool]) -> bool:
        for elem in self:
            if test(elem):
                return True
        return False

    def contains(self, elem) -> bool:
        return self.__contains__(elem)

    def every(self, test: Callable[[Any], bool]) -> bool:
        for elem in self:
            if not test(elem):
                return False
        return True

    def firstWhere(self, test: Callable[[Any], bool], orElse):
        for elem in self:
            if test(elem):
                return elem
        return orElse

    def fold(self, initialValue, combine: Callable[[Any, Any], Any]):
        value = initialValue
        for elem in self:
            value = combine(value, elem)
        return value

    def forEach(self, action: Callable[[Any], None]) -> None:
        for elem in self:
            action(elem)

    def indexOf(self, elem, orElse: int) -> int:
        try:
            return self.index(elem)
        except ValueError:
            return orElse

    def indexWhere(self, test: Callable[[Any], bool], orElse: int) -> int:
        for i, elem in enumerate(self):
            if test(elem):
                return i
        return orElse

    def lastIndexOf(self, elem, orElse: int) -> int:
        res = self.reversed.indexOf(elem, orElse)
        return orElse if res == orElse else self.length - 1 - res

    def lastIndexWhere(self, test: Callable[[Any], bool], orElse: int) -> int:
        res = self.reversed.indexWhere(test, orElse)
        return orElse if res == orElse else self.length - 1 - res

    def lastWhere(self, test: Callable[[Any], bool], orElse):
        return self.reversed.firstWhere(test, orElse)

    def map(self, mutation: Callable[[Any], Any]):
        return Vector([mutation(elem) for elem in self])

    def range(self, start: int, end: int):
        return Vector(self[start: end])

    def reduce(self, combine: Callable[[Any, Any], Any]):
        if self.isEmpty:
            raise ValueError("Cannot reduce an empty vector")
        if self.length == 1:
            return self[0]

        value = self[0]
        for i, elem in enumerate(self[1:]):
            value = combine(value, elem)
        return value

    def removeAt(self, i: int) -> None:
        if self.length > i:
            self.pop(i)

    def removeRange(self, start: int, end: int) -> None:
        del self[start: end]

    def removeWhere(self, test: Callable[[Any], bool]) -> None:
        to_pop = []
        for i, elem in enumerate(self):
            if test(elem):
                to_pop.append(i)

        for p in to_pop.__reversed__():
            self.removeAt(p)

    def skip(self, count: int):
        return Vector(self[count:])

    def skipWhile(self, test: Callable[[Any], bool]):
        for i, elem in enumerate(self):
            if not test(elem):
                return Vector(self[i:])
        return Vector()

    def take(self, count: int):
        return Vector(self[:count])

    def takeWhile(self, test: Callable[[Any], bool]):
        for i, elem in enumerate(self):
            if not test(elem):
                return Vector(self[:i])
        return Vector()

    def toList(self) -> list:
        return list(self)

    def toSet(self) -> set:
        return set(self)

    def where(self, test: Callable[[Any], bool]):
        return Vector([elem for elem in self if test(elem)])

    def whereType(self, t: type):
        return Vector([elem for elem in self if isinstance(elem, t)])


K = Any
V = Any


class Map(dict):

    ###################################
    # Constructors
    ###################################

    def __init__(self, m=(), **kwargs):
        dict.__init__(self, m, **kwargs)

    @staticmethod
    def fromEntries(entries: Vector):
        m = Map()
        for entry in entries:
            m.update(entry)
        return m

    ###################################
    # Properties
    ###################################

    @property
    def length(self) -> int:
        return len(self)

    @property
    def isEmpty(self) -> bool:
        return len(self) == 0

    @property
    def isNotEmpty(self) -> bool:
        return len(self) != 0

    @property
    def ks(self) -> Vector:
        return Vector(self.keys())

    @property
    def vs(self) -> Vector:
        return Vector(self.values())

    @property
    def entries(self) -> Vector:
        return self.ks.map(lambda key: {key: self[key]})

    ###################################
    # Methods
    ###################################

    def containsKey(self, key) -> bool:
        return self.ks.contains(key)

    def containsValue(self, value) -> bool:
        return self.vs.contains(value)

    def forEach(self, action: Callable[[K, V], None]) -> None:
        for key in self.keys():
            action(key, self[key])

    def map(self, mutation: Callable[[K, V], dict]):
        return Map.fromEntries(Vector([mutation(key, self[key]) for key in self.keys()]))

    def removeKey(self, key) -> V:
        return self.pop(key)

    def removeWhere(self, test: Callable[[K, V], bool]) -> None:
        for key in self.keys():
            if test(key, self[key]):
                self.removeKey(key)

    def updateAtKey(self, key, mutation: Callable[[V], V]) -> None:
        if key not in self.keys():
            return
        self[key] = mutation(self[key])

    def updateAll(self, mutation: Callable[[K, V], V]) -> None:
        for key in self.keys():
            self[key] = mutation(key, self[key])
