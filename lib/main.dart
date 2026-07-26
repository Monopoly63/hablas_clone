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
import 'core/l10n/localization_service.dart';
import 'features/app_picker/domain/app_picker_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/lock_screen.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/stealth/stealth_mode_service.dart';
import 'features/export_import/data_transfer_service.dart';

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

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize DI container (all services, persistence, repositories)
  await initializeDependencies();

  runApp(const HablasCloneApp());
}

class HablasCloneApp extends StatelessWidget {
  const HablasCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = sl<LocalizationService>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(create: (_) => sl<VirtualEngineBridge>()),
        RepositoryProvider<WorkProfileBridge>(create: (_) => sl<WorkProfileBridge>()),
        RepositoryProvider<InstancePersistenceService>(create: (_) => sl<InstancePersistenceService>()),
        RepositoryProvider<AppCacheService>(create: (_) => sl<AppCacheService>()),
        RepositoryProvider<AppPickerRepository>(create: (_) => sl<AppPickerRepository>()),
        RepositoryProvider<AuthRepository>(create: (_) => sl<AuthRepository>()),
        RepositoryProvider<LocalizationService>.value(value: loc),
        RepositoryProvider<StealthModeService>(create: (_) => sl<StealthModeService>()),
        RepositoryProvider<DataTransferService>(create: (_) => sl<DataTransferService>()),
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
          // RTL support for Arabic
          locale: loc.currentLocale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: [], // Using custom LocalizationService
          builder: (context, child) {
            // Apply RTL direction for Arabic
            return Directionality(
              textDirection: loc.textDirection,
              child: child!,
            );
          },
          home: const _AppEntry(),
        ),
      ),
    );
  }
}

/// Entry point — Onboarding → Permissions → Lock → Dashboard
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  _AppPhase _phase = _AppPhase.onboarding;

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _AppPhase.onboarding => OnboardingScreen(
          onComplete: () => setState(() => _phase = _AppPhase.permissions),
        ),
      _AppPhase.permissions => PermissionGate(
          onGranted: () {
            setState(() => _phase = _AppPhase.lock);
            context.read<DashboardBloc>().add(LoadDashboard());
          },
        ),
      _AppPhase.lock => LockScreen(
          onUnlocked: () => setState(() => _phase = _AppPhase.dashboard),
        ),
      _AppPhase.dashboard => const DashboardScreen(),
    };
  }
}

enum _AppPhase { onboarding, permissions, lock, dashboard }
