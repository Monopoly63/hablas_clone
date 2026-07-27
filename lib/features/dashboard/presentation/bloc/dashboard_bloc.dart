import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/virtual_instance.dart';
import '../../../app_picker/domain/installed_app.dart';
import '../../../app_picker/domain/app_picker_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class RefreshDashboard extends DashboardEvent {}

class LaunchInstance extends DashboardEvent {
  final String instanceId;
  LaunchInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

class TerminateInstance extends DashboardEvent {
  final String instanceId;
  TerminateInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

class DeleteInstance extends DashboardEvent {
  final String instanceId;
  DeleteInstance(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

class RenameInstance extends DashboardEvent {
  final String instanceId;
  final String newName;
  RenameInstance(this.instanceId, this.newName);
  @override
  List<Object?> get props => [instanceId, newName];
}

class CloneNewApp extends DashboardEvent {
  final String packageName;
  CloneNewApp(this.packageName);
  @override
  List<Object?> get props => [packageName];
}

class AppAddedFromPicker extends DashboardEvent {
  final String packageName;
  final String appName;
  final int instanceId;
  AppAddedFromPicker({required this.packageName, required this.appName, required this.instanceId});
  @override
  List<Object?> get props => [packageName, appName, instanceId];
}

class ClearInstanceCache extends DashboardEvent {
  final String instanceId;
  ClearInstanceCache(this.instanceId);
  @override
  List<Object?> get props => [instanceId];
}

class SyncWithNativeEngine extends DashboardEvent {}

class RetryLastAction extends DashboardEvent {}

// ─── State ───────────────────────────────────────────────────────────────

class DashboardState extends Equatable {
  final List<VirtualInstance> instances;
  final bool isLoading;
  final String? error;
  final Map<String, int> totalStorageByApp;
  final bool isSyncing;
  final String? lastFailedAction;

  DashboardState({
    this.instances = const [],
    this.isLoading = false,
    this.error,
    this.totalStorageByApp = const {},
    this.isSyncing = false,
    this.lastFailedAction,
  });

  DashboardState copyWith({
    List<VirtualInstance>? instances,
    bool? isLoading,
    String? error,
    Map<String, int>? totalStorageByApp,
    bool? isSyncing,
    String? lastFailedAction,
  }) {
    return DashboardState(
      instances: instances ?? this.instances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalStorageByApp: totalStorageByApp ?? this.totalStorageByApp,
      isSyncing: isSyncing ?? this.isSyncing,
      lastFailedAction: lastFailedAction ?? this.lastFailedAction,
    );
  }

  Map<String, List<VirtualInstance>> get groupedByPackage {
    final map = <String, List<VirtualInstance>>{};
    for (final instance in instances) {
      (map[instance.packageName] ?? []).add(instance);
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
  List<Object?> get props => [instances, isLoading, error, totalStorageByApp, isSyncing];
}

// ─── BLoC ────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AppPickerRepository _appPickerRepository;

  DashboardBloc({required AppPickerRepository appPickerRepository})
      : _appPickerRepository = appPickerRepository,
        super(DashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<LaunchInstance>(_onLaunchInstance);
    on<TerminateInstance>(_onTerminateInstance);
    on<DeleteInstance>(_onDeleteInstance);
    on<RenameInstance>(_onRenameInstance);
    on<CloneNewApp>(_onCloneNewApp);
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

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final instances = await _appPickerRepository.loadPersistedInstances();
      final storageMap = _computeStorageMap(instances);
      emit(state.copyWith(
        instances: instances,
        isLoading: false,
        totalStorageByApp: storageMap,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load instances: $e',
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

    final optimisticUpdated = state.instances.map((i) {
      if (i.id == event.instanceId) {
        return i.copyWith(status: InstanceStatus.running, lastActiveAt: DateTime.now());
      }
      return i;
    }).toList();
    emit(state.copyWith(instances: optimisticUpdated, error: null));

    final success = await _appPickerRepository.launchInstance(
      instance.packageName,
      instance.instanceIndex,
    );

    if (!success) {
      final rolledBack = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(status: InstanceStatus.error, lastActiveAt: instance.lastActiveAt);
        }
        return i;
      }).toList();
      emit(state.copyWith(
        instances: rolledBack,
        error: 'Failed to launch ${instance.appName}',
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

  // ─── Clone New App ────────────────────────────────────────────────

  Future<void> _onCloneNewApp(CloneNewApp event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final iconBytes = _appPickerRepository.getIconBytes(event.packageName);

      final instanceId = await _appPickerRepository.createInstance(
        event.packageName,
        iconBytes: iconBytes,
      );

      final appName = _appPickerRepository.getAppNameForPackage(event.packageName);
      final existingCount = state.instanceCountForPackage(event.packageName);

      final newInstance = VirtualInstance(
        id: '${event.packageName}_$instanceId',
        packageName: event.packageName,
        appName: appName,
        instanceIndex: instanceId,
        customName: existingCount == 0
            ? '$appName — Clone 1'
            : '$appName — Clone ${existingCount + 1}',
        status: InstanceStatus.idle,
        storageSizeBytes: 0,
        createdAt: DateTime.now(),
      );

      final updated = [...state.instances, newInstance];
      final storageMap = _computeStorageMap(updated);
      emit(state.copyWith(
        instances: updated,
        totalStorageByApp: storageMap,
        isLoading: false,
      ));

      // Persist via repository (which handles Hive internally)
      await _appPickerRepository.persistInstances(updated);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Clone failed: $e',
        lastFailedAction: 'CloneNewApp:${event.packageName}',
      ));
    }
  }

  // ─── App Added from Picker ────────────────────────────────────────

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

    await _appPickerRepository.persistInstances(updated);
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
    } else if (action.startsWith('CloneNewApp:')) {
      final packageName = action.substring('CloneNewApp:'.length);
      add(CloneNewApp(packageName));
    } else if (action.startsWith('LaunchInstance:')) {
      final instanceId = action.substring('LaunchInstance:'.length);
      add(LaunchInstance(instanceId));
    }
  }
}
