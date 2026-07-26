import 'package:equatable/equatable.dart';

/// Domain entity representing a virtual app instance.
class VirtualInstance extends Equatable {
  final String id;
  final String packageName;
  final String appName;
  final int instanceIndex;
  final String customName;
  final InstanceStatus status;
  final int storageSizeBytes;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String? iconPath;

  const VirtualInstance({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.instanceIndex,
    required this.customName,
    required this.status,
    required this.storageSizeBytes,
    required this.createdAt,
    this.lastActiveAt,
    this.iconPath,
  });

  VirtualInstance copyWith({
    String? customName,
    InstanceStatus? status,
    int? storageSizeBytes,
    DateTime? lastActiveAt,
  }) {
    return VirtualInstance(
      id: id,
      packageName: packageName,
      appName: appName,
      instanceIndex: instanceIndex,
      customName: customName ?? this.customName,
      status: status ?? this.status,
      storageSizeBytes: storageSizeBytes ?? this.storageSizeBytes,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      iconPath: iconPath,
    );
  }

  /// Human-readable storage size.
  String get storageSizeFormatted {
    if (storageSizeBytes < 1024) return '$storageSizeBytes B';
    if (storageSizeBytes < 1048576) return '${(storageSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (storageSizeBytes < 1073741824) return '${(storageSizeBytes / 1048576).toStringAsFixed(1)} MB';
    return '${(storageSizeBytes / 1073741824).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [id, packageName, instanceIndex, status, storageSizeBytes, customName];
}

enum InstanceStatus {
  running,
  idle,
  sleeping,
  error;

  String get displayName => switch (this) {
    InstanceStatus.running => 'Running',
    InstanceStatus.idle => 'Idle',
    InstanceStatus.sleeping => 'Sleeping',
    InstanceStatus.error => 'Error',
  };

  String get emoji => switch (this) {
    InstanceStatus.running => '🟢',
    InstanceStatus.idle => '🔵',
    InstanceStatus.sleeping => '🌙',
    InstanceStatus.error => '🔴',
  };
}
