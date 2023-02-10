import 'package:flutter_test/flutter_test.dart';
import 'package:storage_engine/memory_box_adapter.dart';

import 'package:storage_engine/storage_engine.dart';

void main() async {
  const testCollectionKey = "testBox";
  await StorageEngine.registerBoxAdapter<String>(
    collectionKey: testCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final box = StorageEngine.getBox<String>(testCollectionKey);

  const key = "testKey";
  const value = "testValue";

  const key2 = "testKey2";
  const value2 = "testValue2";

  //write tests for put
  test('box put', () async {
    //clear box for next tests
    await box.clear();

    //-------------test put: key = val -> get key => val -------------
    await box.put(key, value);
    expect(await box.get(key), value);

    //-------------test put: key2 = val ->  get key => != val2 -------------
    await box.put(key2, value);
    expect(await box.get(key2), isNot(equals(value2)));

    //-------------test put: key2 = val2 ->  get key2 => val2 -------------
    //(test if put overwrites)
    await box.put(key2, value2);
    expect(await box.get(key2), value2);
  });

  //write tests for containsKey
  test('box containsKey', () async {
    //clear box for next tests
    await box.clear();

    //-------------test containsKey: key = val -> containsKey key => true -------------
    await box.put(key, value);
    expect(await box.containsKey(key), true);

    //-------------test containsKey:  containsKey randomKey => false -------------
    expect(await box.containsKey("aefjbglisbgabegosbgo"), false);
  });

  //write tests for getKeys
  test('box getKeys', () async {
    //clear box for next tests
    await box.clear();

    //-------------test getKeys: key = val -> getKeys => [key] -------------
    await box.put(key, value);
    await box.put(key2, value2);

    expect(await box.getKeys(), [key, key2]);
  });
}
