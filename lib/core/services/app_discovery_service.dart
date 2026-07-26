import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import '../native_bridge/virtual_engine_bridge.dart';

/// ─── App Discovery Service ──────────────────────────────────────────
///
/// This service enumerates installed apps on the device using the
/// `device_apps` Flutter package, which handles the QUERY_ALL_PACKAGES
/// permission internally.
///
/// It also extracts app icons as raw bytes that can be displayed in
/// Flutter via MemoryImage.
///
class AppDiscoveryService {
  /// Returns all user-installed apps on the device.
  /// Uses device_apps package which handles permissions properly.
  Future<List<DiscoveredApp>> getInstalledApps() async {
    try {
      // Get only user-installed apps (exclude system apps by default)
      final apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: false,
        includeAppIcons: true, // CRITICAL: get icons!
      );

      return apps.map((app) {
        // Convert device_apps Application to our DiscoveredApp model
        return DiscoveredApp(
          packageName: app.packageName,
          appName: app.appName,
          versionName: app.versionName,
          isSystemApp: app.isSystemApp,
          iconBytes: app.icon, // Uint8List? — raw PNG bytes
          category: app.category?.toString(),
        );
      }).where((app) => app.packageName != 'com.hablas.studio') // Exclude self
       .toList();
    } catch (e) {
      // If permission not granted, device_apps throws or returns empty
      return [];
    }
  }

  /// Returns ALL apps including system apps.
  Future<List<DiscoveredApp>> getAllApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true,
        includeAppIcons: true,
      );
      return apps.map((app) => DiscoveredApp(
        packageName: app.packageName,
        appName: app.appName,
        versionName: app.versionName,
        isSystemApp: app.isSystemApp,
        iconBytes: app.icon,
        category: app.category?.toString(),
      )).where((app) => app.packageName != 'com.hablas.studio')
       .toList();
    } catch (e) {
      return [];
    }
  }

  /// Launches an app by package name.
  Future<bool> launchApp(String packageName) async {
    try {
      return await DeviceApps.openApp(packageName);
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
  final Uint8List? iconBytes; // Raw PNG bytes from device_apps
  final String? category;

  const DiscoveredApp({
    required this.packageName,
    required this.appName,
    this.versionName,
    this.isSystemApp = false,
    this.iconBytes,
    this.category,
  });

  /// Whether this app icon can be displayed (has bytes).
  bool hasIcon => iconBytes != null && iconBytes!.isNotEmpty;

  /// Creates an ImageProvider from icon bytes for Flutter display.
  MemoryImage? get iconImage {
    if (!hasIcon) return null;
    return MemoryImage(iconBytes!);
  }

  /// Whether this is a popular clone target.
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
    'com.facebook.lite',
    'com.twitter.android',
    'com.snapchat.android',
    'com.zhiliaoapp.musically',
    'com.viber.voip',
    'com.Slack',
    'com.discord',
    'com.linkedin.android',
  };
}
