import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hablas_virtual_studio/core/constants/app_constants.dart';
import 'package:hablas_virtual_studio/core/theme/app_theme.dart';
import 'package:hablas_virtual_studio/core/native_bridge/virtual_engine_bridge.dart';
import 'package:hablas_virtual_studio/features/dashboard/domain/virtual_instance.dart';
import 'package:hablas_virtual_studio/core/persistence/instance_persistence_service.dart';

void main() {
  group('AppConstants', () {
    test('appName should be Hablas Clone', () {
      expect(AppConstants.appName, 'Hablas Clone');
    });
    test('packageName should be com.hablas.studio', () {
      expect(AppConstants.packageName, 'com.hablas.studio');
    });
    test('sandboxBasePath should contain com.hablas.studio', () {
      expect(AppConstants.sandboxBasePath, contains('com.hablas.studio'));
    });
  });

  group('AppTheme', () {
    test('oledBlack is #050505', () {
      expect(AppTheme.oledBlack, const Color(0xFF050505));
    });
    test('liquidCyan is #00F2FE', () {
      expect(AppTheme.liquidCyan, const Color(0xFF00F2FE));
    });
    test('cobaltBlue is #4FACFE', () {
      expect(AppTheme.cobaltBlue, const Color(0xFF4FACFE));
    });
    test('neonEmerald is #00FF87', () {
      expect(AppTheme.neonEmerald, const Color(0xFF00FF87));
    });
    test('buildDarkTheme returns dark theme', () {
      final theme = AppTheme.buildDarkTheme();
      expect(theme.brightness, Brightness.dark);
    });
    test('buildDarkTheme has oledBlack scaffold', () {
      final theme = AppTheme.buildDarkTheme();
      expect(theme.scaffoldBackgroundColor, AppTheme.oledBlack);
    });
  });

  group('VirtualEngineException', () {
    test('contains error message', () {
      const exception = VirtualEngineException('test error');
      expect(exception.message, 'test error');
      expect(exception.toString(), contains('test error'));
    });
    test('isRetryable flag works', () {
      const retryable = VirtualEngineException('network error', isRetryable: true);
      const permanent = VirtualEngineException('invalid package', isRetryable: false);
      expect(retryable.isRetryable, true);
      expect(permanent.isRetryable, false);
    });
  });

  group('InstanceStatus (domain model)', () {
    test('displayName returns correct names', () {
      expect(InstanceStatus.running.displayName, 'Running');
      expect(InstanceStatus.idle.displayName, 'Idle');
      expect(InstanceStatus.sleeping.displayName, 'Sleeping');
      expect(InstanceStatus.error.displayName, 'Error');
    });
    test('emoji returns correct symbols', () {
      expect(InstanceStatus.running.emoji, '🟢');
      expect(InstanceStatus.idle.emoji, '🔵');
      expect(InstanceStatus.sleeping.emoji, '🌙');
      expect(InstanceStatus.error.emoji, '🔴');
    });
    test('name property matches string values', () {
      expect(InstanceStatus.running.name, 'running');
      expect(InstanceStatus.idle.name, 'idle');
      expect(InstanceStatus.sleeping.name, 'sleeping');
      expect(InstanceStatus.error.name, 'error');
    });
  });

  group('InstalledAppInfo', () {
    test('fromMap creates correctly', () {
      final info = InstalledAppInfo.fromMap({
        'packageName': 'com.whatsapp',
        'appName': 'WhatsApp',
        'iconPath': null,
        'versionName': '2.23',
        'isSystemApp': false,
      });
      expect(info.packageName, 'com.whatsapp');
      expect(info.appName, 'WhatsApp');
    });
    test('equality is based on packageName', () {
      const a = InstalledAppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp');
      const b = InstalledAppInfo(packageName: 'com.whatsapp', appName: 'WA');
      expect(a, equals(b));
    });
  });

  group('VirtualInstanceModel', () {
    test('fromDomain converts correctly', () {
      final instance = VirtualInstance(
        id: 'com.whatsapp_1',
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        instanceIndex: 1,
        customName: 'WhatsApp — Clone 1',
        status: InstanceStatus.idle,
        storageSizeBytes: 0,
        createdAt: DateTime(2024, 1, 1),
      );
      final model = VirtualInstanceModel.fromDomain(instance);
      expect(model.id, 'com.whatsapp_1');
      expect(model.packageName, 'com.whatsapp');
      expect(model.status, 'idle');
      expect(model.storageSizeBytes, 0);
    });
    test('toDomain converts back correctly', () {
      final model = VirtualInstanceModel(
        id: 'com.whatsapp_1',
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        instanceIndex: 1,
        customName: 'WhatsApp — Clone 1',
        status: 'idle',
        storageSizeBytes: 0,
        createdAtMs: DateTime(2024, 1, 1).millisecondsSinceEpoch,
      );
      final domain = model.toDomain();
      expect(domain.id, 'com.whatsapp_1');
      expect(domain.packageName, 'com.whatsapp');
      expect(domain.status, InstanceStatus.idle);
      expect(domain.storageSizeBytes, 0);
    });
    test('round-trip preserves data', () {
      final original = VirtualInstance(
        id: 'org.telegram_2',
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        instanceIndex: 2,
        customName: 'Telegram — Clone 2',
        status: InstanceStatus.running,
        storageSizeBytes: 1024,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      final model = VirtualInstanceModel.fromDomain(original);
      final restored = model.toDomain();
      expect(restored.id, original.id);
      expect(restored.packageName, original.packageName);
      expect(restored.customName, original.customName);
      expect(restored.status, original.status);
      expect(restored.storageSizeBytes, original.storageSizeBytes);
    });
  });

  group('VirtualInstanceInfo', () {
    test('fromMap creates correctly with status string', () {
      final info = VirtualInstanceInfo.fromMap({
        'packageName': 'com.whatsapp',
        'instanceId': 1,
        'customName': 'WhatsApp Clone 1',
        'status': 'running',
        'storageSizeBytes': 512,
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
      });
      expect(info.packageName, 'com.whatsapp');
      expect(info.instanceId, 1);
      expect(info.status, InstanceStatus.running);
      expect(info.storageSizeBytes, 512);
    });
    test('fromMap defaults to idle for unknown status', () {
      final info = VirtualInstanceInfo.fromMap({
        'packageName': 'com.whatsapp',
        'instanceId': 1,
        'customName': 'WhatsApp Clone 1',
        'status': 'unknown_status',
        'storageSizeBytes': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      expect(info.status, InstanceStatus.idle);
    });
  });

  group('VirtualInstance', () {
    test('storageSizeFormatted formats correctly', () {
      final small = VirtualInstance(
        id: 'test_1', packageName: 'test', appName: 'test',
        instanceIndex: 1, customName: 'test', status: InstanceStatus.idle,
        storageSizeBytes: 512, createdAt: DateTime.now(),
      );
      expect(small.storageSizeFormatted, '512 B');

      final kb = small.copyWith(storageSizeBytes: 1536);
      expect(kb.storageSizeFormatted, '1.5 KB');

      final mb = small.copyWith(storageSizeBytes: 1048576);
      expect(mb.storageSizeFormatted, '1.0 MB');
    });

    test('copyWith preserves identity fields', () {
      final original = VirtualInstance(
        id: 'test_1', packageName: 'test', appName: 'test',
        instanceIndex: 1, customName: 'test', status: InstanceStatus.idle,
        storageSizeBytes: 0, createdAt: DateTime.now(),
      );
      final modified = original.copyWith(customName: 'New Name', status: InstanceStatus.running);
      expect(modified.id, original.id);
      expect(modified.packageName, original.packageName);
      expect(modified.customName, 'New Name');
      expect(modified.status, InstanceStatus.running);
    });
  });
}
