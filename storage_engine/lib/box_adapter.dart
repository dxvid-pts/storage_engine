import 'package:storage_engine/update_enum.dart';

typedef UpdateCallback<T> = void Function(String key, UpdateAction action);

abstract class BoxAdapter<T> {
  BoxAdapter();

  late final String boxKey;
  final List<UpdateCallback> _listeners = [];

  Future<void> init(String boxKey);

  bool containsKey(String key);

  T? get(String key);

  void put(String key, T value);

  void putAll(Map<String, T> values);

  void remove(String key);

  void clear();

  List<T> getValues();

  List<String> getKeys();

  void notifyListeners(String key, UpdateAction action) {
    for (var listener in _listeners) {
      listener(key, action);
    }
  }

  void watch(UpdateCallback callback) {
    _listeners.add(callback);
  }
}