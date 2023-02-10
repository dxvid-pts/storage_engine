import 'package:flutter_test/flutter_test.dart';
import 'package:storage_engine/memory_box_adapter.dart';
import 'package:storage_engine/storage_box.dart';

import 'package:storage_engine/storage_engine.dart';

void main() async {
  //-----------------string box tests-----------------
  const testStringCollectionKey = "stringBox";
  await StorageEngine.registerBoxAdapter<String>(
    collectionKey: testStringCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final stringBox = StorageEngine.getBox<String>(testStringCollectionKey);

  //-----------------int box tests-----------------
  const testIntCollectionKey = "intBox";
  await StorageEngine.registerBoxAdapter<int>(
    collectionKey: testIntCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final intBox = StorageEngine.getBox<int>(testIntCollectionKey);

  //-----------------double box tests-----------------
  const doubleStringCollectionKey = "doubleBox";
  await StorageEngine.registerBoxAdapter<double>(
    collectionKey: doubleStringCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final doubleBox = StorageEngine.getBox<double>(doubleStringCollectionKey);

  //-----------------bool box tests-----------------
  const testBoolCollectionKey = "boolBox";
  await StorageEngine.registerBoxAdapter<bool>(
    collectionKey: testBoolCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final boolBox = StorageEngine.getBox<bool>(testBoolCollectionKey);

  //-----------------map box tests-----------------
  const testMapCollectionKey = "mapBox";
  await StorageEngine.registerBoxAdapter<Map<String, int>>(
    collectionKey: testMapCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final mapBox = StorageEngine.getBox<Map<String, int>>(testMapCollectionKey);

  //-----------------list box tests-----------------
  const testListCollectionKey = "listBox";
  await StorageEngine.registerBoxAdapter<List<String>>(
    collectionKey: testListCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final listBox = StorageEngine.getBox<List<String>>(testListCollectionKey);

  //-----------------set box tests-----------------
  const testSetCollectionKey = "setBox";
  await StorageEngine.registerBoxAdapter<Set<String>>(
    collectionKey: testSetCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final setBox = StorageEngine.getBox<Set<String>>(testSetCollectionKey);

  //-----------------custom class box tests-----------------
  const testClassCollectionKey = "classBox";
  await StorageEngine.registerBoxAdapter<TestClass>(
    collectionKey: testClassCollectionKey,
    version: 1,
    adapter: MemoryBoxAdapter(),
  );

  final classBox = StorageEngine.getBox<TestClass>(testClassCollectionKey);

  //-----------------run tests-----------------

  await boxAdapterTest<String>(stringBox, "testValue", "testValue2");
  await boxAdapterTest<int>(intBox, 1, 2000);
  await boxAdapterTest<double>(doubleBox, 1.0, 2000.0);
  await boxAdapterTest<bool>(boolBox, true, false);
  await boxAdapterTest<Map<String, int>>(mapBox, {"test": 1}, {"test": 2});
  await boxAdapterTest<List<String>>(listBox, ["test"], ["test2"]);
  await boxAdapterTest<Set<String>>(setBox, {"test"}, {"test2"});
  await boxAdapterTest<TestClass>(
    classBox,
    const TestClass(
      testString: "test",
      testInt: 1,
      testDouble: 1.0,
      testBool: true,
      testMap: {"test": 1},
      testList: ["test"],
      testSet: {"test"},
    ),
    const TestClass(
      testString: "test2",
      testInt: 2,
      testDouble: 2.0,
      testBool: false,
      testMap: {"test": 2},
      testList: ["test2"],
      testSet: {"test2"},
    ),
  );
}

class TestClass {
  final String testString;
  final int testInt;
  final double testDouble;
  final bool testBool;
  final Map<String, int> testMap;
  final List<String> testList;
  final Set<String> testSet;

  const TestClass({
    required this.testString,
    required this.testInt,
    required this.testDouble,
    required this.testBool,
    required this.testMap,
    required this.testList,
    required this.testSet,
  });
}

Future<void> boxAdapterTest<T>(StorageBox<T> box, T value, T value2) async {
  const key = "testKey";
  const key2 = "testKey2";

  //as the memory box adapter is used, the box should be empty on start
  test('test empty on start', () async {
    expect(await box.getKeys(), []);
  });

  //write tests for clear
  test('box clear', () async {
    //-------------test clear: key = val -> get key => null -------------
    await box.put(key, value);
    expect(await box.get(key), value);

    await box.clear();
    expect(await box.get(key), null);
  });

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
