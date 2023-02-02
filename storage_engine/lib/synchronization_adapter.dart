import 'package:storage_engine/box_adapter.dart';
import 'package:storage_engine/update_enum.dart';

class SynchronizationAdapter<T> extends BoxAdapter<T> {
  late final BoxAdapter<T> _primaryRawAdapter;
  late final BoxAdapter<T> _secondaryRawAdapter;

  SynchronizationAdapter(
      {required BoxAdapter<T> primaryAdapter,
      required BoxAdapter<T> secondaryAdapter}) {
    _primaryRawAdapter = primaryAdapter;
    _secondaryRawAdapter = secondaryAdapter;
  }

  @override
  Future<void> init(String boxKey) {
    return Future.wait([
      _primaryRawAdapter.init("$boxKey--one")
        ..then((_) {
          //listen for changes in the primary adapter and update the secondary adapter
          _primaryRawAdapter.watch((key, action) {
            if (action == UpdateAction.set || action == UpdateAction.update) {
              _secondaryRawAdapter.put(key, _primaryRawAdapter.get(key)!);
            } else if (action == UpdateAction.delete) {
              _secondaryRawAdapter.remove(key);
            }

            //notify listeners of the sync adapter
            notifyListeners(key, action);
          });
        }),
      _secondaryRawAdapter.init("$boxKey--two")
        ..then((_) {
          //listen for changes in the secondary adapter and update the primary adapter
          _secondaryRawAdapter.watch((key, action) {
            if (action == UpdateAction.set || action == UpdateAction.update) {
              _primaryRawAdapter.put(key, _secondaryRawAdapter.get(key)!);
            } else if (action == UpdateAction.delete) {
              _primaryRawAdapter.remove(key);
            }

            //notify listeners of the sync adapter
            notifyListeners(key, action);
          });
        }),
    ]);
  }

  @override
  void clear() {
    _primaryRawAdapter.clear();
    _secondaryRawAdapter.clear();
  }

  @override
  bool containsKey(String key) => _primaryRawAdapter.containsKey(key);

  @override
  T? get(String key) => _primaryRawAdapter.get(key);

  @override
  List<String> getKeys() => _primaryRawAdapter.getKeys();

  @override
  List<T> getValues() => _primaryRawAdapter.getValues();

  @override
  void put(String key, T value) {
    _primaryRawAdapter.put(key, value);
    _secondaryRawAdapter.put(key, value);
  }

  @override
  void putAll(Map<String, T> values) {
    _primaryRawAdapter.putAll(values);
    _secondaryRawAdapter.putAll(values);
  }

  @override
  void remove(String key) {
    _primaryRawAdapter.remove(key);
    _secondaryRawAdapter.remove(key);
  }
}
