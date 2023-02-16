import 'dart:math';

import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/storage_box.dart';
import 'package:storage_engine/storage_engine.dart';
import 'package:storage_engine/update_enum.dart';
import 'package:test/test.dart';

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

  await Future.wait([
    testAdapterWithType<String>(stringAdapter, "testValue", "testValue2"),
    testAdapterWithType<int>(intAdapter, 1, 2000),
    testAdapterWithType<double>(doubleAdapter, 1.1, 2000.0),
    testAdapterWithType<bool>(boolAdapter, true, false),
    testAdapterWithType<Map<String, int>>(mapAdapter, {"test": 1}, {"test": 2}),
    testAdapterWithType<List<String>>(listAdapter, ["test"], ["test2"]),
    testAdapterWithType<Set<String>>(setAdapter, {"test"}, {"test2"}),
    testAdapterWithType<TestClass>(classAdapter, class1, class2),
  ]);
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

  //write tests for put with latency
  test('box latency put', () async {
    //clear box for next tests
    await box.clear();

    //-------------test getKeys: key = val -> getKeys => [key] -------------
    await box.put(key, value, latency: const Duration(milliseconds: 100));
    await box.put(key2, value2);

    //key should be in box as it will be cached
    expect(await box.getAll(), {key: value, key2: value2});

    await Future.delayed(const Duration(milliseconds: 200));

    expect(await box.getAll(), {key: value, key2: value2});
  });

  //write tests for watch
  test('box watch', () async {
    //clear box for next tests
    await box.clear();

    //-------------test getKeys: key = val -> getKeys => [key] -------------
    // await box.put(key, value, latency: const Duration(milliseconds: 100));
    //expect put event after put
    await _expectNext<T>(
      box: box,
      expectedKey: key,
      expectedAction: UpdateAction.put,
      function: () => box.put(key, value),
    );

    //expect put event after update with same value
    await _expectNext<T>(
      box: box,
      expectedKey: key,
      expectedAction: UpdateAction.put,
      function: () => box.put(key, value),
    );

    //expect put event after update with different value
    await _expectNext<T>(
      box: box,
      expectedKey: key,
      expectedAction: UpdateAction.put,
      function: () => box.put(key, value2),
    );

    //expect delete event after delete
    await _expectNext<T>(
      box: box,
      expectedKey: key,
      expectedAction: UpdateAction.delete,
      function: () async {
        await box.remove(key);
      },
    );

    //expect put events after put multiple
    await _expectNextList<T>(
      box: box,
      expectedKeys: [key, key2],
      expectedActions: [UpdateAction.put, UpdateAction.put],
      function: () async {
        await box.putAll({key: value, key2: value2});
      },
    );

    //expect delete events after clear multiple
    await _expectNextList<T>(
      box: box,
      expectedKeys: [key, key2],
      expectedActions: [UpdateAction.delete, UpdateAction.delete],
      function: () async {
        await box.clear();
      },
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

Future<void> _expectNext<T>({
  required StorageBox<T> box,
  required String expectedKey,
  required UpdateAction expectedAction,
  required Function function,
}) =>
    _expectNextList(
        box: box,
        expectedKeys: [expectedKey],
        expectedActions: [expectedAction],
        function: function);

Future<void> _expectNextList<T>({
  required StorageBox<T> box,
  required List<String> expectedKeys,
  required List<UpdateAction> expectedActions,
  required Function function,
}) async {
  final List<String> receivedKeys = [];
  final List<UpdateAction> receivedActions = [];

  //listen to the box
  box.watch((key, action) {
    receivedKeys.add(key);
    receivedActions.add(action);
  });

  //run function
  await function();

  //wait 5ms for the events to be received
  await Future.delayed(const Duration(milliseconds: 100));

  //check if the event was received
  _checkLists(receivedKeys, expectedKeys);
  _checkLists(receivedActions, expectedActions);
}

void _checkLists(List l1, List l2) {
  expect(l1.length, l2.length);
  expect(l1.runtimeType, l2.runtimeType);
  for (int i = 0; i < l1.length; i++) {
    expect(l1[i], l2[i]);
  }
}
