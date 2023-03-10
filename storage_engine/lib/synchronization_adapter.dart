import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/update_enum.dart';

class SynchronizationAdapter<T> extends BoxAdapter<T> {
  late final BoxAdapter<T> _primaryRawAdapter;
  late final BoxAdapter<T> _secondaryRawAdapter;

  SynchronizationAdapter({
    required BoxAdapter<T> primaryAdapter,
    required BoxAdapter<T> secondaryAdapter,
  }) : super(runInIsolate: false) {
    _primaryRawAdapter = primaryAdapter;
    _secondaryRawAdapter = secondaryAdapter;
  }

  @override
  Future<void> init(String boxKey) {
    return Future.wait([
      _primaryRawAdapter.init("$boxKey--one")
        ..then((_) {
          //listen for changes in the primary adapter and update the secondary adapter
          _primaryRawAdapter.watch((key, value, action) async {
            if (action == UpdateAction.put) {
              await _secondaryRawAdapter.put(key, value);
            } else if (action == UpdateAction.delete) {
              await _secondaryRawAdapter.remove(key);
            }

            //notify listeners of the sync adapter
            notifyListeners(key, value, action);
          });
        }),
      _secondaryRawAdapter.init("$boxKey--two")
        ..then((_) {
          //listen for changes in the secondary adapter and update the primary adapter
          _secondaryRawAdapter.watch((key, value, action) async {
            if (action == UpdateAction.put) {
              await _primaryRawAdapter.put(key, value);
            } else if (action == UpdateAction.delete) {
              await _primaryRawAdapter.remove(key);
            }

            //notify listeners of the sync adapter
            notifyListeners(key, value, action);
          });
        }),
    ]);
  }

  @override
  Future<void> clear() => Future.wait([
        _primaryRawAdapter.clear(),
        _secondaryRawAdapter.clear(),
      ]);

  @override
  Future<bool> containsKey(String key) => _primaryRawAdapter.containsKey(key);

  @override
  Future<T?> get(String key) => _primaryRawAdapter.get(key);

  @override
  Future<Map<String, T>> getAll({ListPaginationParams? pagination}) =>
      _primaryRawAdapter.getAll(pagination: pagination);

  @override
  Future<void> put(String key, T value) => Future.wait([
        _primaryRawAdapter.put(key, value),
        _secondaryRawAdapter.put(key, value),
      ]);

  @override
  Future<void> putAll(Map<String, T> values) => Future.wait([
        _primaryRawAdapter.putAll(values),
        _secondaryRawAdapter.putAll(values),
      ]);

  @override
  Future<void> remove(String key) => Future.wait([
        _primaryRawAdapter.remove(key),
        _secondaryRawAdapter.remove(key),
      ]);
}
