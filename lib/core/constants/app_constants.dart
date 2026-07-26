/// Application-wide constants and configuration values.
library;

class AppConstants {
  // ─── Branding ───────────────────────────────────────────────────────
  static const String appName = 'Hablas Clone';
  static const String appBrand = 'Hablas';
  static const String packageName = 'com.hablas.studio';
  static const String engineChannel = 'com.hablas.studio/engine';

  // ─── Version ────────────────────────────────────────────────────────
  static const String version = '2.0.0';
  static const int buildNumber = 7;

  // ─── Limits ─────────────────────────────────────────────────────────
  /// Theoretical max instances — no hard cap, but we show a soft warning.
  static const int softInstanceWarningThreshold = 5;

  // ─── Storage Paths ──────────────────────────────────────────────────
  static const String sandboxBasePath = '/data/data/com.hablas.studio/virtual/sandbox/';

  // ─── Animation Durations ────────────────────────────────────────────
  static const Duration glassTransitionDuration = Duration(milliseconds: 300);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration pulseDuration = Duration(milliseconds: 2000);

  // ─── Default Instance Naming ────────────────────────────────────────
  static const String defaultInstancePrefix = 'Instance';

  // ─── Notification ───────────────────────────────────────────────────
  static const String foregroundChannelId = 'hablas_engine_foreground';
  static const String foregroundChannelName = 'Hablas Engine Service';
  static const int foregroundNotificationId = 1001;
}
