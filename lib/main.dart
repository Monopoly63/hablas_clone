import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/native_bridge/virtual_engine_bridge.dart';
import 'core/persistence/instance_persistence_service.dart';
import 'core/cache/app_cache_service.dart';
import 'core/permissions/permission_gate.dart';
import 'features/app_picker/domain/app_picker_repository.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/lock_screen.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

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

  // Initialize DI container (services, persistence, repositories)
  await initializeDependencies();

  runApp(const HablasCloneApp());
}

class HablasCloneApp extends StatelessWidget {
  const HablasCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(create: (_) => sl<VirtualEngineBridge>()),
        RepositoryProvider<InstancePersistenceService>(create: (_) => sl<InstancePersistenceService>()),
        RepositoryProvider<AppCacheService>(create: (_) => sl<AppCacheService>()),
        RepositoryProvider<AppPickerRepository>(create: (_) => sl<AppPickerRepository>()),
        RepositoryProvider<AuthRepository>(create: (_) => sl<AuthRepository>()),
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
          home: const _AppEntry(),
        ),
      ),
    );
  }
}

/// Entry point — Permission → Lock → Dashboard
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  _AppPhase _phase = _AppPhase.permissions;

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
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

enum _AppPhase { permissions, lock, dashboard }
