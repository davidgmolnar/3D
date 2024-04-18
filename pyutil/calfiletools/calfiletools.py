from os import listdir
from re import match

from util.containers import Vector, Map

_CAL_REPO_DIR: str = "C:/Users/Lenovo/Desktop/Calfiles2021"
_CAL_IMPORT_PATTERN: str = r"[0-9]{4}_[a-zA-Z]+.[cC]{1}[aA]{1}[lL]{1}"
_ALREADY_IMPLEMENTED: list[str] = ["+", "-", "*", "/", "DERIVATE", "INTEGRATE", "AND", "NAND", "OR", "NOR",
                                   "XOR", "XNOR", "NOT", "ABS", "IFEXISTS", "DELETE", "MIN", "MAX", "IF", "SHIFT",
                                   "FILLFROMBOOL"]


class Instruction:
    def __init__(self, line: str):
        self.op: str = self.__getOp(line)
        self.result: str | None = self.__getResult(line) if line.__contains__('=') else None
        self.operands: Vector[str] = self.__getOperands(line)
        self._line: str = line

    @staticmethod
    def __getResult(line: str) -> str:
        return line.split('=')[0].rstrip()

    @staticmethod
    def __getOp(line: str) -> str:
        return line.split('(')[0].split('=')[-1].strip().upper()

    @staticmethod
    def __getOperands(line: str) -> Vector[str]:
        return Vector(
            "".join("".join(line.split('(')[1:]).split(')')[:-1]).split(',')
        ).map(lambda op: op.strip())

    def __str__(self):
        return self._line


class CalFileTools:
    def __init__(self):
        self._calfiles: Map[str, Vector[Instruction]] = Map()

    @staticmethod
    def _isComment(line: str) -> bool:
        return line.startswith(';') or line.startswith('[') or line.startswith('//') or (
                line.startswith('{') and line.endswith('}'))

    @staticmethod
    def _removeBlockComment(lines: Vector[str]) -> Vector[str]:
        while True:
            start = lines.indexWhere(lambda line: line.startswith('{'), orElse=-1)
            if start == -1:
                break

            end = lines.indexWhere(lambda line: line.endswith('}'), orElse=-1)
            if end == -1:
                raise ValueError("Unclosed block comment detected")
            lines.removeRange(start, end + 1)
        return lines

    def _import(self, file: str):
        maybeHasBlockComment = Vector(
            open(f"{_CAL_REPO_DIR}/{file}", 'r')
            .read()
            .split('\n')
        ).where(lambda line: len(line.strip()) > 0 and not self._isComment(line))

        self._calfiles[file] = self._removeBlockComment(maybeHasBlockComment).map(lambda line: Instruction(line))

    def init(self):
        for file in listdir(_CAL_REPO_DIR):
            if match(_CAL_IMPORT_PATTERN, file) is not None:
                self._import(file)
        return self

    def _collect(self) -> Map[str, Vector[Instruction]]:
        separated: Map[str, Vector[Instruction]] = Map()

        def add(i: Instruction):
            if i.op not in separated.ks:
                separated[i.op] = Vector()
            separated[i.op].append(i)

        for script in self._calfiles.vs:
            script.forEach(add)

        return separated

    def rankCommandsByUsage(self):
        separated: Map[str, Vector[Instruction]] = self._collect()

        ops: Vector[str] = separated.ks.where(lambda o: o not in _ALREADY_IMPLEMENTED)
        ops.sort(key=lambda o: separated[o].length, reverse=True)

        for op in ops:
            print(f"OP: {op} count: {separated[op].length}")
            for inst in separated[op]:
                print(f"\t{inst}")

    def stat(self):
        separated: Map[str, Vector[Instruction]] = self._collect()
        notImplemented: Vector[str] = separated.ks.where(lambda o: o not in _ALREADY_IMPLEMENTED)
        notImplemented.sort(key=lambda o: separated[o].length, reverse=True)
        nnum = notImplemented.fold(0, lambda prev, o: prev + separated[o].length)
        implemented: Vector[str] = separated.ks.where(lambda o: o in _ALREADY_IMPLEMENTED)
        implemented.sort(key=lambda o: separated[o].length, reverse=True)
        inum = implemented.fold(0, lambda prev, o: prev + separated[o].length)

        print(f"Total not implemented {nnum}")
        for op in notImplemented:
            print(f"\tNot implemented: {op} count: {separated[op].length}")

        print(f"Total implemented {inum}")
        for op in implemented:
            print(f"\tImplemented: {op} count: {separated[op].length}")


if __name__ == '__main__':
    cft = CalFileTools().init()
    cft.rankCommandsByUsage()
    cft.stat()
