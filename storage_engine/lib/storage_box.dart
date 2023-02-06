import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/isolate_handler.dart';
import 'package:storage_engine/update_enum.dart';

class StorageBox<T> {
  late final BoxAdapter<T> _adapter;
  late final String _boxKey;

  late final Future<void> _waitForIsolateSetup;

  bool get _useIsolate => _adapter.runInIsolate;

  StorageBox.from(BoxAdapter<T> adapter, String boxKey) {
    _adapter = adapter;
    _boxKey = boxKey;

    if (_useIsolate) {
      Future<void> waitForIsolateSetup() async {
        await spawnIsolateIfNotRunning();
        await registerIsolateBox(boxKey: _boxKey, adapter: adapter);
      }

      _waitForIsolateSetup = waitForIsolateSetup();
    }
  }

  Future<bool> containsKey(String key) async {
    if (_useIsolate) {
      await _waitForIsolateSetup;
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
    if (_useIsolate) {
      print("isolate get");
      await _waitForIsolateSetup;
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
    if (_useIsolate) {
      print("isolate put");

      await _waitForIsolateSetup;
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
    if (_useIsolate) {
      await _waitForIsolateSetup;
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
    if (_useIsolate) {
      await _waitForIsolateSetup;
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
    //get keys to notify listeners
    final keys = await _adapter.getKeys();

    if (_useIsolate) {
      await _waitForIsolateSetup;
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
    if (_useIsolate) {
      await _waitForIsolateSetup;
      return await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.getValues,
      );
    } else {
      return await _adapter.getValues();
    }
  }

  Future<List<String>> getKeys() async {
    if (_useIsolate) {
      await _waitForIsolateSetup;
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
