import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../features/dashboard/domain/virtual_instance.dart';

/// ─── Instance Persistence Service — Hive-backed local storage ──────
///
/// Solves the #1 critical issue: cloned instances survive app restarts.
/// Stores VirtualInstance data + icon bytes (Uint8List) in Hive boxes.
///
/// Architecture:
///   - `instances` box: Maps instance ID → VirtualInstanceModel (Hive-adapted)
///   - `icons` box: Maps package name → icon bytes (Uint8List)
///   - `metadata` box: App-level metadata (last scan timestamp, etc.)
///
class InstancePersistenceService {
  static const String _instancesBoxName = 'hablas_instances';
  static const String _iconsBoxName = 'hablas_icons';
  static const String _metadataBoxName = 'hablas_metadata';

  late Box<VirtualInstanceModel> _instancesBox;
  late Box<Uint8List> _iconsBox;
  late Box<dynamic> _metadataBox;

  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  bool _isInitialized = false;

  /// Opens Hive boxes and registers adapters. Must be called before any CRUD.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Register adapter for VirtualInstanceModel
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(VirtualInstanceModelAdapter());
    }

    _instancesBox = await Hive.openBox<VirtualInstanceModel>(_instancesBoxName);
    _iconsBox = await Hive.openBox<Uint8List>(_iconsBoxName);
    _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);

    _isInitialized = true;
    _logger.i('Persistence initialized: ${_instancesBox.length} instances, ${_iconsBox.length} icons');
  }

  // ─── Instance CRUD ─────────────────────────────────────────────────

  /// Saves a VirtualInstance to Hive.
  Future<void> saveInstance(VirtualInstance instance, {Uint8List? iconBytes}) async {
    if (!_isInitialized) await initialize();

    final model = VirtualInstanceModel.fromDomain(instance);
    await _instancesBox.put(instance.id, model);

    // Also store icon bytes if provided
    if (iconBytes != null && iconBytes.isNotEmpty) {
      await _iconsBox.put(instance.packageName, iconBytes);
    }

    _logger.d('Saved instance: ${instance.id}');
  }

  /// Saves multiple instances at once (batch operation).
  Future<void> saveAllInstances(List<VirtualInstance> instances) async {
    if (!_isInitialized) await initialize();

    final Map<String, VirtualInstanceModel> batch = {};
    for (final instance in instances) {
      batch[instance.id] = VirtualInstanceModel.fromDomain(instance);
    }
    await _instancesBox.putAll(batch);

    _logger.d('Saved ${instances.length} instances');
  }

  /// Loads all persisted VirtualInstances from Hive.
  Future<List<VirtualInstance>> loadAllInstances() async {
    if (!_isInitialized) await initialize();

    final models = _instancesBox.values.toList();
    _logger.i('Loaded ${models.length} persisted instances');

    return models.map((model) => model.toDomain()).toList();
  }

  /// Deletes a single instance by ID.
  Future<void> deleteInstance(String instanceId) async {
    if (!_isInitialized) await initialize();

    await _instancesBox.delete(instanceId);
    _logger.d('Deleted instance: $instanceId');
  }

  /// Deletes all instances (nuke option).
  Future<void> deleteAllInstances() async {
    if (!_isInitialized) await initialize();

    await _instancesBox.clear();
    _logger.w('Cleared all instances');
  }

  // ─── Icon Persistence ──────────────────────────────────────────────

  /// Retrieves stored icon bytes for a package name.
  Uint8List? getIconBytes(String packageName) {
    if (!_isInitialized) return null;
    return _iconsBox.get(packageName);
  }

  /// Saves icon bytes for a package name.
  Future<void> saveIconBytes(String packageName, Uint8List bytes) async {
    if (!_isInitialized) await initialize();

    await _iconsBox.put(packageName, bytes);
    _logger.d('Saved icon for: $packageName (${bytes.length} bytes)');
  }

  /// Checks if we have cached icon for a package.
  bool hasIconCached(String packageName) {
    if (!_isInitialized) return false;
    return _iconsBox.containsKey(packageName);
  }

  // ─── Metadata ──────────────────────────────────────────────────────

  /// Records timestamp of last app scan.
  Future<void> setLastScanTimestamp(DateTime timestamp) async {
    if (!_isInitialized) await initialize();
    await _metadataBox.put('last_scan_ts', timestamp.millisecondsSinceEpoch);
  }

  /// Gets timestamp of last app scan.
  DateTime? getLastScanTimestamp() {
    if (!_isInitialized) return null;
    final ts = _metadataBox.get('last_scan_ts') as int?;
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Records whether permissions were fully granted at last check.
  Future<void> setPermissionsGranted(bool granted) async {
    if (!_isInitialized) await initialize();
    await _metadataBox.put('permissions_granted', granted);
  }

  bool? getPermissionsGranted() {
    if (!_isInitialized) return null;
    return _metadataBox.get('permissions_granted') as bool?;
  }

  // ─── Stats ─────────────────────────────────────────────────────────

  int get persistedInstanceCount => _isInitialized ? _instancesBox.length : 0;
  int get cachedIconCount => _isInitialized ? _iconsBox.length : 0;

  // ─── Health Check ──────────────────────────────────────────────────

  /// Compacts Hive boxes to reclaim disk space. Run periodically.
  Future<void> compact() async {
    if (!_isInitialized) return;
    await _instancesBox.compact();
    await _iconsBox.compact();
    await _metadataBox.compact();
    _logger.i('Hive boxes compacted');
  }
}

// ─── Hive-Adapted Model ──────────────────────────────────────────────────

/// Hive-compatible model for VirtualInstance persistence.
/// Uses HiveField annotations for binary serialization.
@HiveType(typeId: 100)
class VirtualInstanceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String packageName;

  @HiveField(2)
  String appName;

  @HiveField(3)
  int instanceIndex;

  @HiveField(4)
  String customName;

  @HiveField(5)
  String status; // Stored as string for Hive compatibility

  @HiveField(6)
  int storageSizeBytes;

  @HiveField(7)
  int createdAtMs; // Stored as millis for Hive compatibility

  @HiveField(8)
  int? lastActiveAtMs;

  @HiveField(9)
  String? iconPath;

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

  /// Converts from domain VirtualInstance.
  factory VirtualInstanceModel.fromDomain(VirtualInstance instance) {
    return VirtualInstanceModel(
      id: instance.id,
      packageName: instance.packageName,
      appName: instance.appName,
      instanceIndex: instance.instanceIndex,
      customName: instance.customName,
      status: instance.status.name, // enum → string
      storageSizeBytes: instance.storageSizeBytes,
      createdAtMs: instance.createdAt.millisecondsSinceEpoch,
      lastActiveAtMs: instance.lastActiveAt?.millisecondsSinceEpoch,
      iconPath: instance.iconPath,
    );
  }

  /// Converts to domain VirtualInstance.
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
}

/// Hive adapter for VirtualInstanceModel binary serialization.
class VirtualInstanceModelAdapter extends TypeAdapter<VirtualInstanceModel> {
  @override
  final int typeId = 100;

  @override
  VirtualInstanceModel read(BinaryReader reader) {
    // Read all fields — Hive BinaryReader doesn't have readIntOrNull/readStringOrNull
    // So we use sentinel values: 0 for null int, '' for null string
    final id = reader.readString();
    final packageName = reader.readString();
    final appName = reader.readString();
    final instanceIndex = reader.readInt();
    final customName = reader.readString();
    final status = reader.readString();
    final storageSizeBytes = reader.readInt();
    final createdAtMs = reader.readInt();
    final lastActiveAtMsRaw = reader.readInt(); // 0 = null
    final iconPathRaw = reader.readString(); // '' = null

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
    writer.writeInt(obj.lastActiveAtMs ?? 0); // Sentinel: 0 = null
    writer.writeString(obj.iconPath ?? ''); // Sentinel: '' = null
  }
}
