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

// ─── State ───────────────────────────────────────────────────────────────

class DashboardState extends Equatable {
  final List<VirtualInstance> instances;
  final bool isLoading;
  final String? error;
  final Map<String, int> totalStorageByApp; // package → total bytes

  DashboardState({
    this.instances = const [],
    this.isLoading = false,
    this.error,
    this.totalStorageByApp = const {},
  });

  DashboardState copyWith({
    List<VirtualInstance>? instances,
    bool? isLoading,
    String? error,
    Map<String, int>? totalStorageByApp,
  }) {
    return DashboardState(
      instances: instances ?? this.instances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalStorageByApp: totalStorageByApp ?? this.totalStorageByApp,
    );
  }

  /// Group instances by their parent package.
  Map<String, List<VirtualInstance>> get groupedByPackage {
    final map = <String, List<VirtualInstance>>{};
    for (final instance in instances) {
      (map[instance.packageName] ?? []).add(instance);
    }
    return map;
  }

  int get totalInstanceCount => instances.length;

  int get runningInstanceCount => instances.where((i) => i.status == InstanceStatus.running).length;

  int get totalStorageBytes => totalStorageByApp.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [instances, isLoading, error, totalStorageByApp];
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
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // Load persisted instances from local storage
      final instances = await _appPickerRepository.loadPersistedInstances();
      final storageMap = <String, int>{};
      for (final instance in instances) {
        storageMap[instance.packageName] =
            (storageMap[instance.packageName] ?? 0) + instance.storageSizeBytes;
      }
      emit(state.copyWith(
        instances: instances,
        isLoading: false,
        totalStorageByApp: storageMap,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshDashboard(RefreshDashboard event, Emitter<DashboardState> emit) async {
    // Re-fetch storage sizes from native engine
    try {
      final updatedInstances = <VirtualInstance>[];
      for (final instance in state.instances) {
        final size = await _appPickerRepository.getStorageSize(
          instance.packageName,
          instance.instanceIndex,
        );
        updatedInstances.add(instance.copyWith(storageSizeBytes: size));
      }
      final storageMap = <String, int>{};
      for (final instance in updatedInstances) {
        storageMap[instance.packageName] =
            (storageMap[instance.packageName] ?? 0) + instance.storageSizeBytes;
      }
      emit(state.copyWith(
        instances: updatedInstances,
        totalStorageByApp: storageMap,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLaunchInstance(LaunchInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
      orElse: () => throw StateError('Instance not found'),
    );
    final success = await _appPickerRepository.launchInstance(
      instance.packageName,
      instance.instanceIndex,
    );
    if (success) {
      final updated = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(status: InstanceStatus.running, lastActiveAt: DateTime.now());
        }
        return i;
      }).toList();
      emit(state.copyWith(instances: updated));
    }
  }

  Future<void> _onTerminateInstance(TerminateInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
      orElse: () => throw StateError('Instance not found'),
    );
    final success = await _appPickerRepository.terminateInstance(
      instance.packageName,
      instance.instanceIndex,
    );
    if (success) {
      final updated = state.instances.map((i) {
        if (i.id == event.instanceId) {
          return i.copyWith(status: InstanceStatus.idle);
        }
        return i;
      }).toList();
      emit(state.copyWith(instances: updated));
    }
  }

  Future<void> _onDeleteInstance(DeleteInstance event, Emitter<DashboardState> emit) async {
    final instance = state.instances.firstWhere(
      (i) => i.id == event.instanceId,
    );
    await _appPickerRepository.deleteInstance(
      instance.packageName,
      instance.instanceIndex,
    );
    final updated = state.instances.where((i) => i.id != event.instanceId).toList();
    final storageMap = <String, int>{};
    for (final inst in updated) {
      storageMap[inst.packageName] =
          (storageMap[inst.packageName] ?? 0) + inst.storageSizeBytes;
    }
    emit(state.copyWith(instances: updated, totalStorageByApp: storageMap));
  }

  Future<void> _onRenameInstance(RenameInstance event, Emitter<DashboardState> emit) async {
    final updated = state.instances.map((i) {
      if (i.id == event.instanceId) {
        return i.copyWith(customName: event.newName);
      }
      return i;
    }).toList();
    emit(state.copyWith(instances: updated));
    await _appPickerRepository.persistInstances(updated);
  }

  Future<void> _onCloneNewApp(CloneNewApp event, Emitter<DashboardState> emit) async {
    try {
      final instanceId = await _appPickerRepository.createInstance(event.packageName);
      final appInfo = await _appPickerRepository.getAppInfo(event.packageName);
      final newInstance = VirtualInstance(
        id: '${event.packageName}_$instanceId',
        packageName: event.packageName,
        appName: appInfo.appName,
        instanceIndex: instanceId,
        customName: '${appInfo.appName} — Instance $instanceId',
        status: InstanceStatus.idle,
        storageSizeBytes: 0,
        createdAt: DateTime.now(),
        iconPath: appInfo.iconPath,
      );
      final updated = [...state.instances, newInstance];
      final storageMap = <String, int>{};
      for (final inst in updated) {
        storageMap[inst.packageName] =
            (storageMap[inst.packageName] ?? 0) + inst.storageSizeBytes;
      }
      emit(state.copyWith(instances: updated, totalStorageByApp: storageMap));
      await _appPickerRepository.persistInstances(updated);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onAppAddedFromPicker(AppAddedFromPicker event, Emitter<DashboardState> emit) async {
    final newInstance = VirtualInstance(
      id: '${event.packageName}_${event.instanceId}',
      packageName: event.packageName,
      appName: event.appName,
      instanceIndex: event.instanceId,
      customName: '$event.appName — Instance $event.instanceId',
      status: InstanceStatus.idle,
      storageSizeBytes: 0,
      createdAt: DateTime.now(),
    );
    final updated = [...state.instances, newInstance];
    final storageMap = <String, int>{};
    for (final inst in updated) {
      storageMap[inst.packageName] =
          (storageMap[inst.packageName] ?? 0) + inst.storageSizeBytes;
    }
    emit(state.copyWith(instances: updated, totalStorageByApp: storageMap));
    await _appPickerRepository.persistInstances(updated);
  }
}
