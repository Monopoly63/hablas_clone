import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import '../../domain/virtual_instance.dart';
import '../../../app_picker/domain/app_picker_repository.dart';
import '../../../app_picker/domain/installed_app.dart';
import '../../../../core/error/result.dart';
import '../../../../core/error/app_error.dart';

// ─── Events ──────────────────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load all persisted instances from Hive on startup.
class LoadDashboard extends DashboardEvent {}

/// Refresh instances — re-scan app sizes and sync with engine.
class RefreshDashboard extends DashboardEvent {}

/// Launch a virtual instance.
class LaunchInstance extends DashboardEvent {
  final String instanceId;
  LaunchInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

/// Terminate a running instance.
class TerminateInstance extends DashboardEvent {
  final String instanceId;
  TerminateInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

/// Delete an instance permanently.
class DeleteInstance extends DashboardEvent {
  final String instanceId;
  DeleteInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

/// Rename an instance.
class RenameInstance extends DashboardEvent {
  final String instanceId;
  final String newName;
  RenameInstance(this.instanceId, this.newName);
  @override
  List<Object?> get props => [instanceId, newName];
}

/// Clone a new app — uses AppPickerRepository.cloneApp() for complete flow.
class CloneApp extends DashboardEvent {
  final String packageName;
  final String appName;
  CloneApp({required this.packageName, required this.appName});
  @override
  List<Object?> get props => [packageName, appName];
}

/// Legacy event from AppPickerScreen pop — creates instance from picker result.
class AppAddedFromPicker extends DashboardEvent {
  final String packageName;
  final String appName;
  final int instanceId;
  AppAddedFromPicker({required this.packageName, required this.appName, required this.instanceId});
  @override
  List<Object?> get props => [packageName, appName, instanceId];
}

/// Clear cache for an instance.
class ClearInstanceCache extends DashboardEvent {
  final String instanceId;
  ClearInstanceCache(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

/// Sync with native engine.
class SyncWithNativeEngine extends DashboardEvent {}

/// Retry last failed action.
class RetryLastAction extends DashboardEvent {}

// ─── State ───────────────────────────────────────────────────────────────

class DashboardState extends Equatable {
  final List<VirtualInstance> instances;
  final bool isLoading;
  final String? error;
  final AppError? detailedError;
  final Map<String, int> totalStorageByApp;
  final bool isSyncing;
  final String? lastFailedAction;
  final int discoveredAppCount;

  DashboardState({
    this.instances = const [],
    this.isLoading = false,
    this.error,
    this.detailedError,
    this.totalStorageByApp = const {},
    this.isSyncing = false,
    this.lastFailedAction,
    this.discoveredAppCount = 0,
  });

  DashboardState copyWith({
    List<VirtualInstance>? instances,
    bool? isLoading,
    String? error,
    AppError? detailedError,
    Map<String, int>? totalStorageByApp,
    bool? isSyncing,
    String? lastFailedAction,
    int? discoveredAppCount,
  }) {
    return DashboardState(
      instances: instances ?? this.instances,
      isLoading: isLoading ?? this.isLoading,
      error: error, // error is always reset — pass null to clear
      detailedError: detailedError,
      totalStorageByApp: totalStorageByApp ?? this.totalStorageByApp,
      isSyncing: isSyncing ?? this.isSyncing,
      lastFailedAction: lastFailedAction ?? this.lastFailedAction,
      discoveredAppCount: discoveredAppCount ?? this.discoveredAppCount,
    );
  }

  Map<String, List<VirtualInstance>> get groupedByPackage {
    final map = <String, List<VirtualInstance>>{};
    for (final instance in instances) {
      (map[instance.packageName] ??= []).add(instance);
    }
    return map;
  }

  int instanceCountForPackage(String packageName) =>
      instances.where((i) => i.packageName == packageName).length;

  int get totalInstanceCount => instances.length;
  int get runningInstanceCount => instances.where((i) => i.status == InstanceStatus.running).length;
  int get totalStorageBytes => totalStorageByApp.values.fold(0, (a, b) => a + b);
  bool get hasError => error != null;
  bool get isEmpty => instances.isEmpty && !isLoading;

  @override
  List<Object?> get props => [instances, isLoading, error, totalStorageByApp, isSyncing, discoveredAppCount];
}

// ─── BLoC ────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AppPickerRepository _appPickerRepository;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  DashboardBloc({required AppPickerRepository appPickerRepository})
      : _appPickerRepository = appPickerRepository,
        super(DashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<LaunchInstance>(_onLaunchInstance);
    on<TerminateInstance>(_onTerminateInstance);
    on<DeleteInstance>(_onDeleteInstance);
    on<RenameInstance>(_onRenameInstance);
    on<CloneApp>(_onCloneApp);
    on<AppAddedFromPicker>(_onAppAddedFromPicker);
    on<ClearInstanceCache>(_onClearInstanceCache);
    on<SyncWithNativeEngine>(_onSyncWithNativeEngine);
    on<RetryLastAction>(_onRetryLastAction);
  }

  Map<String, int> _computeStorageMap(List<VirtualInstance> instances) {
    final storageMap = <String, int>{};
    for (final instance in instances) {
      storageMap[instance.packageName] =
          (storageMap[instance.packageName] ?? 0) + instance.storageSizeBytes;
    }
    return storageMap;
  }

  // ─── Load Dashboard ───────────────────────────────────────────────

  /// CRITICAL: This is called on startup. MUST load from Hive.
  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    _logger.i('📊 Loading dashboard from persistence...');

    try {
      final instances = await _appPickerRepository.loadPersistedInstances();
      final storageMap = _computeStorageMap(instances);

      // Also get discovered app count for permission verification
      final appsResult = await _appPickerRepository.getInstalledApps();
      final discoveredCount = appsResult.isSuccess ? appsResult.data!.length : 0;

      _logger.i('✅ Dashboard loaded: ${instances.length} instances, ${discoveredCount} apps discovered');

      emit(state.copyWith(
        instances: instances,
        isLoading: false,
        totalStorageByApp: storageMap,
        discoveredAppCount: discoveredCount,
        error: null,
      ));
    } catch (e) {
      _logger.e('❌ Failed to load dashboard: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load instances: $e',
        detailedError: AppError.persistence('loadDashboard'),
        lastFailedAction: 'LoadDashboard',
      ));
    }
  }

  // ─── Refresh Dashboard ────────────────────────────────────────────

  Future<void> _onRefreshDashboard(RefreshDashboard event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isSyncing: true));
    try {
      final updatedInstances = <VirtualInstance>[];
      for (final instance in state.instances) {
        final size = await _appPickerRepository.getStorageSize(
          instance.packageName,
          instance.instanceIndex,
        );
        updatedInstances.add(instance.copyWith(storageSizeBytes: size));
      }
      final storageMap = _computeStorageMap(updatedInstances);
      await _appPickerRepository.persistInstances(updatedInstances);
      emit(state.copyWith(
        instances: updatedInstances,
        totalStorageByApp: storageMap,
        isSyncing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        error: 'Refresh failed: $e',
        lastFailedAction: 'RefreshDashboard',
      ));
    }
  }

  // ─── Launch Instance ──────────────────────────────────────────────

  Future<void> _onLaunchInstance(LaunchInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
      orElse: () => throw StateError('Instance not found: ${event.instanceId}'),
    );

    // Optimistic update: mark as running immediately
    final optimisticUpdated = state.instances.map((i) {
      if (i.id == event.instanceId) {
        return i.copyWith(status: InstanceStatus.running, lastActiveAt: DateTime.now());
      }
      return i;
    }).toList();
    emit(state.copyWith(instances: optimisticUpdated, error: null));

    // Actually launch via repository
    final result = await _appPickerRepository.launchInstance(
      instance.packageName,
      instance.instanceIndex,
    );

    if (result.isError || result.data != true) {
      // Rollback: mark as error
      final rolledBack = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(status: InstanceStatus.error, lastActiveAt: instance.lastActiveAt);
        }
        return i;
      }).toList();
      emit(state.copyWith(
        instances: rolledBack,
        error: 'Failed to launch ${instance.appName}',
        detailedError: result.error ?? AppError.engineError('launch failed'),
        lastFailedAction: 'LaunchInstance:${event.instanceId}',
      ));
    }

    await _appPickerRepository.persistInstances(state.instances);
  }

  // ─── Terminate Instance ───────────────────────────────────────────

  Future<void> _onTerminateInstance(TerminateInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
      orElse: () => throw StateError('Instance not found'),
    );

    final optimisticUpdated = state.instances.map((i) {
      if (i.id == event.instanceId) {
        return i.copyWith(status: InstanceStatus.idle);
      }
      return i;
    }).toList();
    emit(state.copyWith(instances: optimisticUpdated, error: null));

    final success = await _appPickerRepository.terminateInstance(
      instance.packageName,
      instance.instanceIndex,
    );

    if (!success) {
      final rolledBack = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(status: InstanceStatus.running);
        }
        return i;
      }).toList();
      emit(state.copyWith(
        instances: rolledBack,
        error: 'Failed to terminate ${instance.appName}',
      ));
    }

    await _appPickerRepository.persistInstances(state.instances);
  }

  // ─── Delete Instance ──────────────────────────────────────────────

  Future<void> _onDeleteInstance(DeleteInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
    );

    final updated = state.instances.where((i) => i.id != event.instanceId).toList();
    final storageMap = _computeStorageMap(updated);
    emit(state.copyWith(instances: updated, totalStorageByApp: storageMap, error: null));

    await _appPickerRepository.deleteInstance(
      instance.packageName,
      instance.instanceIndex,
    );
  }

  // ─── Rename Instance ──────────────────────────────────────────────

  Future<void> _onRenameInstance(RenameInstance event, Emitter<DashboardState> emit) async {
    final updated = state.instances.map((i) {
      if (i.id == event.instanceId) {
        return i.copyWith(customName: event.newName);
      }
      return i;
    }).toList();
    emit(state.copyWith(instances: updated, error: null));
    await _appPickerRepository.persistInstances(updated);
  }

  // ─── Clone App (v2.0.0 — Complete flow) ──────────────────────────

  /// Uses AppPickerRepository.cloneApp() which handles the complete flow:
  /// create → persist → verify.
  Future<void> _onCloneApp(CloneApp event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    _logger.i('🧬 BLoC: Cloning ${event.packageName}...');

    // Get icon bytes if available
    final iconBytes = _appPickerRepository.getIconBytes(event.packageName);

    final result = await _appPickerRepository.cloneApp(
      packageName: event.packageName,
      appName: event.appName,
      iconBytes: iconBytes,
    );

    if (result.isSuccess && result.data != null) {
      final newInstance = result.data!;
      final existingCount = state.instanceCountForPackage(event.packageName);

      // Override custom name with proper count
      final namedInstance = newInstance.copyWith(
        customName: existingCount == 0
            ? '${event.appName} — Clone 1'
            : '${event.appName} — Clone ${existingCount + 1}',
      );

      final updated = [...state.instances, namedInstance];
      final storageMap = _computeStorageMap(updated);

      _logger.i('✅ Clone added to dashboard: ${namedInstance.id}');

      emit(state.copyWith(
        instances: updated,
        totalStorageByApp: storageMap,
        isLoading: false,
        error: null,
      ));
    } else {
      _logger.e('❌ Clone failed: ${result.error?.message ?? "unknown"}');
      emit(state.copyWith(
        isLoading: false,
        error: result.error?.displayMessage ?? 'Clone failed',
        detailedError: result.error ?? AppError.cloneFailed(event.packageName, 'unknown'),
        lastFailedAction: 'CloneApp:${event.packageName}',
      ));
    }
  }

  // ─── App Added from Picker ────────────────────────────────────────

  /// Legacy handler for AppPickerScreen pop result.
  /// Creates instance and persists immediately.
  Future<void> _onAppAddedFromPicker(AppAddedFromPicker event, Emitter<DashboardState> emit) async {
    final existingCount = state.instanceCountForPackage(event.packageName);

    final newInstance = VirtualInstance(
      id: '${event.packageName}_${event.instanceId}',
      packageName: event.packageName,
      appName: event.appName,
      instanceIndex: event.instanceId,
      customName: existingCount == 0
          ? '${event.appName} — Clone 1'
          : '${event.appName} — Clone ${existingCount + 1}',
      status: InstanceStatus.idle,
      storageSizeBytes: 0,
      createdAt: DateTime.now(),
    );

    final updated = [...state.instances, newInstance];
    final storageMap = _computeStorageMap(updated);
    emit(state.copyWith(instances: updated, totalStorageByApp: storageMap, error: null));

    // CRITICAL: Persist immediately and verify
    final persisted = await _appPickerRepository.persistInstances(updated);
    if (!persisted) {
      _logger.e('❌ Failed to persist instances after adding from picker');
      emit(state.copyWith(error: 'Clone created but data may not be saved'));
    } else {
      _logger.i('✅ Instance persisted: ${newInstance.id}');
    }
  }

  // ─── Clear Instance Cache ─────────────────────────────────────────

  Future<void> _onClearInstanceCache(ClearInstanceCache event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
      orElse: () => throw StateError('Instance not found'),
    );

    final success = await _appPickerRepository.clearInstanceCache(
      instance.packageName,
      instance.instanceIndex,
    );

    if (success) {
      final newSize = await _appPickerRepository.getStorageSize(
        instance.packageName,
        instance.instanceIndex,
      );
      final updated = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(storageSizeBytes: newSize);
        }
        return i;
      }).toList();
      final storageMap = _computeStorageMap(updated);
      emit(state.copyWith(instances: updated, totalStorageByApp: storageMap, error: null));
      await _appPickerRepository.persistInstances(updated);
    } else {
      emit(state.copyWith(error: 'Failed to clear cache'));
    }
  }

  // ─── Sync with Native Engine ──────────────────────────────────────

  Future<void> _onSyncWithNativeEngine(SyncWithNativeEngine event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isSyncing: true));
    try {
      final instances = await _appPickerRepository.loadPersistedInstances();
      final storageMap = _computeStorageMap(instances);
      emit(state.copyWith(
        instances: instances,
        totalStorageByApp: storageMap,
        isSyncing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(isSyncing: false, error: 'Sync failed: $e'));
    }
  }

  // ─── Retry ─────────────────────────────────────────────────────────

  Future<void> _onRetryLastAction(RetryLastAction event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(error: null));
    final action = state.lastFailedAction;
    if (action == null) return;

    if (action == 'LoadDashboard') {
      add(LoadDashboard());
    } else if (action == 'RefreshDashboard') {
      add(RefreshDashboard());
    } else if (action.startsWith('CloneApp:')) {
      final packageName = action.substring('CloneApp:'.length);
      add(CloneApp(packageName: packageName, appName: _appPickerRepository.getAppNameForPackage(packageName)));
    } else if (action.startsWith('LaunchInstance:')) {
      final instanceId = action.substring('LaunchInstance:'.length);
      add(LaunchInstance(instanceId));
    }
  }
}
