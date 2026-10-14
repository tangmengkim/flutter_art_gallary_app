
abstract class LocalRepository<T> {
  List<T> getAll();
  T? getById(String id);
  Future<void> save(String id, T item);
  Future<void> delete(String id);
}

