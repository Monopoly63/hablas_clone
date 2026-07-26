import 'package:get_it/get_it.dart';
import '../native_bridge/virtual_engine_bridge.dart';
import '../native_bridge/work_profile_bridge.dart';
import '../persistence/instance_persistence_service.dart';
import '../cache/app_cache_service.dart';
import '../services/app_discovery_service.dart';
import '../services/app_state_service.dart';
import '../services/security_service.dart';
import '../l10n/localization_service.dart';
import '../error/result.dart';
import '../../features/app_picker/domain/app_picker_repository.dart';
import '../../features/dashboard/domain/virtual_instance.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/stealth/stealth_mode_service.dart';
import '../../features/export_import/data_transfer_service.dart';

/// ─── Dependency Injection Container — GetIt v2.0.0 ──────────────────
///
/// CRITICAL FIXES vs v1.x:
///   1. AppPickerRepository is NOW Singleton (was Factory — caused data sync issues)
///   2. AppStateService added for lifecycle persistence
///   3. SecurityService added for multi-layer security
///   4. SharedPreferences initialized here (needed by AppStateService)
///   5. All services eager-initialized before runApp
///
/// Singleton = shared across entire app (same instance everywhere)
/// LazySingleton = created on first access, then shared
/// Factory = new instance every time (only for BLoCs)
///
final sl = GetIt.instance;

/// Initializes all dependencies. Called in main() before runApp().
/// MUST complete before any UI renders.
Future<void> initializeDependencies() async {
  // ─── 1. App State Service (Eager — determines startup phase) ────────
  final appState = AppStateService();
  await appState.initialize();
  sl.registerSingleton<AppStateService>(appState);

  // ─── 2. Localization (Eager — needed for all UI strings) ────────────
  final localization = LocalizationService();
  await localization.initialize();
  sl.registerSingleton<LocalizationService>(localization);

  // ─── 3. Security (Eager — needed for lock check at startup) ──────────
  sl.registerSingleton<SecurityService>(SecurityService());

  // ─── 4. Persistence (Eager — must be initialized before repositories) ──
  final persistence = InstancePersistenceService();
  await persistence.initialize();
  sl.registerSingleton<InstancePersistenceService>(persistence);

  // ─── 5. Core Bridges (Eager) ────────────────────────────────────────
  sl.registerSingleton<VirtualEngineBridge>(VirtualEngineBridge());
  sl.registerSingleton<WorkProfileBridge>(WorkProfileBridge());

  // ─── 6. App Discovery & Cache (Eager) ────────────────────────────────
  sl.registerSingleton<AppDiscoveryService>(AppDiscoveryService());
  sl.registerSingleton<AppCacheService>(AppCacheService());

  // ─── 7. Auth Repository (Eager — needed for lock screen) ────────────
  sl.registerSingleton<AuthRepository>(AuthRepository());

  // ─── 8. AppPickerRepository (NOW Singleton — was Factory in v1.x!) ────
  /// CRITICAL FIX: In v1.x, AppPickerRepository was Factory, meaning
  /// DashboardBloc and AppPickerScreen used DIFFERENT instances.
  /// But they shared the same InstancePersistenceService (Singleton).
  /// The problem: each new AppPickerRepository created its own internal
  /// state that wasn't shared. Now it's Singleton → ONE instance everywhere.
  sl.registerSingleton<AppPickerRepository>(AppPickerRepository(
    engine: sl<VirtualEngineBridge>(),
    persistence: sl<InstancePersistenceService>(),
    appCache: sl<AppCacheService>(),
  ));

  // ─── 9. Feature Services (Lazy) ──────────────────────────────────────
  sl.registerLazySingleton<StealthModeService>(() => StealthModeService());
  sl.registerLazySingleton<DataTransferService>(() => DataTransferService());

  // ─── 10. BLoCs (Factory — recreated per widget lifecycle) ────────────
  /// BLoCs remain Factory because they manage their own state lifecycle.
  /// Each widget tree gets a fresh BLoC, but repositories are Singleton
  /// so the data is shared.
  sl.registerFactory<AuthBloc>(() => AuthBloc(repository: sl<AuthRepository>()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(
    appPickerRepository: sl<AppPickerRepository>(),
  ));
}
