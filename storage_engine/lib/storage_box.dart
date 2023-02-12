import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/isolate_handler.dart';
import 'package:storage_engine/update_enum.dart';

class StorageBox<T> {
  late final BoxAdapter<T> _adapter;
  late final String _boxKey;

  bool get _useIsolate => _adapter.runInIsolate;

  late final Future<void> _waitToBeInitialized;

  StorageBox.from(BoxAdapter<T> adapter, String boxKey) {
    _adapter = adapter;
    _boxKey = boxKey;

    Future<void> waitToBeInitialized() async {
      if (_useIsolate) {
        await spawnIsolateIfNotRunning();
        await registerIsolateBox(boxKey: _boxKey, adapter: adapter);

        //init box with box key when running in isolate
        await runBoxFunctionInIsolate(
          collectionKey: _boxKey,
          type: BoxFunctionType.init,
          key: _boxKey,
        );
      } else {
        //init box in non isolate environments
        await adapter.init(boxKey);
      }
    }

    _waitToBeInitialized = waitToBeInitialized();
  }

  Future<bool> containsKey(String key) async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      return await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.containsKey,
        key: key,
      );
    } else {
      return await _adapter.containsKey(key);
    }
  }

  Future<T?> get(String key) async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      print("isolate get");
      return await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.get,
        key: key,
      );
    } else {
      return await _adapter.get(key);
    }
  }

  Future<void> put(String key, T value) async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      print("isolate put");
      await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.put,
        key: key,
        value: value,
      );
    } else {
      await _adapter.put(key, value);
    }

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.put);
  }

  Future<void> putAll(Map<String, T> values) async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      //putAll uses value instead of key
      await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.putAll,
        value: values,
      );
    } else {
      await _adapter.putAll(values);
    }

    // notify listeners for each key
    for (var key in values.keys) {
      _adapter.notifyListeners(key, UpdateAction.put);
    }
  }

  Future<void> remove(String key) async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.delete,
        key: key,
      );
    } else {
      await _adapter.remove(key);
    }

    // notify listeners
    _adapter.notifyListeners(key, UpdateAction.delete);
  }

  Future<void> clear() async {
    await _waitToBeInitialized;

    //get keys to notify listeners
    final keys = await _adapter.getKeys();

    if (_useIsolate) {
      await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.clear,
      );
    } else {
      await _adapter.clear();
    }

    // notify listeners for each key
    for (var key in keys) {
      _adapter.notifyListeners(key, UpdateAction.delete);
    }
  }

  Future<List<T>> getValues() async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      return await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.getValues,
      );
    } else {
      return await _adapter.getValues();
    }
  }

  Future<List<String>> getKeys() async {
    await _waitToBeInitialized;

    if (_useIsolate) {
      return await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.getKeys,
      );
    } else {
      return await _adapter.getKeys();
    }
  }

  void watch(UpdateCallback callback) => _adapter.watch(callback);
}
