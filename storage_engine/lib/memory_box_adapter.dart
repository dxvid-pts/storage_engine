import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/utils.dart';

class MemoryBoxAdapter<T> extends BoxAdapter<T> {
  MemoryBoxAdapter() : super(runInIsolate: false);

  final Map<String, T> _items = {};

  @override
  Future<T?> get(String key) async => _items[key];

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) async {
    return getPaginatedListFromCache<T>(
      cache: _items,
      pagination: pagination,
    );
  }

  @override
  Future<void> remove(String key) async => _items.remove(key);

  @override
  Future<void> put(String key, T value) async => _items[key] = value;

  @override
  Future<bool> containsKey(String key) async => _items.containsKey(key);

  @override
  Future<void> init(String boxKey) async {}

  @override
  Future<void> putAll(Map<String, T> values) async => _items.addAll(values);
}
