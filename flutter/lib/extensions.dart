extension ListExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) => [...this]..sort(compare);
  List<T> removedWhere(bool Function(T a) check) => [...this]..removeWhere(check);
}