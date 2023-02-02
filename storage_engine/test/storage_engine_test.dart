import 'package:flutter_test/flutter_test.dart';
import 'package:storage_engine/memory_box_adapter.dart';

import 'package:storage_engine/storage_engine.dart';

void main() {
  test('adds one to input values', () {
    // const adapter = MemoryAdapter(id: 'memory-v1');
    //StorageEngine.registerAdapter(adapter);

    // adapt<SampleClass>((object) => [object.name, object.age, object.height]);

    //general adapter -> class to map
    //specific adapter -> map to db
    //example: memory adapter -> for each key value pair
    StorageEngine.registerBoxAdapter('ingredients', MemoryBoxAdapter<String>());

    final box = StorageEngine.getBox<String>('ingredients');
    box.put('key', 'value');
    print(box.get("key"));
    /* final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);*/
  });
}
