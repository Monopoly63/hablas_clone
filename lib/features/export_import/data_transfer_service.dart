import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../core/error/result.dart';
import '../../core/error/app_error.dart';

/// ─── Data Transfer Service — Export/Import clone data as JSON ──────
///
/// Allows users to backup their clone instances and icons before
/// uninstalling, then restore after reinstalling.
///
/// Export format (v1.x — no ZIP dependency):
///   - hablas_backup.json — List of VirtualInstance data + metadata
///   - icons/ — PNG icon files per package name (saved as separate files)
///
/// NOTE: ZIP compression removed for v1.5.x to avoid `archive` package
/// dependency issues. Will be re-added in v2.x when CI is stable.
///
class DataTransferService {
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Exports all clone data to a JSON file + icon files in a directory.
  Future<Result<String>> exportData() async {
    try {
      // 1. Load all instances from Hive
      final instancesBox = Hive.box<dynamic>('hablas_instances');
      final iconsBox = Hive.box<dynamic>('hablas_icons');

      final instances = instancesBox.values.toList();
      final iconEntries = iconsBox.toMap();

      // 2. Create export directory
      final exportDir = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory('${exportDir.path}/hablas_backup_$timestamp');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 3. Save instances as JSON
      final instancesList = instances.map((raw) {
        if (raw is Map<String, dynamic>) return raw;
        return {'id': raw.toString()};
      }).toList();

      final metadata = {
        'version': '1.5.1',
        'exportedAt': timestamp,
        'instanceCount': instances.length,
      };

      final backupJson = jsonEncode({
        'instances': instancesList,
        'metadata': metadata,
      });

      final jsonFile = File('${backupDir.path}/instances.json');
      await jsonFile.writeAsString(backupJson);

      // 4. Save icons as separate PNG files
      final iconsDir = Directory('${backupDir.path}/icons');
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }

      for (final entry in iconEntries.entries) {
        final packageName = entry.key.toString();
        final iconData = entry.value;
        if (iconData is List) {
          final bytes = Uint8List.fromList(iconData.cast<int>());
          final iconFile = File('${iconsDir.path}/$packageName.png');
          await iconFile.writeAsBytes(bytes);
        }
      }

      _logger.i('Exported ${instances.length} instances to ${backupDir.path}');
      return Result.ok(backupDir.path);
    } catch (e) {
      _logger.e('Export failed: $e');
      return Result.fail(AppError.unknown('Export failed: $e'));
    }
  }

  /// Imports clone data from a backup directory.
  Future<Result<int>> importData(String backupDirPath) async {
    try {
      final backupDir = Directory(backupDirPath);
      if (!await backupDir.exists()) {
        return Result.fail(AppError.persistence('import'));
      }

      // 1. Read JSON file
      final jsonFile = File('${backupDir.path}/instances.json');
      if (!await jsonFile.exists()) {
        return Result.fail(AppError.persistence('import'));
      }

      final jsonContent = await jsonFile.readAsString();
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;

      final importedInstances = (decoded['instances'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      // 2. Write to Hive
      final instancesBox = Hive.box<dynamic>('hablas_instances');
      final iconsBox = Hive.box<dynamic>('hablas_icons');

      for (final instance in importedInstances) {
        final id = instance['id'] as String?;
        if (id != null) {
          await instancesBox.put(id, instance);
        }
      }

      // 3. Restore icons
      final iconsDir = Directory('${backupDir.path}/icons');
      if (await iconsDir.exists()) {
        for (final iconFile in iconsDir.listSync()) {
          if (iconFile.path.endsWith('.png')) {
            final packageName = iconFile.path
                .replaceAll('${iconsDir.path}/', '')
                .replaceAll('.png', '');
            final bytes = await File(iconFile.path).readAsBytes();
            await iconsBox.put(packageName, bytes.toList());
          }
        }
      }

      _logger.i('Imported ${importedInstances.length} instances');
      return Result.ok(importedInstances.length);
    } catch (e) {
      _logger.e('Import failed: $e');
      return Result.fail(AppError.unknown('Import failed: $e'));
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Future<Directory> _getExportDirectory() async {
    // Try Downloads directory first
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) return downloadsDir;
    } catch (_) {}

    // Fallback: external storage
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) return externalDir;

    // Last fallback: temporary directory
    return await getTemporaryDirectory();
  }
}
