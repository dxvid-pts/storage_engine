import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/storage_box.dart';
import 'package:storage_engine/storage_engine.dart';

Future<void> testAdapterWithType<T>(
  BoxAdapter<T> adapter,
  T value1,
  T value2,
) async {
  final testCollectionKey = "${T.runtimeType}Box-${Random().nextInt(999999)}";
  StorageEngine.registerBoxAdapter<T>(
    collectionKey: testCollectionKey,
    version: 1,
    adapter: adapter,
  );

  final box = StorageEngine.getBox<T>(testCollectionKey);

  await boxAdapterTest<T>(box, value1, value2);
}

Future<void> testAdapter({
  required BoxAdapter<String> stringAdapter,
  required BoxAdapter<int> intAdapter,
  required BoxAdapter<double> doubleAdapter,
  required BoxAdapter<bool> boolAdapter,
  required BoxAdapter<Map<String, int>> mapAdapter,
  required BoxAdapter<List<String>> listAdapter,
  required BoxAdapter<Set<String>> setAdapter,
  required BoxAdapter<TestClass> classAdapter,
}) async {
  const class1 = TestClass(
    testString: "test",
    testInt: 1,
    testDouble: 1.0,
    testBool: true,
    testMap: {"test": 1},
    testList: ["test"],
    testSet: {"test"},
  );

  const class2 = TestClass(
    testString: "test2",
    testInt: 2,
    testDouble: 2.0,
    testBool: false,
    testMap: {"test": 2},
    testList: ["test2"],
    testSet: {"test2"},
  );

  await testAdapterWithType<String>(stringAdapter, "testValue", "testValue2");
  await testAdapterWithType<int>(intAdapter, 1, 2000);
  await testAdapterWithType<double>(doubleAdapter, 1.1, 2000.0);
  await testAdapterWithType<bool>(boolAdapter, true, false);
  await testAdapterWithType<Map<String, int>>(
      mapAdapter, {"test": 1}, {"test": 2});
  await testAdapterWithType<List<String>>(listAdapter, ["test"], ["test2"]);
  await testAdapterWithType<Set<String>>(setAdapter, {"test"}, {"test2"});
  await testAdapterWithType<TestClass>(classAdapter, class1, class2);
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
    expect(await box.getAll(), isEmpty);
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

  //write tests for getAll
  test('box getAll', () async {
    //clear box for next tests
    await box.clear();

    //-------------test getKeys: key = val -> getKeys => [key] -------------
    await box.put(key, value);
    await box.put(key2, value2);

    expect(await box.getAll(), {key: value, key2: value2});
  });

  //write tests for getAll pagination
  test('box getAll pagination', () async {
    //clear box for next tests
    await box.clear();

    //-------------test getKeys: key = val -> getKeys => [key] -------------
    final Map<String, T> expectedMap = {};
    for (int i = 0; i < 100; i++) {
      final testKey = "key$i";

      expectedMap[testKey] = value;
      await box.put(testKey, value);
    }

    expect(
      await box.getAll(
          pagination: const ListPaginationParams(page: 0, perPage: 10)),
      _sublistMap<T>(expectedMap, 0, 10),
    );

    expect(
      await box.getAll(
          pagination: const ListPaginationParams(page: 1, perPage: 10)),
      _sublistMap<T>(expectedMap, 10, 20),
    );

    expect(
      await box.getAll(
          pagination: const ListPaginationParams(page: 1, perPage: 30)),
      _sublistMap<T>(expectedMap, 30, 60),
    );

    //list only goes to 100, so this can only return 10 (90-100 instead of 90-120)
     expect(
      await box.getAll(
          pagination: const ListPaginationParams(page: 3, perPage: 30)),
      _sublistMap<T>(expectedMap, 90, 100),
    );
  });
}

Map<String, T> _sublistMap<T>(Map<String, T> map, int start, int end) {
  final keys = map.keys.toList();
  final values = map.values.toList();

  return Map.fromIterables(
    keys.sublist(start, end),
    values.sublist(start, end),
  );
}
