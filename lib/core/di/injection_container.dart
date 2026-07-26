import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../native_bridge/virtual_engine_bridge.dart';
import '../persistence/instance_persistence_service.dart';
import '../cache/app_cache_service.dart';
import '../services/app_discovery_service.dart';
import '../error/result.dart';
import '../../features/app_picker/domain/app_picker_repository.dart';
import '../../features/dashboard/domain/virtual_instance.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// ─── Dependency Injection Container — GetIt ──────────────────────
///
/// Central DI container for the entire app.
/// All services are registered here and accessed via GetIt.
/// This replaces the ad-hoc context.read<> pattern with proper DI.
///
/// Benefits:
///   1. Services are accessible anywhere (not just in widget tree)
///   2. Single initialization point (no "create new instances" bug)
///   3. Easy to swap implementations for testing
///   4. Lifecycle management (lazy vs eager, dispose on shutdown)
///
final sl = GetIt.instance;

/// Initializes all dependencies. Called in main() before runApp().
Future<void> initializeDependencies() async {
  // ─── Core Services (Eager — needed immediately) ────────────────────

  // Native engine bridge
  sl.registerSingleton<VirtualEngineBridge>(VirtualEngineBridge());

  // App discovery service
  sl.registerSingleton<AppDiscoveryService>(AppDiscoveryService());

  // ─── Persistence (Eager — must be initialized before anything) ─────

  final persistence = InstancePersistenceService();
  await persistence.initialize();
  sl.registerSingleton<InstancePersistenceService>(persistence);

  // ─── Cache (Eager) ──────────────────────────────────────────────────

  sl.registerSingleton<AppCacheService>(AppCacheService());

  // ─── Auth (Eager — needed for lock screen) ──────────────────────────

  sl.registerSingleton<AuthRepository>(AuthRepository());
  sl.registerFactory<AuthBloc>(() => AuthBloc(repository: sl<AuthRepository>()));

  // ─── Repositories (Factory — recreated when needed) ──────────────────

  sl.registerFactory<AppPickerRepository>(() => AppPickerRepository(
    engine: sl<VirtualEngineBridge>(),
    persistence: sl<InstancePersistenceService>(),
    appCache: sl<AppCacheService>(),
  ));

  // ─── BLoCs (Factory — recreated per widget lifecycle) ────────────────

  sl.registerFactory<DashboardBloc>(() => DashboardBloc(
    appPickerRepository: sl<AppPickerRepository>(),
  ));
}
