import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─── Localization Service — Arabic/English with RTL support ──────
///
/// Simple JSON-based localization (no flutter_localizations overhead).
/// Supports:
///   - Arabic (ar) — RTL, primary market language
///   - English (en) — LTR, default
///   - Auto-detection based on device locale
///   - User override saved in SharedPreferences
///
class LocalizationService {
  static const String _localeKey = 'hablas_locale';
  static const String _arPath = 'lib/l10n/app_ar.json';
  static const String _enPath = 'lib/l10n/app_en.json';

  Locale _currentLocale = const Locale('ar'); // Default: Arabic (our target market)
  Map<String, String> _strings = {};

  Locale get currentLocale => _currentLocale;
  bool get isRTL => _currentLocale.languageCode == 'ar';
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Initializes localization — loads JSON and determines locale.
  Future<void> initialize() async {
    // Check user preference
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      _currentLocale = Locale(savedLocale);
    } else {
      // Auto-detect: if device is Arabic, use Arabic; otherwise English
      final deviceLocale = PlatformDispatcher.instance.locale;
      if (deviceLocale.languageCode.startsWith('ar')) {
        _currentLocale = const Locale('ar');
      } else {
        _currentLocale = const Locale('en');
      }
    }

    await _loadStrings();
  }

  /// Changes locale and saves preference.
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    await _loadStrings();
  }

  /// Gets a localized string by key.
  String get(String key, {Map<String, dynamic>? args}) {
    var str = _strings[key] ?? key;

    if (args != null) {
      for (final entry in args.entries) {
        str = str.replaceAll('{${entry.key}}', entry.value.toString());
      }
    }

    return str;
  }

  /// Loads JSON strings for current locale.
  Future<void> _loadStrings() async {
    try {
      // For now, use hardcoded maps since asset JSON loading
      // in release builds needs proper asset bundle setup
      _strings = _currentLocale.languageCode == 'ar' ? _arStrings : _enStrings;
    } catch (e) {
      _strings = _enStrings; // Fallback to English
    }
  }

  // ─── Hardcoded string maps (compiled into binary for reliability) ──

  static const Map<String, String> _arStrings = {
    'appName': 'هابلس كلاون',
    'appSubtitle': 'نسخ التطبيقات — تشغيل متوازي',
    'permissionsTitle': 'الإذونات المطلوبة',
    'permissionsBody': 'هابلس كلاون يحتاج:\n\n🔍 الوصول إلى قائمة تطبيقاتك\n🔔 إذن الإشعارات\n🔋 إبقاء النسخ نشطة\n\nاضغط أدناه لمنح الإذونات.',
    'grantPermissions': 'منح الإذونات',
    'checkAgain': 'فحص مرة أخرى',
    'openAppSettings': 'فتح إعدادات التطبيق',
    'permissionError': 'لم يتم العثور على تطبيقات. يرجى منح إذن QUERY_ALL_PACKAGES.',
    'noInstancesYet': 'لا توجد نسخ حتى الآن',
    'noInstancesHint': 'اضغط + لنسخ أول تطبيق.\nWhatsApp, Telegram — كلها تعمل بالتوازي.',
    'cloneApp': 'نسخ تطبيق',
    'searchApps': 'بحث التطبيقات...',
    'systemApps': 'تطبيقات النظام',
    'creatingClone': 'جاري إنشاء النسخة...',
    'noAppsFound': 'لم يتم العثور على تطبيقات',
    'tryAgain': 'محاولة مرة أخرى',
    'rename': 'إعادة تسمية',
    'clearCache': 'مسح الكاش',
    'createShortcut': 'إنشاء اختصار',
    'syncEngine': 'مزامنة مع المحرك',
    'delete': 'حذف',
    'deleteConfirm': 'هل تريد حذف النسخة نهائيًا؟ لا يمكن التراجع.',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'skip': 'تخطي',
    'newName': 'اسم جديد...',
    'launch': 'تشغيل',
    'terminate': 'إيقاف',
    'retry': 'محاولة مرة أخرى',
    'total': 'الإجمالي',
    'active': 'نشط',
    'storage': 'التخزين',
    'loading': 'جاري التحميل...',
    'scanningApps': 'جاري البحث عن التطبيقات...',
    'lockTitle': '🔓 فتح هابلس كلاون',
    'lockSetup': '🔒 تعيين رمز PIN للأمان',
    'lockSetupHint': 'اختر رمز PIN من 4-6 أرقام لحماية نسخك',
    'lockHint': 'أدخل رمز PIN للوصول إلى نسخك',
    'skipForNow': 'تخطي الآن',
    'wrongPin': 'رمز PIN خاطئ. حاول مرة أخرى.',
    'tooManyAttempts': 'عدد المحاولات excessive. يرجى الانتظار.',
    'onboardingWelcome': 'مرحبًا في هابلس كلاون',
    'onboardingWelcomeHint': 'نسخ تطبيقاتك — تشغيل WhatsApp وTelegram بالتوازي على نفس الهاتف',
    'onboardingPermissions': 'الإذونات',
    'onboardingPermissionsHint': 'نحتاج الوصول إلى تطبيقاتك لنسخها. بياناتك محمية.',
    'onboardingClone': 'النسخ',
    'onboardingCloneHint': 'اضغط + واختر أي تطبيق لنسخه. النسخة تعمل بشكل مستقل تمامًا.',
    'onboardingSecurity': 'الأمان',
    'onboardingSecurityHint': 'يمكنك تعيين رمز PIN لحماية نسخك من الوصول غير المصرح.',
    'next': 'التالي',
    'getStarted': 'ابدأ الآن',
    'stealthMode': 'وضع Stealth',
    'stealthEnabled': 'وضع Stealth مفعّل — النسخ مخفية',
    'stealthDisabled': 'وضع Stealth معطّل — النسخ ظاهرة',
    'exportData': 'تصدير البيانات',
    'importData': 'استيراد البيانات',
    'workProfile': 'Profile العمل',
    'workProfileSetup': 'إعداد Profile العمل',
    'workProfileSetupHint': 'Profile العمل يتيح نسخ حقيقية مع عزل كامل',
    'workProfileAvailable': 'Profile العمل متاح',
    'workProfileNotAvailable': 'Profile العمل غير متاح',
    'workProfileAlreadySetup': 'Profile العمل مُعّد بالفعل',
    'privacyLock': 'قفل الخصوصية',
    'biometric': 'البصمة / الوجه',
    'pinCode': 'رمز PIN',
    'enableLock': 'تفعيل القفل',
    'disableLock': 'إلغاء القفل',
  };

  static const Map<String, String> _enStrings = {
    'appName': 'Hablas Clone',
    'appSubtitle': 'Clone Apps — Parallel Running',
    'permissionsTitle': 'Permissions Required',
    'permissionsBody': 'Hablas Clone needs:\n\n🔍 Access to your apps list\n🔔 Notification access\n🔋 Keep clones alive\n\nTap below to grant permissions.',
    'grantPermissions': 'Grant Permissions',
    'checkAgain': 'Check Again',
    'openAppSettings': 'Open App Settings',
    'permissionError': 'No apps found. Please grant QUERY_ALL_PACKAGES permission.',
    'noInstancesYet': 'No Virtual Instances Yet',
    'noInstancesHint': 'Tap + to clone your first app.\nWhatsApp, Telegram — all running in parallel.',
    'cloneApp': 'Clone App',
    'searchApps': 'Search apps...',
    'systemApps': 'System Apps',
    'creatingClone': 'Creating clone...',
    'noAppsFound': 'No matching apps found',
    'tryAgain': 'Try Again',
    'rename': 'Rename',
    'clearCache': 'Clear Cache',
    'createShortcut': 'Create Shortcut',
    'syncEngine': 'Sync with Engine',
    'delete': 'Delete',
    'deleteConfirm': 'Delete permanently? Cannot undo.',
    'cancel': 'Cancel',
    'save': 'Save',
    'skip': 'Skip',
    'newName': 'New name...',
    'launch': 'Launch',
    'terminate': 'Terminate',
    'retry': 'Retry',
    'total': 'Total',
    'active': 'Active',
    'storage': 'Storage',
    'loading': 'Loading...',
    'scanningApps': 'Scanning installed apps...',
    'lockTitle': 'Unlock Hablas Clone',
    'lockSetup': 'Set Security PIN',
    'lockSetupHint': 'Choose a 4-6 digit PIN to protect your clones',
    'lockHint': 'Enter your PIN to access clones',
    'skipForNow': 'Skip for now',
    'wrongPin': 'Wrong PIN. Try again.',
    'tooManyAttempts': 'Too many attempts. Please wait.',
    'onboardingWelcome': 'Welcome to Hablas Clone',
    'onboardingWelcomeHint': 'Clone your apps — run WhatsApp and Telegram simultaneously',
    'onboardingPermissions': 'Permissions',
    'onboardingPermissionsHint': 'We need access to your apps to clone them. Your data is protected.',
    'onboardingClone': 'Cloning',
    'onboardingCloneHint': 'Tap + and select any app to clone. The clone runs independently.',
    'onboardingSecurity': 'Security',
    'onboardingSecurityHint': 'Set a PIN to protect your clones from unauthorized access.',
    'next': 'Next',
    'getStarted': 'Get Started',
    'stealthMode': 'Stealth Mode',
    'stealthEnabled': 'Stealth mode enabled — clones hidden',
    'stealthDisabled': 'Stealth mode disabled — clones visible',
    'exportData': 'Export Data',
    'importData': 'Import Data',
    'workProfile': 'Work Profile',
    'workProfileSetup': 'Set up Work Profile',
    'workProfileSetupHint': 'Work Profile enables real clones with full isolation',
    'workProfileAvailable': 'Work Profile available',
    'workProfileNotAvailable': 'Work Profile not available',
    'workProfileAlreadySetup': 'Work Profile already set up',
    'privacyLock': 'Privacy Lock',
    'biometric': 'Fingerprint / Face',
    'pinCode': 'PIN Code',
    'enableLock': 'Enable Lock',
    'disableLock': 'Disable Lock',
  };
}
