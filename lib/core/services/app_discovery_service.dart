import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

/// ─── App Discovery Service — installed_apps v1.5.1 ──────────────────
class AppDiscoveryService {
  /// Returns user-installed apps.
  /// installed_apps v1.5.1: positional args
  Future<List<DiscoveredApp>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true, '');
      // (excludeSystemApps=true, withIcon=true, packageNamePrefix='')
      return apps
          .where((app) => app.packageName != 'com.hablas.studio')
          .map((app) => DiscoveredApp(
            packageName: app.packageName,
            appName: app.name,
            versionName: app.versionName,
            isSystemApp: false, // we excluded system apps
            iconBytes: app.icon,
          )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns ALL apps including system apps.
  Future<List<DiscoveredApp>> getAllApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(false, true, '');
      // (excludeSystemApps=false, withIcon=true, packageNamePrefix='')
      return apps
          .where((app) => app.packageName != 'com.hablas.studio')
          .map((app) => DiscoveredApp(
            packageName: app.packageName,
            appName: app.name,
            versionName: app.versionName,
            isSystemApp: true, // we included system apps
            iconBytes: app.icon,
          )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Launches an app by package name.
  /// InstalledApps.startApp returns void (Future<void>)
  Future<bool> launchApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
      return true;
    } catch (e) {
      return false;
    }
  }
}

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
  MemoryImage? get iconImage => hasIcon ? MemoryImage(iconBytes!) : null;
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
    'com.instagram.android',
    'com.facebook.katana',
    'com.twitter.android',
    'com.snapchat.android',
    'com.discord',
  };
}
