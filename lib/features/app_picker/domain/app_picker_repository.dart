import 'installed_app.dart';
import '../../dashboard/domain/virtual_instance.dart';
import '../../../core/native_bridge/virtual_engine_bridge.dart';

/// Repository layer that abstracts the native bridge and persistence layer.
class AppPickerRepository {
  final VirtualEngineBridge _engine;

  AppPickerRepository({required VirtualEngineBridge engine}) : _engine = engine;

  /// Returns all user-installed apps that are cloneable.
  Future<List<InstalledApp>> getInstalledApps() async {
    final apps = await _engine.getSystemInstalledApps();
    return apps.map((info) => InstalledApp(
      packageName: info.packageName,
      appName: info.appName,
      iconPath: info.iconPath,
      versionName: info.versionName,
      isSystemApp: info.isSystemApp,
    )).toList();
  }

  /// Creates a new virtual instance for a given package.
  Future<int> createInstance(String packageName) async {
    return _engine.createVirtualInstance(packageName);
  }

  /// Launches a virtual instance.
  Future<bool> launchInstance(String packageName, int instanceId) async {
    return _engine.launchVirtualInstance(packageName, instanceId);
  }

  /// Terminates a virtual instance.
  Future<bool> terminateInstance(String packageName, int instanceId) async {
    return _engine.terminateVirtualInstance(packageName, instanceId);
  }

  /// Deletes a virtual instance and its data.
  Future<bool> deleteInstance(String packageName, int instanceId) async {
    return _engine.deleteVirtualInstance(packageName, instanceId);
  }

  /// Gets storage size for a specific instance.
  Future<int> getStorageSize(String packageName, int instanceId) async {
    return _engine.getVirtualInstanceStorageSize(packageName, instanceId);
  }

  /// Gets app info for a specific package.
  Future<InstalledApp> getAppInfo(String packageName) async {
    final apps = await getInstalledApps();
    return apps.firstWhere(
      (a) => a.packageName == packageName,
      orElse: () => InstalledApp(packageName: packageName, appName: packageName),
    );
  }

  // ─── Persistence (Hive-based) ───────────────────────────────────────
  // In production, these would use Hive boxes for local persistence.
  // For now, this is a placeholder that returns empty lists.

  Future<List<VirtualInstance>> loadPersistedInstances() async {
    // TODO: Implement Hive persistence
    // For v1.0.0, we return a demo/empty state
    return [];
  }

  Future<void> persistInstances(List<VirtualInstance> instances) async {
    // TODO: Implement Hive persistence
  }
}
