import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/native_bridge/virtual_engine_bridge.dart';
import 'core/native_bridge/work_profile_bridge.dart';
import 'core/persistence/instance_persistence_service.dart';
import 'core/cache/app_cache_service.dart';
import 'core/permissions/permission_gate.dart';
import 'core/services/app_state_service.dart';
import 'core/services/security_service.dart';
import 'core/l10n/localization_service.dart';
import 'features/app_picker/domain/app_picker_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/lock_screen.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

/// ─── Hablas Clone v2.0.0 — Production-Grade App Cloning Platform ────
///
/// KEY FIXES vs v1.x:
///   1. App state is NOW persisted (SharedPreferences) — no restart from zero
///   2. Onboarding/Permissions/Lock phases are SKIPPED if already completed
///   3. SecurityService replaces AuthRepository with multi-layer security
///   4. All DI services are Singleton — no Factory for repositories
///   5. Hive initialization happens BEFORE any UI renders
///   6. Dashboard loads persisted instances on startup
///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.oledBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive FIRST — must be ready before any persistence operations
  await Hive.initFlutter();

  // Initialize DI container (all services, persistence, repositories)
  // This also initializes SharedPreferences, InstancePersistenceService, etc.
  await initializeDependencies();

  runApp(const HablasCloneApp());
}

class HablasCloneApp extends StatelessWidget {
  const HablasCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = sl<LocalizationService>();
    final appState = sl<AppStateService>();
    final security = sl<SecurityService>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(create: (_) => sl<VirtualEngineBridge>()),
        RepositoryProvider<WorkProfileBridge>(create: (_) => sl<WorkProfileBridge>()),
        RepositoryProvider<InstancePersistenceService>(create: (_) => sl<InstancePersistenceService>()),
        RepositoryProvider<AppCacheService>(create: (_) => sl<AppCacheService>()),
        RepositoryProvider<AppPickerRepository>(create: (_) => sl<AppPickerRepository>()),
        RepositoryProvider<AuthRepository>(create: (_) => sl<AuthRepository>()),
        RepositoryProvider<LocalizationService>.value(value: loc),
        RepositoryProvider<AppStateService>.value(value: appState),
        RepositoryProvider<SecurityService>.value(value: security),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
          BlocProvider<DashboardBloc>(create: (_) => sl<DashboardBloc>()),
        ],
        child: MaterialApp(
          title: 'Hablas Clone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildDarkTheme(),
          locale: loc.currentLocale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: [],
          builder: (context, child) {
            return Directionality(
              textDirection: loc.textDirection,
              child: child!,
            );
          },
          home: const _SmartAppEntry(),
        ),
      ),
    );
  }
}

/// ─── Smart App Entry — Automatically skips completed phases ──────────
///
/// CRITICAL FIX: v1.x always started from onboarding because there was
/// NO state persistence. v2.0.0 uses AppStateService to determine
/// the initial phase and skip completed steps.
///
/// Flow: AppStateService.initialPhase →
///   onboarding → permissions → lock → dashboard
///   (skip any completed phase)
///
class _SmartAppEntry extends StatefulWidget {
  const _SmartAppEntry();

  @override
  State<_SmartAppEntry> createState() => _SmartAppEntryState();
}

class _SmartAppEntryState extends State<_SmartAppEntry> {
  /// Current phase — initialized from persisted state
  AppPhase _phase = AppPhase.onboarding;

  @override
  void initState() {
    super.initState();
    // Determine initial phase from persisted state
    final appState = sl<AppStateService>();
    _phase = appState.initialPhase;

    // If starting at dashboard, load persisted instances
    if (_phase == AppPhase.dashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardBloc>().add(LoadDashboard());
        }
      });
    }
  }

  /// Advance to next phase, persisting each completed step.
  void _advancePhase(AppPhase nextPhase) {
    setState(() => _phase = nextPhase);

    // Load instances when reaching dashboard
    if (nextPhase == AppPhase.dashboard) {
      context.read<DashboardBloc>().add(LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      AppPhase.onboarding => OnboardingScreen(
          onComplete: () {
            // Persist: onboarding done
            sl<AppStateService>().setOnboardingCompleted();
            _advancePhase(AppPhase.permissions);
          },
        ),
      AppPhase.permissions => PermissionGate(
          onGranted: () {
            // Persist: permissions granted
            sl<AppStateService>().setPermissionsGranted();
            // Check if lock is needed
            final lockNeeded = sl<AppStateService>().isLockEnabled;
            _advancePhase(lockNeeded ? AppPhase.lock : AppPhase.dashboard);
          },
        ),
      AppPhase.lock => LockScreen(
          onUnlocked: () {
            _advancePhase(AppPhase.dashboard);
          },
        ),
      AppPhase.dashboard => const DashboardScreen(),
    };
  }
}
