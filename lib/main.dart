import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/native_bridge/virtual_engine_bridge.dart';
import 'core/persistence/instance_persistence_service.dart';
import 'core/cache/app_cache_service.dart';
import 'core/permissions/permission_gate.dart';
import 'features/app_picker/domain/app_picker_repository.dart';
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

  // Initialize Hive for Flutter (includes path_provider internally)
  await Hive.initFlutter();

  // Initialize persistence service (opens Hive boxes, registers adapters)
  final persistenceService = InstancePersistenceService();
  await persistenceService.initialize();

  // Initialize app cache service
  final appCacheService = AppCacheService();

  runApp(HablasVirtualStudio(
    persistenceService: persistenceService,
    appCacheService: appCacheService,
  ));
}

class HablasVirtualStudio extends StatelessWidget {
  final InstancePersistenceService persistenceService;
  final AppCacheService appCacheService;

  const HablasVirtualStudio({
    super.key,
    required this.persistenceService,
    required this.appCacheService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<VirtualEngineBridge>(create: (_) => VirtualEngineBridge()),
        RepositoryProvider<InstancePersistenceService>.value(value: persistenceService),
        RepositoryProvider<AppCacheService>.value(value: appCacheService),
        RepositoryProvider<AppPickerRepository>(
          create: (ctx) => AppPickerRepository(
            engine: ctx.read<VirtualEngineBridge>(),
            persistence: ctx.read<InstancePersistenceService>(),
            appCache: ctx.read<AppCacheService>(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (ctx) => DashboardBloc(appPickerRepository: ctx.read<AppPickerRepository>()),
        child: MaterialApp(
          title: 'Hablas Clone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildDarkTheme(),
          home: _AppEntry(),
        ),
      ),
    );
  }
}

/// Entry point — shows PermissionGate first, then Dashboard
class _AppEntry extends StatefulWidget {
  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _permissionsGranted = false;

  @override
  Widget build(BuildContext context) {
    if (_permissionsGranted) {
      return const DashboardScreen();
    }
    return PermissionGate(
      onGranted: () {
        setState(() => _permissionsGranted = true);
        context.read<DashboardBloc>().add(LoadDashboard());
      },
    );
  }
}
