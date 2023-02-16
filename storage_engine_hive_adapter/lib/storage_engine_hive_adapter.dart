library storage_engine_hive_adapter;

import 'package:hive/hive.dart';
import 'package:storage_engine/box_adapter.dart';

class HiveBoxAdapter<T> extends BoxAdapter<T> {
  HiveBoxAdapter() : super(runInIsolate: true);

  @override
  Future<void> init(String boxKey) async {
    _box = await Hive.openBox<T>(boxKey);
  }

  late final Box<T> _box;

  @override
  Future<T?> get(String key) async => _box.get(key);

  @override
  Future<void> clear() => _box.clear();

  @override
  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) async {
    final Map<String, T> map = _box.toMap().cast();

    if (pagination == null) {
      return map;
    } else {
      final start = (pagination.page - 1) * pagination.perPage;
      final end = start + pagination.perPage;
      return Map.fromIterables(
        _box.keys.cast<String>().toList().sublist(start, end),
        _box.values.toList().sublist(start, end),
      );
    }
  }

  @override
  Future<void> remove(String key) async => _box.delete(key);

  @override
  Future<void> put(String key, T value) => _box.put(key, value);

  @override
  Future<bool> containsKey(String key) async => _box.containsKey(key);

  @override
  Future<void> putAll(Map<String, T> values) => _box.putAll(values);
}
