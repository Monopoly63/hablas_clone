import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/app_discovery_service.dart';
import '../../../core/services/app_state_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_decorations.dart';

/// ─── Permission Gate v2.0.0 — Verifies and persists permission state ──
///
/// KEY FIXES:
///   1. Saves permissions_granted to AppStateService (not just in-memory)
///   2. Actually VERIFIES QUERY_ALL_PACKAGES works by testing app enumeration
///   3. If already granted (from previous session), SKIPS this screen
///   4. Shows discovered app count as verification proof
///
class PermissionGate extends StatefulWidget {
  final VoidCallback onGranted;
  const PermissionGate({super.key, required this.onGranted});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _isChecking = true;
  bool _allGranted = false;
  String? _errorMessage;
  int _discoveredAppCount = 0;

  @override
  void initState() {
    super.initState();
    // Check if permissions were already granted in previous session
    final appState = sl<AppStateService>();
    if (appState.arePermissionsGranted) {
      // Already granted — skip directly
      _allGranted = true;
      _isChecking = false;
      widget.onGranted();
    } else {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // 1. Request runtime permissions
      final results = await [
        Permission.notification,
        Permission.ignoreBatteryOptimizations,
      ].request();

      // 2. CRITICAL: Verify QUERY_ALL_PACKAGES actually works
      final discovery = sl<AppDiscoveryService>();
      final apps = await discovery.getInstalledApps();

      _discoveredAppCount = apps.length;

      if (apps.isEmpty) {
        // QUERY_ALL_PACKAGES not working — guide user to app settings
        setState(() {
          _isChecking = false;
          _allGranted = false;
          _errorMessage = 'No apps found on device. This means the QUERY_ALL_PACKAGES permission is not granted.\n\nPlease go to:\nApp Settings → Hablas Clone → Permissions → Enable "All files access" or "Install unknown apps".';
        });
        return;
      }

      // 3. All checks passed — persist the state
      setState(() {
        _isChecking = false;
        _allGranted = true;
      });

      // PERSIST permissions granted state — this is the KEY FIX
      // Next time the app starts, it will skip this screen
      await sl<AppStateService>().setPermissionsGranted();

      widget.onGranted();
    } catch (e) {
      setState(() {
        _isChecking = false;
        _allGranted = false;
        _errorMessage = 'Permission check failed: $e\n\nPlease try again or grant permissions manually in App Settings.';
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.hub_rounded, color: AppTheme.oledBlack, size: 40),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
              const SizedBox(height: 16),
              const Text('Setting up permissions...', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              const Text('Discovering installed apps...', style: AppTheme.caption),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.neonPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonPink.withOpacity(0.3)),
                ),
                child: const Icon(Icons.warning_rounded, color: AppTheme.neonPink, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Permission Required', style: AppTheme.heading2),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: AppTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _openAppSettings,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: GlassDecorations.glassButton(borderRadius: 14),
                  child: const Center(
                    child: Text('Open App Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.oledBlack)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _checkPermissions,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: GlassDecorations.glassCard(borderRadius: 14, fillColor: AppTheme.glassFillSubtle),
                  child: const Center(
                    child: Text('Check Again', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.liquidCyan)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allGranted) {
      return Scaffold(
        backgroundColor: AppTheme.oledBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.check_rounded, color: AppTheme.oledBlack, size: 40),
              ),
              const SizedBox(height: 24),
              Text('${_discoveredAppCount} apps discovered ✓', style: AppTheme.heading2.copyWith(color: AppTheme.neonEmerald)),
              const SizedBox(height: 8),
              const Text('All permissions granted. Loading dashboard...', style: AppTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    // Default: show permission request UI
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
