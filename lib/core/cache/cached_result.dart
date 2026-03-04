/// Wrapper for data that may be from cache.
class CachedResult<T> {
  final T data;
  final bool isStale;
  final String? cacheKey;

  const CachedResult({
    required this.data,
    this.isStale = false,
    this.cacheKey,
  });
}
