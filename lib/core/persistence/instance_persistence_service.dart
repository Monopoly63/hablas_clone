import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../features/dashboard/domain/virtual_instance.dart';

/// ─── Instance Persistence Service — Hive-backed local storage ──────
///
/// FIXED (v1.3.1):
///   1. Icons box uses `Box<dynamic>` not `Box<Uint8List>` — Hive can't handle Uint8List as typed box
///   2. All operations auto-initialize if needed
///   3. Try-catch on every operation — NEVER throws, always returns fallback
///   4. Icon bytes stored as `List<int>` which Hive handles naturally
///
class InstancePersistenceService {
  static const String _instancesBoxName = 'hablas_instances';
  static const String _iconsBoxName = 'hablas_icons';
  static const String _metadataBoxName = 'hablas_metadata';

  late Box<dynamic> _instancesBox;
  late Box<dynamic> _iconsBox;
  late Box<dynamic> _metadataBox;

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  bool _isInitialized = false;

  /// Opens Hive boxes. Must be called before any CRUD.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register adapter for VirtualInstanceModel
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(VirtualInstanceModelAdapter());
    }

    // Use dynamic boxes — more reliable than typed boxes for complex types
    _instancesBox = await Hive.openBox<dynamic>(_instancesBoxName);
    _iconsBox = await Hive.openBox<dynamic>(_iconsBoxName);
    _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);

    _isInitialized = true;
    _logger.i('Persistence initialized: ${_instancesBox.length} instances, ${_iconsBox.length} icons');
  }

  // ─── Instance CRUD ─────────────────────────────────────────────────

  /// Saves a VirtualInstance to Hive.
  Future<void> saveInstance(VirtualInstance instance, {Uint8List? iconBytes}) async {
    try {
      if (!_isInitialized) await initialize();

      final model = VirtualInstanceModel.fromDomain(instance);
      await _instancesBox.put(instance.id, model.toMap());

      if (iconBytes != null && iconBytes.isNotEmpty) {
        await _iconsBox.put(instance.packageName, iconBytes.toList());
      }

      _logger.d('Saved instance: ${instance.id}');
    } catch (e) {
      _logger.e('Failed to save instance: $e');
      // NEVER throw — persistence failure shouldn't break UX
    }
  }

  /// Saves multiple instances at once.
  Future<void> saveAllInstances(List<VirtualInstance> instances) async {
    try {
      if (!_isInitialized) await initialize();

      final Map<String, dynamic> batch = {};
      for (final instance in instances) {
        batch[instance.id] = VirtualInstanceModel.fromDomain(instance).toMap();
      }
      await _instancesBox.putAll(batch);

      _logger.d('Saved ${instances.length} instances');
    } catch (e) {
      _logger.e('Failed to save instances: $e');
    }
  }

  /// Loads all persisted VirtualInstances from Hive.
  Future<List<VirtualInstance>> loadAllInstances() async {
    try {
      if (!_isInitialized) await initialize();

      final models = _instancesBox.values.toList();
      _logger.i('Loaded ${models.length} persisted instances');

      return models.map((raw) {
        if (raw is VirtualInstanceModel) {
          return raw.toDomain();
        } else if (raw is Map<String, dynamic>) {
          return VirtualInstanceModel.fromMap(raw).toDomain();
        }
        // Skip corrupted entries
        return null;
      }).whereType<VirtualInstance>().toList();
    } catch (e) {
      _logger.e('Failed to load instances: $e');
      return [];
    }
  }

  /// Deletes a single instance by ID.
  Future<void> deleteInstance(String instanceId) async {
    try {
      if (!_isInitialized) await initialize();
      await _instancesBox.delete(instanceId);
      _logger.d('Deleted instance: $instanceId');
    } catch (e) {
      _logger.e('Failed to delete instance: $e');
    }
  }

  /// Deletes all instances.
  Future<void> deleteAllInstances() async {
    try {
      if (!_isInitialized) await initialize();
      await _instancesBox.clear();
      _logger.w('Cleared all instances');
    } catch (e) {
      _logger.e('Failed to clear instances: $e');
    }
  }

  // ─── Icon Persistence ──────────────────────────────────────────────

  /// Retrieves stored icon bytes for a package name.
  Uint8List? getIconBytes(String packageName) {
    try {
      if (!_isInitialized) return null;
      final raw = _iconsBox.get(packageName);
      if (raw == null) return null;
      if (raw is Uint8List) return raw;
      if (raw is List) return Uint8List.fromList(raw.cast<int>());
      return null;
    } catch (e) {
      _logger.e('Failed to get icon: $e');
      return null;
    }
  }

  /// Saves icon bytes for a package name.
  Future<void> saveIconBytes(String packageName, Uint8List bytes) async {
    try {
      if (!_isInitialized) await initialize();
      // Store as List<int> — Hive handles it reliably
      await _iconsBox.put(packageName, bytes.toList());
      _logger.d('Saved icon for: $packageName (${bytes.length} bytes)');
    } catch (e) {
      _logger.e('Failed to save icon: $e');
      // NEVER throw — icon persistence failure shouldn't break clone flow
    }
  }

  /// Checks if we have cached icon for a package.
  bool hasIconCached(String packageName) {
    try {
      if (!_isInitialized) return false;
      return _iconsBox.containsKey(packageName);
    } catch (_) {
      return false;
    }
  }

  // ─── Metadata ──────────────────────────────────────────────────────

  Future<void> setLastScanTimestamp(DateTime timestamp) async {
    try {
      if (!_isInitialized) await initialize();
      await _metadataBox.put('last_scan_ts', timestamp.millisecondsSinceEpoch);
    } catch (_) {}
  }

  DateTime? getLastScanTimestamp() {
    try {
      if (!_isInitialized) return null;
      final ts = _metadataBox.get('last_scan_ts') as int?;
      return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setPermissionsGranted(bool granted) async {
    try {
      if (!_isInitialized) await initialize();
      await _metadataBox.put('permissions_granted', granted);
    } catch (_) {}
  }

  bool? getPermissionsGranted() {
    try {
      if (!_isInitialized) return null;
      return _metadataBox.get('permissions_granted') as bool?;
    } catch (_) {
      return null;
    }
  }

  int get persistedInstanceCount => _isInitialized ? _instancesBox.length : 0;
  int get cachedIconCount => _isInitialized ? _iconsBox.length : 0;

  Future<void> compact() async {
    try {
      if (!_isInitialized) return;
      await _instancesBox.compact();
      await _iconsBox.compact();
      await _metadataBox.compact();
    } catch (_) {}
  }
}

// ─── Hive-Adapted Model ──────────────────────────────────────────────────

/// VirtualInstanceModel stored as Map in Hive (not as custom HiveObject).
/// This is more reliable than TypeAdapter for complex models.
class VirtualInstanceModel {
  final String id;
  final String packageName;
  final String appName;
  final int instanceIndex;
  final String customName;
  final String status;
  final int storageSizeBytes;
  final int createdAtMs;
  final int? lastActiveAtMs;
  final String? iconPath;

  VirtualInstanceModel({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.instanceIndex,
    required this.customName,
    required this.status,
    required this.storageSizeBytes,
    required this.createdAtMs,
    this.lastActiveAtMs,
    this.iconPath,
  });

  factory VirtualInstanceModel.fromDomain(VirtualInstance instance) {
    return VirtualInstanceModel(
      id: instance.id,
      packageName: instance.packageName,
      appName: instance.appName,
      instanceIndex: instance.instanceIndex,
      customName: instance.customName,
      status: instance.status.name,
      storageSizeBytes: instance.storageSizeBytes,
      createdAtMs: instance.createdAt.millisecondsSinceEpoch,
      lastActiveAtMs: instance.lastActiveAt?.millisecondsSinceEpoch,
      iconPath: instance.iconPath,
    );
  }

  VirtualInstance toDomain() {
    return VirtualInstance(
      id: id,
      packageName: packageName,
      appName: appName,
      instanceIndex: instanceIndex,
      customName: customName,
      status: InstanceStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => InstanceStatus.idle,
      ),
      storageSizeBytes: storageSizeBytes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      lastActiveAt: lastActiveAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActiveAtMs!)
          : null,
      iconPath: iconPath,
    );
  }

  /// Convert to Map for Hive storage (most reliable format).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'instanceIndex': instanceIndex,
      'customName': customName,
      'status': status,
      'storageSizeBytes': storageSizeBytes,
      'createdAtMs': createdAtMs,
      'lastActiveAtMs': lastActiveAtMs ?? 0,
      'iconPath': iconPath ?? '',
    };
  }

  /// Convert from Map (Hive storage).
  factory VirtualInstanceModel.fromMap(Map<String, dynamic> map) {
    return VirtualInstanceModel(
      id: map['id'] as String,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      instanceIndex: map['instanceIndex'] as int,
      customName: map['customName'] as String,
      status: map['status'] as String,
      storageSizeBytes: map['storageSizeBytes'] as int,
      createdAtMs: map['createdAtMs'] as int,
      lastActiveAtMs: (map['lastActiveAtMs'] as int) == 0 ? null : map['lastActiveAtMs'] as int,
      iconPath: (map['iconPath'] as String).isEmpty ? null : map['iconPath'] as String,
    );
  }
}

/// TypeAdapter kept for compatibility but we now prefer Map storage.
class VirtualInstanceModelAdapter extends TypeAdapter<VirtualInstanceModel> {
  @override
  final int typeId = 100;

  @override
  VirtualInstanceModel read(BinaryReader reader) {
    final id = reader.readString();
    final packageName = reader.readString();
    final appName = reader.readString();
    final instanceIndex = reader.readInt();
    final customName = reader.readString();
    final status = reader.readString();
    final storageSizeBytes = reader.readInt();
    final createdAtMs = reader.readInt();
    final lastActiveAtMsRaw = reader.readInt();
    final iconPathRaw = reader.readString();

    return VirtualInstanceModel(
      id: id,
      packageName: packageName,
      appName: appName,
      instanceIndex: instanceIndex,
      customName: customName,
      status: status,
      storageSizeBytes: storageSizeBytes,
      createdAtMs: createdAtMs,
      lastActiveAtMs: lastActiveAtMsRaw == 0 ? null : lastActiveAtMsRaw,
      iconPath: iconPathRaw.isEmpty ? null : iconPathRaw,
    );
  }

  @override
  void write(BinaryWriter writer, VirtualInstanceModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.packageName);
    writer.writeString(obj.appName);
    writer.writeInt(obj.instanceIndex);
    writer.writeString(obj.customName);
    writer.writeString(obj.status);
    writer.writeInt(obj.storageSizeBytes);
    writer.writeInt(obj.createdAtMs);
    writer.writeInt(obj.lastActiveAtMs ?? 0);
    writer.writeString(obj.iconPath ?? '');
  }
}
