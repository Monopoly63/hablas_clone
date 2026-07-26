import 'dart:typed_data';
import 'package:logger/logger.dart';
import '../services/app_discovery_service.dart';

/// ─── App Cache Service — In-memory + Hive cache for installed apps ──
///
/// Problem: Every time AppPickerScreen opens, it re-scans the entire device.
/// Solution: Cache the app list with a timestamp. Refresh only if stale
/// (older than 5 minutes) or on explicit user request.
///
class AppCacheService {
  List<DiscoveredApp>? _cachedApps;
  DateTime? _cacheTimestamp;
  static const Duration _staleThreshold = Duration(minutes: 5);

  final AppDiscoveryService _discovery = AppDiscoveryService();
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Returns cached app list if fresh, otherwise re-scans.
  Future<List<DiscoveredApp>> getApps({bool forceRefresh = false, bool includeSystemApps = false}) async {
    if (!forceRefresh && _cachedApps != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age < _staleThreshold) {
        _logger.d('App cache hit (${_cachedApps!.length} apps, ${age.inSeconds}s old)');
        return _cachedApps!;
      }
      _logger.d('App cache stale (${age.inMinutes}m old), refreshing...');
    }

    // Re-scan the device
    final apps = includeSystemApps
        ? await _discovery.getAllApps()
        : await _discovery.getInstalledApps();

    _cachedApps = apps;
    _cacheTimestamp = DateTime.now();

    _logger.i('App cache refreshed: ${apps.length} apps');
    return apps;
  }

  /// Returns cached apps without re-scanning. Returns null if no cache.
  List<DiscoveredApp>? getCachedAppsOrNull() => _cachedApps;

  /// Invalidates the cache, forcing next call to re-scan.
  void invalidateCache() {
    _cachedApps = null;
    _cacheTimestamp = null;
    _logger.d('App cache invalidated');
  }

  /// Searches cached apps by query. Returns empty list if no cache.
  List<DiscoveredApp> searchCachedApps(String query) {
    if (_cachedApps == null) return [];

    final q = query.toLowerCase();
    return _cachedApps!.where((app) =>
      app.appName.toLowerCase().contains(q) ||
      app.packageName.toLowerCase().contains(q),
    ).toList();
  }

  /// Stores icon bytes for a package in the internal map (lightweight cache).
  final Map<String, Uint8List> _iconCache = {};

  void cacheIcon(String packageName, Uint8List bytes) {
    _iconCache[packageName] = bytes;
  }

  Uint8List? getCachedIcon(String packageName) => _iconCache[packageName];

  bool hasCachedIcon(String packageName) => _iconCache.containsKey(packageName);
}
