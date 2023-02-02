import 'package:storage_engine/box_adapter.dart';

class MemoryBoxAdapter<T> extends BoxAdapter<T> {
  MemoryBoxAdapter();

  final Map<String, T> _items = {};

  @override
  Future<T?> get(String key) async => _items[key]!;

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<List<T>> getValues() async => _items.values.toList();

  @override
  Future<List<String>> getKeys() async => _items.keys.toList();

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
