library storage_engine;

import 'package:flutter/foundation.dart';
import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/memory_box_adapter.dart';

const String _legacyBoxKey =
    '96utq2@9zxwP6R4ZL6tS7Fq^HCU^y&arUx5uwS^wssPLda*zaNesWW@^PSdFDvfZK%5oz';
const String _sepereator = '--6tS7Fq^HCU^y&arUx5uw--';

class StorageEngine {
  static final Map<String, BoxAdapter> _boxes = {};
  static final BoxAdapter<bool> _legacyBoxes = MemoryBoxAdapter<bool>()
    ..init(_legacyBoxKey);

  static Future<void> registerBoxAdapter({
    required String collectionKey,
    required int version,
    required BoxAdapter adapter,
  }) async {
    //add box with collection key to map
    _boxes[collectionKey] = adapter;

    //generate box key from collection key and version
    final boxKey = _getBoxKey(collectionKey, version);

    //log box key and mark available data to true, so we can migrate data later
    _legacyBoxes.put(boxKey, true);

    //init box with box key
    await adapter.init(boxKey);
  }

  static void migrateBoxFromAdapterIfExist<T>({
    required String collectionKey,
    required int oldVersion,
    required BoxAdapter<T> oldAdapter,
  }) {
    final boxKey = _getBoxKey(collectionKey, oldVersion);

    print(_legacyBoxes.getKeys());

    //check if box has data left -> migrate
    if (_legacyBoxes.containsKey(boxKey) && _legacyBoxes.get(boxKey)! == true) {
      //get all data from old adapter
      final map = Map<String, T>.fromIterables(
          oldAdapter.getKeys(), oldAdapter.getValues());

      //get current box from collection key
      final currentBox = getBox<T>(collectionKey);
      currentBox.putAll(map);

      //mark old box as migrated
      _legacyBoxes.put(boxKey, false);
    }
  }

  static BoxAdapter<T> getBox<T>(String key) {
    assert(_boxes.containsKey(key), 'Box \'$key\' does not exist');
    return _boxes[key]! as BoxAdapter<T>;
  }

  static String _getBoxKey(String key, int version) =>
      "$key$_sepereator$version";
}
