import 'package:get_it/get_it.dart';
import '../native_bridge/virtual_engine_bridge.dart';
import '../native_bridge/work_profile_bridge.dart';
import '../persistence/instance_persistence_service.dart';
import '../cache/app_cache_service.dart';
import '../services/app_discovery_service.dart';
import '../services/app_state_service.dart';
import '../l10n/localization_service.dart';
import '../error/result.dart';
import '../../features/app_picker/domain/app_picker_repository.dart';
import '../../features/dashboard/domain/virtual_instance.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/stealth/stealth_mode_service.dart';
import '../../features/export_import/data_transfer_service.dart';

/// ─── Dependency Injection Container — GetIt ──────────────────────
///
/// Registers ALL services, repositories, BLoCs, and bridges.
/// Called in main() before runApp().
///
final sl = GetIt.instance;

/// Initializes all dependencies.
Future<void> initializeDependencies() async {
  // ─── Localization (Eager — needed first for all UI strings) ────────
  final localization = LocalizationService();
  await localization.initialize();
  sl.registerSingleton<LocalizationService>(localization);

  // ─── App State (Eager — determines startup phase) ──────────────────
  final appState = AppStateService();
  await appState.initialize();
  sl.registerSingleton<AppStateService>(appState);

  // ─── Core Bridges (Eager) ──────────────────────────────────────────
  sl.registerSingleton<VirtualEngineBridge>(VirtualEngineBridge());
  sl.registerSingleton<WorkProfileBridge>(WorkProfileBridge());

  // ─── App discovery (Eager) ─────────────────────────────────────────
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

  // ─── Feature Services (Lazy — created when first accessed) ──────────
  sl.registerLazySingleton<StealthModeService>(() => StealthModeService());
  sl.registerLazySingleton<DataTransferService>(() => DataTransferService());

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
