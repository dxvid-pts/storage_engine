import 'package:storage_engine/update_enum.dart';

typedef UpdateCallback<T> = void Function(String key, T value, UpdateAction action);

class ListPaginationParams {
  final int page;
  final int perPage;

  const ListPaginationParams({this.page = 1, this.perPage = 30});
}

abstract class BoxAdapter<T> {
  final bool runInIsolate;

  BoxAdapter({this.runInIsolate = true});

  final List<UpdateCallback<T>> listeners = [];

  Future<void> init(String boxKey);

  Future<bool> containsKey(String key);

  Future<T?> get(String key);

  Future<void> put(String key, T value);

  Future<void> putAll(Map<String, T> values);

  Future<void> remove(String key);

  Future<void> clear();

  Future<Map<String, T>> getAll({ListPaginationParams? pagination});

  void notifyListeners(String key, T value, UpdateAction action) {
    for (var listener in listeners) {
      listener(key, value, action);
    }
  }

  //TODO: unregister listener
  void watch(UpdateCallback<T> callback) {
    listeners.add(callback);
  }
}
