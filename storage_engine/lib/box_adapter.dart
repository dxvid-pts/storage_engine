abstract class BoxAdapter<T> {
  BoxAdapter();
  
  late final String boxKey;

  Future<void> init(String boxKey);

  bool containsKey(String key);

  T? get(String key);

  void put(String key, T value);

  void putAll(Map<String, T> values);

  void remove(String key);

  void clear();

  List<T> getValues();

  List<String> getKeys();
}