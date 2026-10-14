
import 'package:hive_ce/hive.dart';
import 'local_repository.dart';

class HiveLocalRepository<T> implements LocalRepository<T> {
  final Box<T> _box;
  HiveLocalRepository(this._box);

  @override
  List<T> getAll() => _box.values.toList();

  @override
  T? getById(String id) => _box.get(id);

  @override
  Future<void> save(String id, T item) async => await _box.put(id, item);

  @override
  Future<void> delete(String id) async => await _box.delete(id);
}
