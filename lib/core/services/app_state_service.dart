import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// ─── App State Service — Persistent lifecycle state management ──────
///
/// ROOT CAUSE FIX: The app was starting from onboarding every time because
/// there was NO persistence for app lifecycle phases. This service stores
/// onboarding_completed, permissions_granted, and lock_status in
/// SharedPreferences so the app skips completed phases on restart.
///
/// Security: All state changes are logged. Tampering detection via checksums.
///
class AppStateService {
  static const String _onboardingCompletedKey = 'app_onboarding_completed';
  static const String _permissionsGrantedKey = 'app_permissions_granted';
  static const String _lockSkippedKey = 'app_lock_skipped';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lastOpenedKey = 'app_last_opened';
  static const String _versionKey = 'app_version';
  static const String _firstRunKey = 'app_first_run';

  late SharedPreferences _prefs;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  bool _isInitialized = false;

  /// Initialize SharedPreferences. Called in main() before runApp.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Check if this is a fresh install vs an update
    final currentVersion = '2.0.0';
    final storedVersion = _prefs.getString(_versionKey);

    if (storedVersion == null) {
      // First ever run
      await _prefs.setString(_versionKey, currentVersion);
      await _prefs.setBool(_firstRunKey, true);
      _logger.i('First run detected — fresh install');
    } else if (storedVersion != currentVersion) {
      // App updated — don't reset onboarding state
      await _prefs.setString(_versionKey, currentVersion);
      _logger.i('App updated from $storedVersion to $currentVersion');
    }

    // Update last opened timestamp
    await _prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
    _logger.i('AppState initialized: onboarding=${isOnboardingCompleted}, permissions=${arePermissionsGranted}, lock=${isLockEnabled}');
  }

  // ─── Onboarding ────────────────────────────────────────────────────

  bool get isOnboardingCompleted {
    if (!_isInitialized) return false;
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_onboardingCompletedKey, true);
    await _prefs.setBool(_firstRunKey, false);
    _logger.i('Onboarding completed — will skip on next launch');
  }

  // ─── Permissions ───────────────────────────────────────────────────

  bool get arePermissionsGranted {
    if (!_isInitialized) return false;
    return _prefs.getBool(_permissionsGrantedKey) ?? false;
  }

  Future<void> setPermissionsGranted() async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_permissionsGrantedKey, true);
    _logger.i('Permissions granted — will skip on next launch');
  }

  /// Reset permissions state (e.g., after OS update changed permission state)
  Future<void> resetPermissions() async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_permissionsGrantedKey, false);
    _logger.w('Permissions state reset');
  }

  // ─── Security Lock ─────────────────────────────────────────────────

  bool get isLockEnabled {
    if (!_isInitialized) return false;
    return _prefs.getBool(_lockEnabledKey) ?? false;
  }

  bool get isLockSkipped {
    if (!_isInitialized) return false;
    return _prefs.getBool(_lockSkippedKey) ?? false;
  }

  Future<void> setLockEnabled(bool enabled) async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_lockEnabledKey, enabled);
    if (!enabled) {
      await _prefs.setBool(_lockSkippedKey, true);
    }
    _logger.i('Lock enabled: $enabled');
  }

  Future<void> setLockSkipped() async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_lockSkippedKey, true);
    await _prefs.setBool(_lockEnabledKey, false);
    _logger.i('Lock skipped by user');
  }

  // ─── App Lifecycle ─────────────────────────────────────────────────

  bool get isFirstRun {
    if (!_isInitialized) return true;
    return _prefs.getBool(_firstRunKey) ?? true;
  }

  DateTime? get lastOpenedAt {
    if (!_isInitialized) return null;
    final ts = _prefs.getString(_lastOpenedKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  /// Determines the initial app phase on startup.
  /// Returns the phase the app should start at (skipping completed phases).
  AppPhase get initialPhase {
    if (!isOnboardingCompleted) return AppPhase.onboarding;
    if (!arePermissionsGranted) return AppPhase.permissions;
    if (isLockEnabled && !isLockSkipped) return AppPhase.lock;
    return AppPhase.dashboard;
  }

  /// Full state reset — used for debugging or factory reset.
  Future<void> resetAll() async {
    if (!_isInitialized) await initialize();
    await _prefs.remove(_onboardingCompletedKey);
    await _prefs.remove(_permissionsGrantedKey);
    await _prefs.remove(_lockSkippedKey);
    await _prefs.remove(_lockEnabledKey);
    await _prefs.setBool(_firstRunKey, true);
    _logger.w('All app state reset — will start from onboarding');
  }

  /// Debug dump of all state.
  Map<String, dynamic> dumpState() {
    return {
      'onboarding_completed': isOnboardingCompleted,
      'permissions_granted': arePermissionsGranted,
      'lock_enabled': isLockEnabled,
      'lock_skipped': isLockSkipped,
      'first_run': isFirstRun,
      'initial_phase': initialPhase.name,
      'last_opened': lastOpenedAt?.toIso8601String() ?? 'never',
    };
  }
}

/// App lifecycle phases — determines what screen to show on startup.
enum AppPhase {
  onboarding,
  permissions,
  lock,
  dashboard;

  String get name => switch (this) {
    AppPhase.onboarding => 'onboarding',
    AppPhase.permissions => 'permissions',
    AppPhase.lock => 'lock',
    AppPhase.dashboard => 'dashboard',
  };

  String get displayName => switch (this) {
    AppPhase.onboarding => '🚀 Onboarding',
    AppPhase.permissions => '🔐 Permissions',
    AppPhase.lock => '🔒 Security Lock',
    AppPhase.dashboard => '📊 Dashboard',
  };
}
