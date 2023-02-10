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

  //write tests for put
  test('box put', () async {
    //-------------test put: key = val -> get key => val -------------
    const key = "testKey";
    const value = "testValue";

    await box.put(key, value);
    expect(await box.get(key), value);

    //-------------test put: key2 = val ->  get key => != val2 -------------
    const key2 = "testKey2";
    const value2 = "testValue2";

    await box.put(key2, value);
    expect(await box.get(key2), isNot(equals(value2)));

    //-------------test put: key2 = val2 ->  get key2 => val2 ------------- 
    //(test if put overwrites)
    await box.put(key2, value2);
    expect(await box.get(key2), value2);
  });

  //write tests for containsKey
  test('box containsKey', () async {
    //-------------test containsKey: key = val -> containsKey key => true -------------
    const key = "testKey";
    const value = "testValue";

    await box.put(key, value);
    expect(await box.containsKey(key), true);

    //-------------test containsKey:  containsKey randomKey => false -------------
    expect(await box.containsKey("aefjbglisbgabegosbgo"), false);
  });
}
