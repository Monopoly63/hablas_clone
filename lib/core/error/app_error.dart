/// ─── App Error — Structured error hierarchy for the app ────────────
///
/// Replaces string-based error handling with typed, structured errors.
/// Each error has:
///   - type: What category of error (permission, clone, network, etc.)
///   - message: Human-readable description (localized)
///   - isRetryable: Whether the user should try again
///   - code: Machine-readable error code for analytics
///
library;

enum AppErrorType {
  /// Permission not granted (QUERY_ALL_PACKAGES, notification, etc.)
  permission,

  /// Cloning operation failed
  cloneFailed,

  /// Work Profile setup failed
  workProfileSetup,

  /// App not compatible with cloning
  notCompatible,

  /// Network connectivity issue
  network,

  /// Storage/disk space issue
  storage,

  /// Security/PIN lock issue
  security,

  /// Native engine crashed or not responding
  engineError,

  /// Persistence/Hive operation failed
  persistence,

  /// Unknown/unexpected error
  unknown,
}

class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final bool isRetryable;
  final String code;
  final String? details; // Stack trace, debug info, etc.

  const AppError({
    required this.type,
    required this.message,
    this.isRetryable = false,
    this.code = '',
    this.details,
  });

  // ─── Factory Constructors ──────────────────────────────────────────

  factory AppError.permission(String permissionName) => AppError(
    type: AppErrorType.permission,
    message: 'Permission required: $permissionName',
    isRetryable: true,
    code: 'PERM_$permissionName',
  );

  factory AppError.cloneFailed(String packageName, String reason) => AppError(
    type: AppErrorType.cloneFailed,
    message: 'Failed to clone $packageName: $reason',
    isRetryable: true,
    code: 'CLONE_$packageName',
    details: reason,
  );

  factory AppError.workProfileSetup(String reason) => AppError(
    type: AppErrorType.workProfileSetup,
    message: 'Work Profile setup failed: $reason',
    isRetryable: true,
    code: 'WP_SETUP',
    details: reason,
  );

  factory AppError.notCompatible(String packageName) => AppError(
    type: AppErrorType.notCompatible,
    message: '$packageName is not compatible with cloning',
    isRetryable: false,
    code: 'COMP_$packageName',
  );

  factory AppError.engineError(String reason) => AppError(
    type: AppErrorType.engineError,
    message: 'Virtual engine error: $reason',
    isRetryable: true,
    code: 'ENGINE',
    details: reason,
  );

  factory AppError.persistence(String operation) => AppError(
    type: AppErrorType.persistence,
    message: 'Data persistence error during $operation',
    isRetryable: true,
    code: 'PERSIST_$operation',
  );

  factory AppError.security(String reason) => AppError(
    type: AppErrorType.security,
    message: reason,
    isRetryable: false,
    code: 'SEC',
  );

  factory AppError.unknown(String reason) => AppError(
    type: AppErrorType.unknown,
    message: 'Unexpected error: $reason',
    isRetryable: false,
    code: 'UNKNOWN',
    details: reason,
  );

  // ─── Helpers ────────────────────────────────────────────────────────

  /// User-facing localized error message.
  String get displayMessage => switch (type) {
    AppErrorType.permission => 'الإذونات مطلوبة. يرجى السماح للتطبيق بالوصول إلى تطبيقاتك.',
    AppErrorType.cloneFailed => 'فشل نسخ التطبيق. حاول مرة أخرى.',
    AppErrorType.workProfileSetup => 'فشل إعداد Profile العمل. قد لا يكون جهازك متوافقًا.',
    AppErrorType.notCompatible => 'هذا التطبيق غير متوافق مع النسخ.',
    AppErrorType.network => 'مشكلة في الاتصال. تحقق من الإنترنت.',
    AppErrorType.storage => 'مساحة تخزين غير كافية.',
    AppErrorType.security => 'خطأ في الأمان.',
    AppErrorType.engineError => 'خطأ في المحرك الافتراضي.',
    AppErrorType.persistence => 'خطأ في حفظ البيانات.',
    AppErrorType.unknown => 'خطأ غير متوقع.',
  };

  /// English version for debug/logs.
  String get displayMessageEn => switch (type) {
    AppErrorType.permission => 'Permission required. Please allow access to your apps.',
    AppErrorType.cloneFailed => 'Failed to clone app. Please try again.',
    AppErrorType.workProfileSetup => 'Work Profile setup failed. Your device may not be compatible.',
    AppErrorType.notCompatible => 'This app is not compatible with cloning.',
    AppErrorType.network => 'Network error. Check your connection.',
    AppErrorType.storage => 'Insufficient storage space.',
    AppErrorType.security => 'Security error.',
    AppErrorType.engineError => 'Virtual engine error.',
    AppErrorType.persistence => 'Data persistence error.',
    AppErrorType.unknown => 'Unexpected error.',
  };

  /// Icon for the error type in UI.
  String get emoji => switch (type) {
    AppErrorType.permission => '🔐',
    AppErrorType.cloneFailed => '❌',
    AppErrorType.workProfileSetup => '💼',
    AppErrorType.notCompatible => '🚫',
    AppErrorType.network => '🌐',
    AppErrorType.storage => '💾',
    AppErrorType.security => '🔒',
    AppErrorType.engineError => '⚡',
    AppErrorType.persistence => '📦',
    AppErrorType.unknown => '⚠️',
  };

  @override
  String toString() => 'AppError($type): $message [code=$code retryable=$isRetryable]';
}
