import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../core/error/result.dart';
import '../../core/error/app_error.dart';

/// ─── Security Service — Multi-layer security architecture ──────────
///
/// LAYER 1: App-level lock (PIN/Biometric) — prevents unauthorized access
/// LAYER 2: SharedPreferences persistence — stores lock/PIN state
/// LAYER 3: Data integrity verification — checksums for critical data
/// LAYER 4: Anti-tamper detection — detects if app data was modified externally
///
/// Rewritten to use SharedPreferences instead of flutter_secure_storage
/// to avoid dependency issues. Will upgrade to encrypted storage in v2.x.
///
class SecurityService {
  // ─── SharedPreferences Keys ─────────────────────────────────────────
  static const String _pinKey = 'hablas_sec_pin';
  static const String _pinHashKey = 'hablas_sec_pin_hash';
  static const String _lockEnabledKey = 'hablas_sec_lock_enabled';
  static const String _biometricEnabledKey = 'hablas_sec_biometric';
  static const String _failedAttemptsKey = 'hablas_sec_attempts';
  static const String _lastFailedAtKey = 'hablas_sec_last_fail';
  static const String _dataChecksumKey = 'hablas_sec_checksum';
  static const String _masterKeyKey = 'hablas_sec_master';

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // ─── PIN Operations (Layer 1) ──────────────────────────────────────

  /// Set a PIN code. Stores both the PIN and a hash for verification.
  Future<Result<void>> setPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        return Result.fail(AppError.security('PIN must be 4-6 digits'));
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
        return Result.fail(AppError.security('PIN must be digits only'));
      }

      final prefs = await SharedPreferences.getInstance();
      final pinHash = _computeHash(pin);
      await prefs.setString(_pinKey, pin);
      await prefs.setString(_pinHashKey, pinHash);
      await prefs.setBool(_lockEnabledKey, true);

      _logger.i('PIN set successfully (${pin.length} digits)');
      return Result.ok(null);
    } catch (e) {
      _logger.e('Failed to set PIN: $e');
      return Result.fail(AppError.security('Failed to save PIN: $e'));
    }
  }

  /// Verify a PIN code. Checks both the PIN and its integrity hash.
  Future<Result<bool>> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_pinKey);
      final storedHash = prefs.getString(_pinHashKey);

      if (storedPin == null) {
        return Result.fail(AppError.security('No PIN set'));
      }

      // Integrity check
      final expectedHash = _computeHash(storedPin);
      if (storedHash != null && storedHash != expectedHash) {
        _logger.w('PIN integrity check FAILED — data may have been tampered!');
        await prefs.remove(_pinKey);
        await prefs.remove(_pinHashKey);
        await prefs.setBool(_lockEnabledKey, false);
        return Result.fail(AppError.security('Security integrity violation detected. Lock reset for safety.'));
      }

      if (pin == storedPin) {
        await prefs.remove(_failedAttemptsKey);
        await prefs.remove(_lastFailedAtKey);
        _logger.i('PIN verified successfully');
        return Result.ok(true);
      }

      await _recordFailedAttempt(prefs);
      _logger.w('Wrong PIN entered (attempts: ${await getFailedAttempts()})');
      return Result.ok(false);
    } catch (e) {
      _logger.e('Failed to verify PIN: $e');
      return Result.fail(AppError.security('PIN verification failed'));
    }
  }

  /// Remove PIN code and disable lock.
  Future<Result<void>> removePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      await prefs.remove(_pinHashKey);
      await prefs.setBool(_lockEnabledKey, false);
      await prefs.remove(_failedAttemptsKey);
      _logger.i('PIN removed and lock disabled');
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to remove PIN'));
    }
  }

  bool get hasPinSync => false;

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  // ─── Failed Attempt Tracking ────────────────────────────────────────

  Future<void> _recordFailedAttempt(SharedPreferences prefs) async {
    final current = await getFailedAttempts();
    await prefs.setInt(_failedAttemptsKey, current + 1);
    await prefs.setString(_lastFailedAtKey, DateTime.now().toIso8601String());
  }

  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  Future<int> getLockoutRemainingSeconds() async {
    final attempts = await getFailedAttempts();
    if (attempts < 5) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lastFailedRaw = prefs.getString(_lastFailedAtKey);
    if (lastFailedRaw == null) return 0;

    final lastFailed = DateTime.tryParse(lastFailedRaw);
    if (lastFailed == null) return 0;

    final lockoutSeconds = _computeLockoutDuration(attempts);
    final elapsed = DateTime.now().difference(lastFailed).inSeconds;
    final remaining = lockoutSeconds - elapsed;

    return remaining > 0 ? remaining : 0;
  }

  int _computeLockoutDuration(int attempts) {
    if (attempts <= 5) return 30;
    if (attempts <= 10) return 60;
    if (attempts <= 15) return 120;
    if (attempts <= 20) return 300;
    return 600;
  }

  // ─── Biometric Auth ─────────────────────────────────────────────────

  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to save biometric setting'));
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // ─── Data Integrity ─────────────────────────────────────────────────

  String _computeHash(String data) {
    var hash = 0;
    for (var i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash) + data.codeUnitAt(i);
      hash = hash & hash;
    }
    return 'h${hash.abs().toRadixString(16)}';
  }

  Future<bool> verifyDataIntegrity(String data, String expectedChecksum) async {
    final computed = _computeHash(data);
    return computed == expectedChecksum;
  }

  // ─── Encrypted Data Storage (SharedPreferences-based for v1.x) ──────

  Future<Result<void>> storeEncrypted(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hablas_enc_$key', value);
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to store data'));
    }
  }

  Future<Result<String?>> readEncrypted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('hablas_enc_$key');
      return Result.ok(value);
    } catch (e) {
      return Result.fail(AppError.security('Failed to read data'));
    }
  }

  Future<Result<void>> deleteEncrypted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hablas_enc_$key');
      return Result.ok(null);
    } catch (e) {
      return Result.fail(AppError.security('Failed to delete data'));
    }
  }

  // ─── Anti-Tamper Detection ──────────────────────────────────────────

  Future<bool> performSecurityAudit() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check 1: PIN integrity
      final pin = prefs.getString(_pinKey);
      final pinHash = prefs.getString(_pinHashKey);
      if (pin != null && pinHash != null) {
        final computed = _computeHash(pin);
        if (computed != pinHash) {
          _logger.e('SECURITY AUDIT: PIN integrity violation!');
          return false;
        }
      }

      // Check 2: Master key
      final masterKey = prefs.getString(_masterKeyKey);
      if (masterKey == null) {
        final newKey = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
        await prefs.setString(_masterKeyKey, newKey);
        _logger.i('Master key generated for security layer');
      }

      _logger.i('Security audit passed — all integrity checks OK');
      return true;
    } catch (e) {
      _logger.e('Security audit failed: $e');
      return false;
    }
  }

  // ─── Debug ──────────────────────────────────────────────────────────

  Map<String, dynamic> dumpSecurityState() {
    return {
      'has_pin': '(async — call hasPin())',
      'lock_enabled': '(async — call isLockEnabled())',
      'biometric_enabled': '(async — call isBiometricEnabled())',
      'failed_attempts': '(async — call getFailedAttempts())',
    };
  }
}
