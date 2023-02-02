library storage_engine_hive_adapter;

import 'package:hive/hive.dart';
import 'package:storage_engine/box_adapter.dart';

class HiveBoxAdapter<T> extends BoxAdapter<T> {
  HiveBoxAdapter();

  @override
  Future<void> init(String boxKey) async {
    _box = await Hive.openBox<T>(boxKey);
  }

  late final Box<T> _box;

  @override
  T? get(String key) => _box.get(key);

  @override
  void clear() => _box.clear();

  @override
  List<T> getValues() => _box.values.toList();

  @override
  List<String> getKeys() => [..._box.keys];

  @override
  void remove(String key) => _box.delete(key);

  @override
  void put(String key, T value) => _box.put(key, value);

  @override
  bool containsKey(String key) => _box.containsKey(key);

  @override
  void putAll(Map<String, T> values) => _box.putAll(values);
}
