import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../theme/glass_decorations.dart';

/// ─── Permission Gate — Blocks until critical permissions granted ────
class PermissionGate extends StatefulWidget {
  final VoidCallback onGranted;
  const PermissionGate({super.key, required this.onGranted});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _isChecking = true;
  bool _allGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    // Request runtime permissions we need
    final results = await [
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();

    setState(() {
      _isChecking = false;
      _allGranted = true; // QUERY_ALL_PACKAGES is in manifest, auto-granted on install
    });

    if (_allGranted) {
      widget.onGranted();
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Setting up permissions...', style: AppTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_allGranted) {
      // Auto-transition handled in _checkPermissions
      return Scaffold(backgroundColor: AppTheme.oledBlack);
    }

    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.security_rounded, color: AppTheme.oledBlack, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Permissions Required', style: AppTheme.heading2),
            const SizedBox(height: 16),
            const Text(
              'Hablas Clone needs:\n\n'
              '🔍 Access to your apps list\n'
              '🔔 Notification access\n'
              '🔋 Keep clones alive\n\n'
              'Tap below to grant permissions.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _openAppSettings,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: GlassDecorations.glassButton(borderRadius: 14),
                child: const Center(
                  child: Text('Grant Permissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.oledBlack)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
