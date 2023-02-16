library storage_engine;

import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/memory_box_adapter.dart';
import 'package:storage_engine/storage_box.dart';

const String _legacyBoxKey =
    '96utq2@9zxwP6R4ZL6tS7Fq^HCU^y&arUx5uwS^wssPLda*zaNesWW@^PSdFDvfZK%5oz';
const String _sepereator = '__engine__';

class StorageEngine {
  static final Map<String, StorageBox> _storageBoxes = {};
  static final BoxAdapter<bool> _legacyBoxes = MemoryBoxAdapter<bool>()
    ..init(_legacyBoxKey);

  static void registerBoxAdapter<T>({
    required String collectionKey,
    required int version,
    required BoxAdapter<T> adapter,
  }) {
    //generate box key from collection key and version
    final boxKey = _getBoxKey(collectionKey, version);

    //add box with collection key to map
    _storageBoxes[collectionKey] = StorageBox<T>.from(adapter, boxKey);

    //log box key and mark available data to true, so we can migrate data later
    _legacyBoxes.put(boxKey, true);
  }

  static Future<void> migrateBoxFromAdapterIfExist<T>({
    required String collectionKey,
    required int oldVersion,
    required BoxAdapter<T> oldAdapter,
  }) async {
    final boxKey = _getBoxKey(collectionKey, oldVersion);

    //check if box has data left -> migrate
    if (await _legacyBoxes.containsKey(boxKey) &&
        await _legacyBoxes.get(boxKey) == true) {
      //get all data from old adapter
      //TODO: pagination
      final map = await oldAdapter.getAll();

      //get current box from collection key
      final currentBox = getBox<T>(collectionKey);
      await currentBox.putAll(map);

      //mark old box as migrated
      await _legacyBoxes.put(boxKey, false);
    }
  }

  static StorageBox<T> getBox<T>(String key) {
    assert(_storageBoxes.containsKey(key), 'Box \'$key\' does not exist');
    return _storageBoxes[key]! as StorageBox<T>;
  }

  static String _getBoxKey(String key, int version) =>
      "$key$_sepereator$version";
}
