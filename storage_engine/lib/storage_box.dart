import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/update_enum.dart';

class StorageBox<T> {
  late final BoxAdapter<T> _adapter;
  
  StorageBox.from(BoxAdapter<T> adapter) {
    _adapter = adapter;
  }

  Future<bool> containsKey(String key) => _adapter.containsKey(key);

  Future<T?> get(String key) => _adapter.get(key);

  Future<void> put(String key, T value) async {
    await _adapter.put(key, value);

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.set);
  }

  Future<void> putAll(Map<String, T> values) async {
    await _adapter.putAll(values);

    // notify listeners for each key
    for (var key in values.keys) {
      _adapter.notifyListeners(key, UpdateAction.set);
    }
  }

  Future<void> remove(String key) async {
    await _adapter.remove(key);

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.delete);
  }

  Future<void> clear() async {
    final keys = await _adapter.getKeys();
    await _adapter.clear();

    // notify listeners for each key
    for (var key in keys) {
      _adapter.notifyListeners(key, UpdateAction.delete);
    }
  }

  Future<List<T>> getValues() => _adapter.getValues();

  Future<List<String>> getKeys() => _adapter.getKeys();

  void watch(UpdateCallback callback) => _adapter.watch(callback);
}
