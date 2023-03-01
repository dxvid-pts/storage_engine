library storage_engine_hive_adapter;

import 'package:hive/hive.dart';
import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/utils.dart';

class HiveBoxAdapter<T> extends BoxAdapter<T> {
  HiveBoxAdapter({
    required this.path,
    this.adapters = const {},
  }) : super(runInIsolate: true);

  final String path;
  Set<TypeAdapter<T>> adapters;

  @override
  Future<void> init(String boxKey) async {
    print(path);
    //TODO is web
    Hive.init(path);

    for (final adapter in adapters) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    _box = await Hive.openBox<T>(boxKey);
  }

  late final Box<T> _box;

  @override
  Future<T?> get(String key) async => _box.get(key);

  @override
  Future<void> clear() => _box.clear();

  @override
  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) async {
    return getPaginatedListFromCache<T>(
      cache: _box.toMap().cast(),
      pagination: pagination,
    );
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
