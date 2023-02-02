import 'package:storage_engine/update_enum.dart';

typedef UpdateCallback<T> = void Function(String key, UpdateAction action);

abstract class BoxAdapter<T> {
  BoxAdapter();

  late final String boxKey;
  final List<UpdateCallback> _listeners = [];

  Future<void> init(String boxKey);

  Future<bool> containsKey(String key);

  Future<T?> get(String key);

  Future<void> put(String key, T value);

  Future<void> putAll(Map<String, T> values);

  Future<void> remove(String key);

  Future<void> clear();

  Future<List<T>> getValues();

  Future<List<String>> getKeys();

  void notifyListeners(String key, UpdateAction action) {
    for (var listener in _listeners) {
      listener(key, action);
    }
  }

  void watch(UpdateCallback callback) {
    _listeners.add(callback);
  }
}