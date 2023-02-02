import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/update_enum.dart';

class StorageBox<T> {
  late final BoxAdapter<T> _adapter;
  StorageBox.from(BoxAdapter<T> adapter) {
    _adapter = adapter;
  }

  bool containsKey(String key) => _adapter.containsKey(key);

  T? get(String key) => _adapter.get(key);

  void put(String key, T value) {
    _adapter.put(key, value);

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.set);
  }

  void putAll(Map<String, T> values) {
    _adapter.putAll(values);

    // notify listeners for each key
    for (var key in values.keys) {
      _adapter.notifyListeners(key, UpdateAction.set);
    }
  }

  void remove(String key) {
    _adapter.remove(key);

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.delete);
  }

  void clear() {
    final keys = _adapter.getKeys();
    _adapter.clear();

    // notify listeners for each key
    for (var key in keys) {
      _adapter.notifyListeners(key, UpdateAction.delete);
    }
  }

  List<T> getValues() => _adapter.getValues();

  List<String> getKeys() => _adapter.getKeys();

  void watch(UpdateCallback callback) => _adapter.watch(callback);
}
