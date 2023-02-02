library storage_engine;

import 'package:flutter/foundation.dart';
import 'package:storage_engine/box_adapter.dart';

class StorageEngine {
  static final Map<String, BoxAdapter> _boxes = {};

  static void registerBoxAdapter(String key, BoxAdapter adapter) {
    _boxes[key] = adapter;
  }

  static void migrateBoxFromAdapterIfExist(String key, BoxAdapter oldAdapter) {
    debugPrint('migrateFromIfExist');
  }

  static BoxAdapter<T> getBox<T>(String key) {
    assert(_boxes.containsKey(key), 'Box \'$key\' does not exist');
    return _boxes[key]! as BoxAdapter<T>;
  }
}