import 'dart:async';

import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/isolate_handler.dart';
import 'package:storage_engine/update_enum.dart';

class StorageBox<T> {
  late final BoxAdapter<T> _adapter;
  late final String _boxKey;

  bool get _useIsolate => _adapter.runInIsolate;

  late final Future<void> _waitToBeInitialized;

  //allways prefers cache over storage!
  //if something is in the cache, the storage backend is not contacted
  final Map<String, T> _cache = {};

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
    //always prefer cache over storage
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

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

  final Map<String, DateTime> _latencyExecutionTime = {};

  Future<void> put(String key, T value, {Duration? latency}) async {
    //print("debugging: put request");
    Future<void> internalPutAndCacheRemove(T v) async {
      //print("debugging: final put");
      //remove key from cache
      _cache.remove(key);

      await _waitToBeInitialized;

      if (_useIsolate) {
        await runBoxFunctionInIsolate(
          collectionKey: _boxKey,
          type: BoxFunctionType.put,
          key: key,
          value: v,
        );
      } else {
        await _adapter.put(key, v);
      }
    }

    if (latency == null) {
      //if latency is null, put immediately
      await internalPutAndCacheRemove(value);
    } else {
      //if latency is not null, put after latency
      //this allows to save server requests if you expect a lot of changes in a short time
      //changes are served immediately from the cache but are synced to the storage backend after latency

      //update cache
      _cache[key] = value;

      final bool alreadyInLatencyQueue = _latencyExecutionTime.containsKey(key);

      //set latency end time. If latency is already set this increases the latency with the new latency
      _latencyExecutionTime[key] = DateTime.now().add(latency);

      //check if latency is already running and if so return so that the function is only executed once
      if (!alreadyInLatencyQueue) {
        //update ingredient amount when latency is over
        unawaited(
          Future.delayed(latency, () async {
            //check if latency is was changed and adjust accordingly
            while (_latencyExecutionTime[key]!.isAfter(DateTime.now())) {
              //if latency changed wait for new latency to end
              await Future.delayed(
                  _latencyExecutionTime[key]!.difference(DateTime.now()));
              //wait extra time to avoid an unneccessary loop run
              await Future.delayed(const Duration(milliseconds: 10));
            }

            //remove latency data
            _latencyExecutionTime.remove(key);

            //check if cache still contains key
            //if not, return as a put call later in time already updated the storage backend
            final valueFromCache = _cache[key];
            if (valueFromCache == null) return;

            //this also removes the key from the cache
            await internalPutAndCacheRemove(valueFromCache);
          }),
        );
      }
    }

    // notify listeners
    _adapter.notifyListeners(key, value, UpdateAction.put);
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
      _adapter.notifyListeners(key, values[key]!, UpdateAction.put);
    }
  }

  Future<void> remove(String key) async {
    //get value to notify listeners if there are listeners
    T? value;
    if (_adapter.listeners.isNotEmpty) {
      value = (await _adapter.get(key)) ?? _cache[key];

      //as we confirmed that the key does not exist, we can return. No need to remove
      if (value == null) {
        return;
      }
    }

    //if key is in cache, remove it
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

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

    // notify listeners for each key if there are listeners
    if (_adapter.listeners.isNotEmpty) {
      _adapter.notifyListeners(key, value!, UpdateAction.delete);
    }
  }

  Future<void> clear() async {
    //TODO: Implement pagination to avoid loading all keys from large databases into memory

    //temporarily keep cache to notify listeners later
    final Map<String, T> _valueCache = _cache;

    //clear cache
    _cache.clear();

    await _waitToBeInitialized;

    //only get update values if there are listeners to save resources
    Map<String, T> values = {};
    if (_adapter.listeners.isNotEmpty) {
      //get keys to notify listeners
      values = {
        ...(await _adapter.getAll()),
        ..._valueCache,
      };
    }

    if (_useIsolate) {
      await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.clear,
      );
    } else {
      await _adapter.clear();
    }

    // notify listeners for each key if there are listeners
    if (_adapter.listeners.isNotEmpty) {
      for (String key in values.keys) {
        _adapter.notifyListeners(key, values[key]!, UpdateAction.delete);
      }
    }
  }

  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) async {
    await _waitToBeInitialized;

    final Map<String, T> values;

    if (_useIsolate) {
      values = await runBoxFunctionInIsolate(
        collectionKey: _boxKey,
        type: BoxFunctionType.getAll,
        value: pagination,
      );
    } else {
      values = await _adapter.getAll(pagination: pagination);
    }

    //always prefer cache over storage
    //check if key is in cache and overwrite storage value
    for (final cacheKey in _cache.keys) {
      values[cacheKey] = _cache[cacheKey]!;
    }

    return values;
  }

  void watch(UpdateCallback<T> callback) => _adapter.watch(callback);
}
