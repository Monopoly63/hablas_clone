import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hablas_virtual_studio/core/constants/app_constants.dart';
import 'package:hablas_virtual_studio/core/theme/app_theme.dart';
import 'package:hablas_virtual_studio/core/native_bridge/virtual_engine_bridge.dart';

void main() {
  group('AppConstants', () {
    test('appName should be Hablas Virtual Studio', () {
      expect(AppConstants.appName, 'Hablas Virtual Studio');
    });
    test('packageName should be com.hablas.studio', () {
      expect(AppConstants.packageName, 'com.hablas.studio');
    });
    test('version should be 1.0.0', () {
      expect(AppConstants.version, '1.0.0');
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
  });

  group('InstanceStatus', () {
    test('fromString parses correctly', () {
      expect(InstanceStatus.fromString('running'), InstanceStatus.running);
      expect(InstanceStatus.fromString('idle'), InstanceStatus.idle);
      expect(InstanceStatus.fromString('sleeping'), InstanceStatus.sleeping);
      expect(InstanceStatus.fromString('error'), InstanceStatus.error);
      expect(InstanceStatus.fromString('unknown'), InstanceStatus.idle);
    });
    test('toDisplayString returns names', () {
      expect(InstanceStatus.running.toDisplayString(), 'Running');
      expect(InstanceStatus.idle.toDisplayString(), 'Idle');
      expect(InstanceStatus.sleeping.toDisplayString(), 'Sleeping');
      expect(InstanceStatus.error.toDisplayString(), 'Error');
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
}
