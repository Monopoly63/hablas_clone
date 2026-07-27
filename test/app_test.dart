import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hablas_virtual_studio/core/constants/app_constants.dart';
import 'package:hablas_virtual_studio/core/theme/app_theme.dart';
import 'package:hablas_virtual_studio/core/native_bridge/virtual_engine_bridge.dart';
import 'package:hablas_virtual_studio/core/error/result.dart';
import 'package:hablas_virtual_studio/core/error/app_error.dart';
import 'package:hablas_virtual_studio/features/dashboard/domain/virtual_instance.dart';

void main() {
  group('AppConstants', () {
    test('packageName should be com.hablas.studio', () {
      expect(AppConstants.packageName, 'com.hablas.studio');
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

  group('InstanceStatus', () {
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

  // ─── Result Type Tests ───────────────────────────────────────────────

  group('Result', () {
    test('Success holds data', () {
      final result = Result<int>.ok(42);
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.data, 42);
      expect(result.error, null);
    });

    test('Failure holds error', () {
      final result = Result<int>.fail(AppError.cloneFailed('com.whatsapp', 'test'));
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.data, null);
      expect(result.error!.type, AppErrorType.cloneFailed);
    });

    test('map transforms success data', () {
      final result = Result<int>.ok(42);
      final mapped = result.map((data) => data.toString());
      expect(mapped.isSuccess, true);
      expect(mapped.data, '42');
    });

    test('map propagates failure', () {
      final result = Result<int>.fail(AppError.unknown('test'));
      final mapped = result.map((data) => data.toString());
      expect(mapped.isError, true);
      expect(mapped.error!.type, AppErrorType.unknown);
    });

    test('guard wraps successful call', () {
      final result = Result.guard(() => 42);
      expect(result.isSuccess, true);
      expect(result.data, 42);
    });

    test('guard catches exception', () {
      final result = Result<int>.guard(() => throw Exception('boom'));
      expect(result.isError, true);
      expect(result.error!.type, AppErrorType.unknown);
    });

    test('getOrDefault returns fallback', () {
      final failure = Result<int>.fail(AppError.unknown('test'));
      expect(failure.getOrDefault(0), 0);

      final success = Result<int>.ok(42);
      expect(success.getOrDefault(0), 42);
    });
  });

  // ─── AppError Tests ──────────────────────────────────────────────────

  group('AppError', () {
    test('factory constructors create correct types', () {
      final perm = AppError.permission('QUERY_ALL_PACKAGES');
      expect(perm.type, AppErrorType.permission);
      expect(perm.isRetryable, true);

      final clone = AppError.cloneFailed('com.whatsapp', 'not compatible');
      expect(clone.type, AppErrorType.cloneFailed);
      expect(clone.isRetryable, true);

      final compat = AppError.notCompatible('com.whatsapp');
      expect(compat.type, AppErrorType.notCompatible);
      expect(compat.isRetryable, false);
    });

    test('displayMessage returns Arabic', () {
      final perm = AppError.permission('QUERY_ALL_PACKAGES');
      expect(perm.displayMessage, contains('الإذونات'));

      final clone = AppError.cloneFailed('com.whatsapp', 'test');
      expect(clone.displayMessage, contains('فشل'));
    });

    test('displayMessageEn returns English', () {
      final perm = AppError.permission('QUERY_ALL_PACKAGES');
      expect(perm.displayMessageEn, contains('Permission'));

      final clone = AppError.cloneFailed('com.whatsapp', 'test');
      expect(clone.displayMessageEn, contains('Failed'));
    });

    test('emoji returns correct icons', () {
      expect(AppError.permission('x').emoji, '🔐');
      expect(AppError.cloneFailed('x', 'y').emoji, '❌');
      expect(AppError.engineError('x').emoji, '⚡');
      expect(AppError.unknown('x').emoji, '⚠️');
    });
  });
}
