/// Native Bridge — Dart ↔ Kotlin MethodChannel Interface
/// Connects the Flutter UI layer to the Android Virtual Engine subsystem.
///
/// Channel: com.hablas.studio/engine
/// All calls are asynchronous and return typed results via platform channels.
library;

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class VirtualEngineBridge {
  static const String _channelName = 'com.hablas.studio/engine';

  static const MethodChannel _channel = MethodChannel(_channelName);

  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // ─── App Discovery ──────────────────────────────────────────────────

  /// Scans the device for cloneable installed applications.
  /// Returns a list of maps containing package metadata.
  Future<List<InstalledAppInfo>> getSystemInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getSystemInstalledApps',
      );
      return result.map((item) => InstalledAppInfo.fromMap(item as Map<String, dynamic>)).toList();
    } on PlatformException catch (e) {
      _logger.e('Failed to get installed apps: ${e.message}', error: e);
      return [];
    }
  }

  // ─── Instance Lifecycle ─────────────────────────────────────────────

  /// Creates a new isolated virtual instance for a given package.
  /// Returns the instance ID (int) assigned by the engine.
  Future<int> createVirtualInstance(String packageName) async {
    try {
      final int instanceId = await _channel.invokeMethod(
        'createVirtualInstance',
        {'packageName': packageName},
      );
      return instanceId;
    } on PlatformException catch (e) {
      _logger.e('Failed to create instance for $packageName: ${e.message}', error: e);
      throw VirtualEngineException('createVirtualInstance failed: ${e.message}');
    }
  }

  /// Launches a virtual instance inside its sandbox container.
  Future<bool> launchVirtualInstance(String packageName, int instanceId) async {
    try {
      final bool success = await _channel.invokeMethod(
        'launchVirtualInstance',
        {'packageName': packageName, 'instanceId': instanceId},
      );
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to launch instance $instanceId for $packageName: ${e.message}', error: e);
      return false;
    }
  }

  /// Safely terminates a virtual instance, flushing data before shutdown.
  Future<bool> terminateVirtualInstance(String packageName, int instanceId) async {
    try {
      final bool success = await _channel.invokeMethod(
        'terminateVirtualInstance',
        {'packageName': packageName, 'instanceId': instanceId},
      );
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to terminate instance $instanceId for $packageName: ${e.message}', error: e);
      return false;
    }
  }

  // ─── Storage Management ─────────────────────────────────────────────

  /// Returns current disk usage for a specific instance.
  Future<int> getVirtualInstanceStorageSize(String packageName, int instanceId) async {
    try {
      final int sizeBytes = await _channel.invokeMethod(
        'getVirtualInstanceStorageSize',
        {'packageName': packageName, 'instanceId': instanceId},
      );
      return sizeBytes;
    } on PlatformException catch (e) {
      _logger.e('Failed to get storage size: ${e.message}', error: e);
      return 0;
    }
  }

  /// Clears instance cache without affecting active session data.
  Future<bool> clearInstanceCache(String packageName, int instanceId) async {
    try {
      final bool success = await _channel.invokeMethod(
        'clearInstanceCache',
        {'packageName': packageName, 'instanceId': instanceId},
      );
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to clear cache: ${e.message}', error: e);
      return false;
    }
  }

  // ─── Bulk Operations ────────────────────────────────────────────────

  /// Returns all active virtual instances across all packages.
  Future<List<VirtualInstanceInfo>> getAllInstances() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllInstances');
      return result.map((item) => VirtualInstanceInfo.fromMap(item as Map<String, dynamic>)).toList();
    } on PlatformException catch (e) {
      _logger.e('Failed to get all instances: ${e.message}', error: e);
      return [];
    }
  }

  /// Deletes an instance and all its sandbox data permanently.
  Future<bool> deleteVirtualInstance(String packageName, int instanceId) async {
    try {
      final bool success = await _channel.invokeMethod(
        'deleteVirtualInstance',
        {'packageName': packageName, 'instanceId': instanceId},
      );
      return success;
    } on PlatformException catch (e) {
      _logger.e('Failed to delete instance: ${e.message}', error: e);
      return false;
    }
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────

class InstalledAppInfo {
  final String packageName;
  final String appName;
  final String? iconPath;
  final String? versionName;
  final bool isSystemApp;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.versionName,
    this.isSystemApp = false,
  });

  factory InstalledAppInfo.fromMap(Map<String, dynamic> map) {
    return InstalledAppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconPath: map['iconPath'] as String?,
      versionName: map['versionName'] as String?,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstalledAppInfo && packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

class VirtualInstanceInfo {
  final String packageName;
  final int instanceId;
  final String customName;
  final InstanceStatus status;
  final int storageSizeBytes;
  final DateTime createdAt;

  const VirtualInstanceInfo({
    required this.packageName,
    required this.instanceId,
    required this.customName,
    required this.status,
    required this.storageSizeBytes,
    required this.createdAt,
  });

  factory VirtualInstanceInfo.fromMap(Map<String, dynamic> map) {
    return VirtualInstanceInfo(
      packageName: map['packageName'] as String,
      instanceId: map['instanceId'] as int,
      customName: map['customName'] as String? ?? 'Instance ${map['instanceId']}',
      status: InstanceStatus.fromString(map['status'] as String? ?? 'idle'),
      storageSizeBytes: map['storageSizeBytes'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

enum InstanceStatus {
  running,
  idle,
  sleeping,
  error;

  static InstanceStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'running' => InstanceStatus.running,
      'sleeping' => InstanceStatus.sleeping,
      'error' => InstanceStatus.error,
      _ => InstanceStatus.idle,
    };
  }

  String toDisplayString() {
    return switch (this) {
      InstanceStatus.running => 'Running',
      InstanceStatus.idle => 'Idle',
      InstanceStatus.sleeping => 'Sleeping',
      InstanceStatus.error => 'Error',
    };
  }
}

class VirtualEngineException implements Exception {
  final String message;
  const VirtualEngineException(this.message);

  @override
  String toString() => 'VirtualEngineException: $message';
}
