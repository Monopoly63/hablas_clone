import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../../core/error/result.dart';
import '../../../core/error/app_error.dart';

/// ─── Auth Repository — PIN/Biometric security lock ────────────────
///
/// Provides security lock for accessing the app.
/// Two modes:
///   1. PIN code (4-6 digits, user-defined)
///   2. Biometric (fingerprint/face — if device supports)
///
/// Uses SharedPreferences for PIN storage (encrypted in future with flutter_secure_storage).
/// For v1.5.x, we use SharedPreferences to avoid dependency issues.
///
class AuthRepository {
  static const String _pinKey = 'hablas_security_pin';
  static const String _biometricEnabledKey = 'hablas_biometric_enabled';
  static const String _lockEnabledKey = 'hablas_lock_enabled';

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // ─── Lock Status ────────────────────────────────────────────────────

  /// Whether security lock is enabled.
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  /// Enable/disable security lock.
  Future<Result<void>> setLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, enabled);
      return Result.ok(null);
    } catch (e) {
      _logger.e('Failed to set lock enabled: $e');
      return Result.fail(AppError.security('Failed to save lock setting'));
    }
  }

  // ─── PIN Operations ─────────────────────────────────────────────────

  /// Set a new PIN code.
  Future<Result<void>> setPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        return Result.fail(AppError.security('PIN must be 4-6 digits'));
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
        return Result.fail(AppError.security('PIN must be digits only'));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
      await setLockEnabled(true);
      return Result.ok(null);
    } catch (e) {
      _logger.e('Failed to set PIN: $e');
      return Result.fail(AppError.security('Failed to save PIN'));
    }
  }

  /// Verify PIN code.
  Future<Result<bool>> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_pinKey);
      if (storedPin == null) {
        return Result.fail(AppError.security('No PIN set'));
      }
      return Result.ok(pin == storedPin);
    } catch (e) {
      _logger.e('Failed to verify PIN: $e');
      return Result.fail(AppError.security('Failed to verify PIN'));
    }
  }

  /// Remove PIN code.
  Future<Result<void>> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      await setLockEnabled(false);
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to remove PIN'));
    }
  }

  /// Whether a PIN has been set.
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  // ─── Biometric ──────────────────────────────────────────────────────

  /// Enable/disable biometric unlock.
  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to save biometric setting'));
    }
  }

  /// Whether biometric unlock is enabled.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
}
