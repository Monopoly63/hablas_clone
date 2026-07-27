import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../../core/error/result.dart';

/// ─── Auth Repository — PIN/Biometric security lock ────────────────
///
/// Provides security lock for accessing the app.
/// Two modes:
///   1. PIN code (4-6 digits, user-defined)
///   2. Biometric (fingerprint/face — if device supports)
///
/// Uses flutter_secure_storage for encrypted PIN storage.
///
class AuthRepository {
  static const String _pinKey = 'hablas_security_pin';
  static const String _biometricEnabledKey = 'hablas_biometric_enabled';
  static const String _lockEnabledKey = 'hablas_lock_enabled';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // ─── Lock Status ────────────────────────────────────────────────────

  /// Whether security lock is enabled.
  Future<bool> isLockEnabled() async {
    final value = await _secureStorage.read(key: _lockEnabledKey);
    return value == 'true';
  }

  /// Enable/disable security lock.
  Future<Result<void>> setLockEnabled(bool enabled) async {
    try {
      await _secureStorage.write(key: _lockEnabledKey, enabled ? 'true' : 'false');
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
      if (!RegExp(r'^[0-9]+$').matches(pin)) {
        return Result.fail(AppError.security('PIN must be digits only'));
      }
      await _secureStorage.write(key: _pinKey, pin);
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
      final storedPin = await _secureStorage.read(key: _pinKey);
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
      await _secureStorage.delete(key: _pinKey);
      await setLockEnabled(false);
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to remove PIN'));
    }
  }

  /// Whether a PIN has been set.
  Future<bool> hasPin() async {
    final value = await _secureStorage.read(key: _pinKey);
    return value != null;
  }

  // ─── Biometric ──────────────────────────────────────────────────────

  /// Enable/disable biometric unlock.
  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(key: _biometricEnabledKey, enabled ? 'true' : 'false');
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to save biometric setting'));
    }
  }

  /// Whether biometric unlock is enabled.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }
}
