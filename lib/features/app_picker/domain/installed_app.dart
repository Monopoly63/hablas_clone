import 'package:equatable/equatable.dart';

/// Domain entity representing an installed app on the device.
class InstalledApp extends Equatable {
  final String packageName;
  final String appName;
  final String? iconPath;
  final String? versionName;
  final bool isSystemApp;
  final int existingInstanceCount;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.versionName,
    this.isSystemApp = false,
    this.existingInstanceCount = 0,
  });

  /// Whether this app is a popular clone target (WhatsApp, Telegram, etc.).
  bool get isPopularCloneTarget => _popularCloneTargets.contains(packageName);

  @override
  List<Object?> get props => [packageName, appName, versionName, existingInstanceCount];

  static const _popularCloneTargets = {
    'com.whatsapp',
    'com.whatsapp.w4b',
    'org.telegram.messenger',
    'org.telegram.plus',
    'com.instagram.android',
    'com.facebook.katana',
    'com.facebook.lite',
    'com.twitter.android',
    'com.snapchat.android',
    'com.zhiliaoapp.musically',
    'com.viber.voip',
    'com.Slack',
    'com.discord',
    'com.linkedin.android',
    'com.ss.android.ugc.trill',
  };
}
