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
  }) : super(runInIsolate: true) {
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
      //clear list cache
      _listCache.clear();

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
  Future<List<T>> getValues({ListPaginationParams? pagination}) async {
    final list = await _getFullList(pagination);

    return list
        .map((e) => _convertToType(e))
        .where((e) => e != null)
        .cast<T>()
        .toList();
  }

  @override
  Future<List<String>> getKeys({ListPaginationParams? pagination}) async {
    return (await _getFullList(pagination)).map((e) => e.id).toList();
  }

  //cache list to avoid multiple requests (keys/values are usually called together)
  //page (-1) is used to get all records
  final Map<int, List<RecordModel>> _listCache = {};
  Future<List<RecordModel>> _getFullList(
    ListPaginationParams? pagination,
  ) async {
    if (_listCache.containsKey(pagination?.page ?? -1)) {
      return _listCache[pagination?.page ?? -1]!;
    } else {
      final List<RecordModel> list = pagination == null
          ? await _collection.getFullList()
          : (await _collection.getList(
                  page: pagination.page, perPage: pagination.perPage))
              .items;

      //cache list
      _listCache[pagination?.page ?? -1] = list;

      return list;
    }
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
