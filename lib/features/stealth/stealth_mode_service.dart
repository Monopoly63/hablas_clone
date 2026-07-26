import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../core/error/result.dart';
import '../../core/error/app_error.dart';

/// ─── Stealth Mode — Hide clones from launcher ────────────────────
///
/// Stealth mode disables the app's launcher activity component,
/// making it invisible on the home screen. The app can only be
/// opened via dialer code (e.g., dial *#*#7737#*#*) or notification.
///
/// This is a privacy feature common in security apps:
///   - Calculator+ (vault apps use this)
///   - AppLock (hide apps feature)
///   - Island (freeze apps feature)
///
/// Implementation:
///   1. Disable launcher component in AndroidManifest → app invisible
///   2. Register dialer shortcut → *#*#7737#*#* opens app
///   3. Notification shortcut → foreground service notification
///   4. Toggle via MethodChannel to Kotlin PackageManager
///
class StealthModeService {
  static const String _stealthKey = 'hablas_stealth_mode';
  static const String _dialerCode = '*#*#7737#*#*'; // "HABLAS" on phone keypad

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  static const MethodChannel _channel = MethodChannel('com.hablas.studio/stealth');

  /// Whether stealth mode is currently active.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stealthKey) ?? false;
  }

  /// Enables stealth mode — hides app from launcher.
  Future<Result<void>> enable() async {
    try {
      // 1. Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_stealthKey, true);

      // 2. Disable launcher component via Kotlin MethodChannel
      await _channel.invokeMethod('enableStealthMode');

      _logger.i('Stealth mode enabled');
      return Result.ok(null);
    } on PlatformException catch (e) {
      _logger.e('Stealth enable failed: ${e.message}');
      return Result.fail(AppError.security('Stealth mode requires Device Admin permission'));
    } catch (e) {
      return Result.fail(AppError.unknown('Stealth enable failed: $e'));
    }
  }

  /// Disables stealth mode — shows app in launcher again.
  Future<Result<void>> disable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_stealthKey, false);

      await _channel.invokeMethod('disableStealthMode');

      _logger.i('Stealth mode disabled');
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.unknown('Stealth disable failed: $e'));
    }
  }

  /// The dialer code to open the app when in stealth mode.
  String get dialerCode => _dialerCode;

  /// Instructions for opening the app in stealth mode.
  String get stealthInstructions => 'To open Hablas Clone in stealth mode:\n'
      '1. Open Phone dialer\n'
      '2. Dial $dialerCode\n'
      '3. App will open automatically';
}
