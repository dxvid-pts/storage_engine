abstract class BoxAdapter<T> {
  const BoxAdapter();

  bool containsKey(String key);

  T? get(String key);

  void put(String key, T value);

  void remove(String key);

  void clear();

  List<T> getValues();

  List<String> getKeys();
}