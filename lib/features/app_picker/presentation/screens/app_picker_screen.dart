import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../../../core/services/app_discovery_service.dart';
import '../../../../core/native_bridge/virtual_engine_bridge.dart';

/// ─── App Picker Screen — Shows REAL installed apps with icons ────────
///
/// Uses AppDiscoveryService (device_apps package) to enumerate
/// installed apps on the device, including their actual icons.
///
class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final AppDiscoveryService _discovery = AppDiscoveryService();
  final VirtualEngineBridge _engine = VirtualEngineBridge();

  List<DiscoveredApp> _allApps = [];
  List<DiscoveredApp> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showSystemApps = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final apps = _showSystemApps
          ? await _discovery.getAllApps()
          : await _discovery.getInstalledApps();

      if (apps.isEmpty) {
        // Permission likely not granted
        setState(() {
          _allApps = [];
          _filteredApps = [];
          _isLoading = false;
          _error = 'No apps found. Please grant QUERY_ALL_PACKAGES permission in App Settings.';
        });
        return;
      }

      // Sort: popular clone targets first, then alphabetical
      apps.sort((a, b) {
        if (a.isPopularCloneTarget && !b.isPopularCloneTarget) return -1;
        if (!a.isPopularCloneTarget && b.isPopularCloneTarget) return 1;
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });

      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading apps: $e\n\nPlease grant permissions in App Settings.';
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = _allApps.where((app) {
        final matchesSearch = query.isEmpty ||
            app.appName.toLowerCase().contains(query.toLowerCase()) ||
            app.packageName.toLowerCase().contains(query.toLowerCase());
        final matchesSystemFilter = _showSystemApps || !app.isSystemApp;
        return matchesSearch && matchesSystemFilter;
      }).toList();
    });
  }

  Future<void> _cloneApp(DiscoveredApp app) async {
    try {
      // Create virtual instance via native bridge
      final instanceId = await _engine.createVirtualInstance(app.packageName);
      if (mounted) {
        Navigator.of(context).pop({
          'packageName': app.packageName,
          'appName': app.appName,
          'instanceId': instanceId,
        });
      }
    } catch (e) {
      // If native bridge fails, still add the app as a "launch-only" clone
      // This way at minimum the user can launch the original app from Hablas
      if (mounted) {
        Navigator.of(context).pop({
          'packageName': app.packageName,
          'appName': app.appName,
          'instanceId': DateTime.now().millisecondsSinceEpoch, // fallback ID
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Clone App'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
          const SizedBox(height: 16),
          const Text('Scanning installed apps...', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
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
            const SizedBox(height: 8),
            Text(_error!, style: AppTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadApps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: GlassDecorations.glassButton(borderRadius: 12),
                child: const Text('Try Again', style: TextStyle(color: AppTheme.oledBlack, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            onChanged: _filterApps,
            style: AppTheme.body,
            decoration: GlassDecorations.glassInputDecoration(
              hintText: 'Search apps...',
              prefixIcon: Icons.search_rounded,
            ),
          ),
        ),
        // Filter toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${_filteredApps.length} apps', style: AppTheme.bodySmall),
              const Spacer(),
              GestureDetector(
                onTap: () { setState(() => _showSystemApps = !_showSystemApps); _loadApps(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: GlassDecorations.glassCard(
                    borderRadius: 8,
                    fillColor: _showSystemApps ? AppTheme.liquidCyan.withOpacity(0.15) : AppTheme.glassFillSubtle,
                  ),
                  child: Text(
                    'System Apps',
                    style: AppTheme.caption.copyWith(
                      color: _showSystemApps ? AppTheme.liquidCyan : const Color(0xFF888888),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildAppList()),
      ],
    );
  }

  Widget _buildAppList() {
    if (_filteredApps.isEmpty) {
      return Center(
        child: Text('No matching apps found', style: AppTheme.bodySmall),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) => _buildAppTile(_filteredApps[index]),
    );
  }

  Widget _buildAppTile(DiscoveredApp app) {
    return GestureDetector(
      onTap: () => _cloneApp(app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: GlassDecorations.glassCard(
          borderRadius: 14,
          fillColor: app.isPopularCloneTarget
              ? AppTheme.liquidCyan.withOpacity(0.03)
              : AppTheme.glassFillSubtle,
        ),
        child: Row(
          children: [
            // App icon (REAL icon from device!)
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: app.isPopularCloneTarget
                      ? AppTheme.liquidCyan.withOpacity(0.3)
                      : AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: app.hasIcon
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: app.iconImage!,
                        width: 44, height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.android_rounded, color: Color(0xFF888888), size: 22),
                      ),
                    )
                  : const Icon(Icons.android_rounded, color: Color(0xFF888888), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: AppTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Clone button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.liquidCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.liquidCyan.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.liquidCyan, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
