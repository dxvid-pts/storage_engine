import 'package:flutter_test/flutter_test.dart';
import 'package:storage_engine/storage_engine.dart';

import 'package:storage_engine_hive_adapter/storage_engine_hive_adapter.dart';

void main() {
  test('adds one to input values', () async {
    final box = StorageEngine.registerBoxAdapter<List<bool>>(
      collectionKey: "boollist",
      version: 1,
      adapter: HiveBoxAdapter(
        path: path(),
        adapters: {},
      ),
    );

    box.put("a", [true]);
    final a = await box.get("a");
    expect(a, [true]);
  });
}

Future<String> path() async {
  return "";
}
