import 'package:storage_engine/box_adapter.dart';

class MemoryBoxAdapter<T> extends BoxAdapter<T> {
  MemoryBoxAdapter();

  final Map<String, T> _items = {};

  @override
  T? get(String key) => _items[key]!;

  @override
  void clear() => _items.clear();

  @override
  List<T> getValues() => _items.values.toList();

  @override
  List<String> getKeys() => _items.keys.toList();

  @override
  void remove(String key) => _items.remove(key);

  @override
  void put(String key, T value) => _items[key] = value;

  @override
  bool containsKey(String key) => _items.containsKey(key);

  @override
  Future<void> init(String boxKey) async {}
  
  @override
  void putAll(Map<String, T> values) => _items.addAll(values);
}
