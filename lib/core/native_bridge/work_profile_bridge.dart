import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../error/result.dart';
import '../error/app_error.dart';

/// ─── Work Profile Bridge — Dart ↔ Kotlin MethodChannel ────────────
///
/// Channel: com.hablas.studio/workprofile
/// Methods: isSetup, isAvailable, install, launch, freeze, unfreeze, remove, getApps
///
class WorkProfileBridge {
  static const String _channelName = 'com.hablas.studio/workprofile';
  static const MethodChannel _channel = MethodChannel(_channelName);
  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Whether Work Profile is currently set up on device.
  Future<Result<bool>> isSetup() async {
    try {
      final bool result = await _channel.invokeMethod('isWorkProfileSetup');
      return Result.ok(result);
    } on PlatformException catch (e) {
      _logger.e('WorkProfile isSetup failed: ${e.message}');
      return Result.fail(AppError.workProfileSetup(e.message ?? 'Unknown'));
    }
  }

  /// Whether Work Profile feature is available on this device.
  Future<Result<bool>> isAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isWorkProfileAvailable');
      return Result.ok(result);
    } on PlatformException catch (e) {
      return Result.fail(AppError.workProfileSetup(e.message ?? 'Not available'));
    }
  }

  /// Installs an app in the Work Profile (real cloning!).
  Future<Result<bool>> installApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('installAppInWorkProfile', {'packageName': packageName});
      if (result) {
        return Result.ok(true);
      }
      return Result.fail(AppError.cloneFailed(packageName, 'Work Profile install returned false'));
    } on PlatformException catch (e) {
      return Result.fail(AppError.cloneFailed(packageName, e.message ?? 'Platform error'));
    }
  }

  /// Launches an app in the Work Profile.
  Future<Result<bool>> launchApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('launchAppInWorkProfile', {'packageName': packageName});
      return Result.ok(result);
    } on PlatformException catch (e) {
      return Result.fail(AppError.engineError(e.message ?? 'Launch failed'));
    }
  }

  /// Freezes an app (disables it in work profile).
  Future<Result<bool>> freezeApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('freezeApp', {'packageName': packageName});
      return Result.ok(result);
    } catch (e) {
      return Result.fail(AppError.engineError('Freeze failed'));
    }
  }

  /// Unfreezes an app (re-enables it in work profile).
  Future<Result<bool>> unfreezeApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('unfreezeApp', {'packageName': packageName});
      return Result.ok(result);
    } catch (e) {
      return Result.fail(AppError.engineError('Unfreeze failed'));
    }
  }

  /// Removes an app from the Work Profile.
  Future<Result<bool>> removeApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('removeAppFromWorkProfile', {'packageName': packageName});
      return Result.ok(result);
    } catch (e) {
      return Result.fail(AppError.cloneFailed(packageName, 'Remove failed'));
    }
  }

  /// Gets all apps installed in the Work Profile.
  Future<Result<List<String>>> getWorkProfileApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getWorkProfileApps');
      return Result.ok(result.cast<String>());
    } catch (e) {
      return Result.fail(AppError.engineError('getWorkProfileApps failed'));
    }
  }
}
