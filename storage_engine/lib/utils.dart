import 'package:storage_engine/box_adapter.dart';

Map<String, T> getPaginatedListFromCache<T>({
  required Map<String, T> cache,
  required ListPaginationParams? pagination,
}) {
  if (pagination == null) {
    return cache;
  } else {
    final start = pagination.page * pagination.perPage;
    int end = start + pagination.perPage;

    //make sure we don't go out of bounds
    if (end > cache.length) {
      end = cache.length;
    }

    return Map.fromIterables(
      cache.keys.toList().sublist(start, end),
      cache.values.toList().sublist(start, end),
    );
  }
}
