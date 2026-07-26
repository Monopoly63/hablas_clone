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

    test('softInstanceWarningThreshold should be positive', () {
      expect(AppConstants.softInstanceWarningThreshold, greaterThan(0));
    });
  });

  group('AppTheme', () {
    test('oledBlack color should be #050505', () {
      expect(AppTheme.oledBlack, const Color(0xFF050505));
    });

    test('liquidCyan color should be #00F2FE', () {
      expect(AppTheme.liquidCyan, const Color(0xFF00F2FE));
    });

    test('cobaltBlue color should be #4FACFE', () {
      expect(AppTheme.cobaltBlue, const Color(0xFF4FACFE));
    });

    test('neonEmerald color should be #00FF87', () {
      expect(AppTheme.neonEmerald, const Color(0xFF00FF87));
    });

    test('buildDarkTheme should return ThemeData with dark brightness', () {
      final theme = AppTheme.buildDarkTheme();
      expect(theme.brightness, Brightness.dark);
    });

    test('buildDarkTheme should have oledBlack scaffold background', () {
      final theme = AppTheme.buildDarkTheme();
      expect(theme.scaffoldBackgroundColor, AppTheme.oledBlack);
    });
  });

  group('VirtualEngineException', () {
    test('should contain error message', () {
      const exception = VirtualEngineException('test error');
      expect(exception.message, 'test error');
      expect(exception.toString(), contains('test error'));
    });
  });

  group('InstanceStatus', () {
    test('fromString should parse correctly', () {
      expect(InstanceStatus.fromString('running'), InstanceStatus.running);
      expect(InstanceStatus.fromString('idle'), InstanceStatus.idle);
      expect(InstanceStatus.fromString('sleeping'), InstanceStatus.sleeping);
      expect(InstanceStatus.fromString('error'), InstanceStatus.error);
      expect(InstanceStatus.fromString('unknown'), InstanceStatus.idle);
    });

    test('toDisplayString should return readable names', () {
      expect(InstanceStatus.running.toDisplayString(), 'Running');
      expect(InstanceStatus.idle.toDisplayString(), 'Idle');
      expect(InstanceStatus.sleeping.toDisplayString(), 'Sleeping');
      expect(InstanceStatus.error.toDisplayString(), 'Error');
    });
  });

  group('InstalledAppInfo', () {
    test('should create from map', () {
      final map = {
        'packageName': 'com.whatsapp',
        'appName': 'WhatsApp',
        'iconPath': null,
        'versionName': '2.23',
        'isSystemApp': false,
      };
      final info = InstalledAppInfo.fromMap(map);
      expect(info.packageName, 'com.whatsapp');
      expect(info.appName, 'WhatsApp');
      expect(info.isSystemApp, false);
    });

    test('equality should be based on packageName', () {
      const info1 = InstalledAppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp');
      const info2 = InstalledAppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp Messenger');
      expect(info1, equals(info2));
    });
  });
}
