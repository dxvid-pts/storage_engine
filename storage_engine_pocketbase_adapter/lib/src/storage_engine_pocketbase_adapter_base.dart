library storage_engine_hive_adapter;

import 'package:pocketbase/pocketbase.dart';
import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/update_enum.dart';

typedef Json = Map<String, dynamic>;

class PocketbaseBoxAdapter<T> extends BoxAdapter<T> {
  late final PocketBase _pb;
  late final RecordService _collection;
  late final T? Function(RecordModel) _convertToType;
  late final Json Function(T) _convertToRecordModel;

  PocketbaseBoxAdapter({
    required PocketBase pb,
    required T? Function(RecordModel) convertToType,
    required Json Function(T) convertToRecordModel,
  }) : super(runInIsolate: false) {
    _pb = pb;
    _convertToType = convertToType;
    _convertToRecordModel = convertToRecordModel;
  }

  @override
  Future<void> init(String boxKey) async {
    //_box = await Hive.openBox<T>(boxKey);
    _collection = _pb.collection(boxKey);

    // watch for changes
    _collection.subscribe('*', (RecordSubscriptionEvent e) {
      if (e.action == "delete") {
        //notify delete
        notifyListeners(e.record!.id, UpdateAction.delete);
      } else {
        //notify put
        notifyListeners(e.record!.id, UpdateAction.put);
      }
    });
  }

  @override
  Future<T?> get(String key) async {
    final record = await _collection.getOne(key);
    return _convertToType(record);
  }

  @override
  Future<void> clear() async {
    _collection.delete('*');
    /*for (String key in await getKeys()) {
      await remove(key);
    }*/
  }

  @override
  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) async {
     final List<RecordModel> list = pagination == null
          ? await _collection.getFullList()
          : (await _collection.getList(
                  page: pagination.page, perPage: pagination.perPage))
              .items;

    return Map.fromEntries(
      list.map((e) => MapEntry(e.id, _convertToType(e)!)),
    );
  }

  @override
  Future<void> remove(String key) async {
    await _collection.delete(key);
  }

  @override
  Future<void> put(String key, T value) async {
    //try to update first as it is more common
    //if it fails (not existant), create
    try {
      await _collection.update(key, body: _convertToRecordModel(value));
    } catch (e) {
      await _collection.create(
        body: <String, dynamic>{
          ..._convertToRecordModel(value),
          'id': key,
        },
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    return await get(key) != null;
  }

  @override
  Future<void> putAll(Map<String, T> values) async {
    for (var entry in values.entries) {
      await put(entry.key, entry.value);
    }
  }
}
