import 'package:storage_engine/memory_box_adapter.dart';

import 'check_adapter.dart';

void main() async {
  //Test MemoryBoxAdapter
  await testAdapter(
    stringAdapter: MemoryBoxAdapter<String>(),
    intAdapter: MemoryBoxAdapter<int>(),
    doubleAdapter: MemoryBoxAdapter<double>(),
    boolAdapter: MemoryBoxAdapter<bool>(),
    mapAdapter: MemoryBoxAdapter<Map<String, int>>(),
    listAdapter: MemoryBoxAdapter<List<String>>(),
    setAdapter: MemoryBoxAdapter<Set<String>>(),
    classAdapter: MemoryBoxAdapter<TestClass>(),
  );
}
