import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_data.dart';

/// ─── App Discovery Service — uses installed_apps package ─────────────
class AppDiscoveryService {
  /// Returns user-installed apps (excluding system apps).
  Future<List<DiscoveredApp>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      return apps
          .where((app) => app.packageName != 'com.hablas.studio')
          .map((app) => _appInfoToDiscovered(app))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns ALL apps including system apps.
  Future<List<DiscoveredApp>> getAllApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );
      return apps
          .where((app) => app.packageName != 'com.hablas.studio')
          .map((app) => _appInfoToDiscovered(app))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Launches an app by package name.
  Future<bool> launchApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
      return true;
    } catch (e) {
      return false;
    }
  }

  DiscoveredApp _appInfoToDiscovered(AppInfo app) {
    return DiscoveredApp(
      packageName: app.packageName,
      appName: app.name,
      versionName: app.versionName,
      isSystemApp: app.isSystemApp,
      iconBytes: app.icon, // Uint8List?
      category: app.category.toString(),
    );
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
    'com.instagram.android',
    'com.facebook.katana',
    'com.twitter.android',
    'com.snapchat.android',
    'com.discord',
    'com.viber.voip',
  };
}
