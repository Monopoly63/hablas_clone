import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hablas_virtual_studio/core/constants/app_constants.dart';
import 'package:hablas_virtual_studio/core/theme/app_theme.dart';
import 'package:hablas_virtual_studio/core/native_bridge/virtual_engine_bridge.dart';
import 'package:hablas_virtual_studio/core/error/result.dart';
import 'package:hablas_virtual_studio/core/error/app_error.dart';
import 'package:hablas_virtual_studio/features/dashboard/domain/virtual_instance.dart';
import 'package:hablas_virtual_studio/core/services/app_state_service.dart';

void main() {
  group('AppConstants', () {
    test('packageName should be com.hablas.studio', () {
      expect(AppConstants.packageName, 'com.hablas.studio');
    });
    test('version should be 2.0.0', () {
      expect(AppConstants.version, '2.0.0');
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
        'versionName': '2.22',
        'isSystemApp': false,
      });
      expect(info.packageName, 'com.whatsapp');
      expect(info.appName, 'WhatsApp');
      expect(info.isSystemApp, false);
    });
  });

  // ─── Result<T> Tests ─────────────────────────────────────────────────

  group('Result', () {
    test('Success is isSuccess', () {
      final result = Result<int>.ok(42);
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.data, 42);
      expect(result.error, null);
    });

    test('Failure is isError', () {
      final result = Result<int>.fail(AppError.unknown('test'));
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.data, null);
      expect(result.error!.type, AppErrorType.unknown);
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

  // ─── AppPhase Tests ──────────────────────────────────────────────────

  group('AppPhase', () {
    test('name returns correct strings', () {
      expect(AppPhase.onboarding.name, 'onboarding');
      expect(AppPhase.permissions.name, 'permissions');
      expect(AppPhase.lock.name, 'lock');
      expect(AppPhase.dashboard.name, 'dashboard');
    });

    test('displayName returns formatted strings', () {
      expect(AppPhase.onboarding.displayName, contains('Onboarding'));
      expect(AppPhase.dashboard.displayName, contains('Dashboard'));
    });
  });

  // ─── VirtualInstance Tests ──────────────────────────────────────────

  group('VirtualInstance', () {
    test('storageSizeFormatted formats bytes correctly', () {
      final small = VirtualInstance(
        id: 'test', packageName: 'com.test', appName: 'Test',
        instanceIndex: 1, customName: 'Test Clone',
        status: InstanceStatus.idle, storageSizeBytes: 500,
        createdAt: DateTime.now(),
      );
      expect(small.storageSizeFormatted, '500 B');

      final kb = small.copyWith(storageSizeBytes: 2048);
      expect(kb.storageSizeFormatted, '2.0 KB');
    });

    test('copyWith preserves identity', () {
      final original = VirtualInstance(
        id: 'test', packageName: 'com.test', appName: 'Test',
        instanceIndex: 1, customName: 'Test Clone',
        status: InstanceStatus.idle, storageSizeBytes: 0,
        createdAt: DateTime(2024, 1, 1),
      );
      final renamed = original.copyWith(customName: 'New Name');
      expect(renamed.id, original.id);
      expect(renamed.customName, 'New Name');
      expect(renamed.packageName, original.packageName);
    });
  });
}
