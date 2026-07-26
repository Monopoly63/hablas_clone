import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_data.dart';
import '../native_bridge/virtual_engine_bridge.dart';

/// ─── App Discovery Service ──────────────────────────────────────────
///
/// Uses the `installed_apps` Flutter package to enumerate installed apps.
/// This package is compatible with AGP 8.x and handles QUERY_ALL_PACKAGES.
///
class AppDiscoveryService {
  /// Returns all user-installed apps on the device.
  Future<List<DiscoveredApp>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      // true = include app icons, true = only apps with launch intent

      return apps
          .where((app) => app.packageName != 'com.hablas.studio') // Exclude self
          .map((app) => DiscoveredApp(
        packageName: app.packageName!,
        appName: app.name!,
        versionName: app.versionName,
        isSystemApp: false,
        iconBytes: app.icon, // Uint8List? from installed_apps
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns ALL apps including system apps.
  Future<List<DiscoveredApp>> getAllApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, false);
      // true = include icons, false = include ALL apps (not just launchable)

      return apps
          .where((app) => app.packageName != 'com.hablas.studio')
          .map((app) => DiscoveredApp(
        packageName: app.packageName!,
        appName: app.name!,
        versionName: app.versionName,
        isSystemApp: app.isSystemApp ?? false,
        iconBytes: app.icon,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Launches an app by package name.
  Future<bool> launchApp(String packageName) async {
    try {
      return await InstalledApps.launchApp(packageName);
    } catch (e) {
      return false;
    }
  }
}

/// ─── DiscoveredApp — Data Model ─────────────────────────────────────
class DiscoveredApp {
  final String packageName;
  final String appName;
  final String? versionName;
  final bool isSystemApp;
  final Uint8List? iconBytes;
  final String? category;

  const DiscoveredApp({
    required this.packageName,
    required this.appName,
    this.versionName,
    this.isSystemApp = false,
    this.iconBytes,
    this.category,
  });

  bool hasIcon => iconBytes != null && iconBytes!.isNotEmpty;

  MemoryImage? get iconImage {
    if (!hasIcon) return null;
    return MemoryImage(iconBytes!);
  }

  bool get isPopularCloneTarget => _popularTargets.contains(packageName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredApp && packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  static const _popularTargets = {
    'com.whatsapp',
    'com.whatsapp.w4b',
    'org.telegram.messenger',
    'org.telegram.plus',
    'com.instagram.android',
    'com.facebook.katana',
    'com.twitter.android',
    'com.snapchat.android',
    'com.discord',
    'com.viber.voip',
    'com.Slack',
    'com.linkedin.android',
  };
}
