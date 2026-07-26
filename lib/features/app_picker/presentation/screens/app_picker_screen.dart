import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../../../core/native_bridge/virtual_engine_bridge.dart';
import '../../domain/installed_app.dart';
import '../../domain/app_picker_repository.dart';

/// App Picker Screen — Searchable list of installed apps with
/// instant cloning support. Features Liquid Glass card design.
class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  late final AppPickerRepository _repository;
  List<InstalledApp> _allApps = [];
  List<InstalledApp> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showSystemApps = false;

  @override
  void initState() {
    super.initState();
    _repository = AppPickerRepository(engine: VirtualEngineBridge());
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _repository.getInstalledApps();
      apps.sort((a, b) {
        if (a.isPopularCloneTarget && !b.isPopularCloneTarget) return -1;
        if (!a.isPopularCloneTarget && b.isPopularCloneTarget) return 1;
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });
      if (mounted) {
        setState(() {
          _allApps = apps;
          _filteredApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load apps: $e')),
        );
      }
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

  Future<void> _cloneApp(InstalledApp app) async {
    try {
      final instanceId = await _repository.createInstance(app.packageName);
      if (mounted) {
        Navigator.of(context).pop({
          'packageName': app.packageName,
          'appName': app.appName,
          'instanceId': instanceId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clone ${app.appName}: $e'),
            backgroundColor: AppTheme.neonPink,
          ),
        );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: _filterApps,
              style: AppTheme.body,
              decoration: GlassDecorations.glassInputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icons.search_rounded,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('${_filteredApps.length} apps', style: AppTheme.bodySmall),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showSystemApps = !_showSystemApps),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: GlassDecorations.glassCard(
                      borderRadius: 8,
                      fillColor: _showSystemApps
                          ? AppTheme.liquidCyan.withOpacity(0.15)
                          : AppTheme.glassFillSubtle,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_applications_outlined,
                          size: 14,
                          color: _showSystemApps ? AppTheme.liquidCyan : const Color(0xFF888888),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'System Apps',
                          style: AppTheme.caption.copyWith(
                            color: _showSystemApps ? AppTheme.liquidCyan : const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredApps.isEmpty
                    ? _buildEmptyResult()
                    : _buildAppList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF666680)),
          const SizedBox(height: 12),
          Text('No apps found', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAppList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        return _buildAppTile(app);
      },
    );
  }

  Widget _buildAppTile(InstalledApp app) {
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: app.isPopularCloneTarget ? AppTheme.primaryGradient : null,
                color: app.isPopularCloneTarget ? null : AppTheme.glassFill,
                border: Border.all(
                  color: app.isPopularCloneTarget
                      ? AppTheme.liquidCyan.withOpacity(0.3)
                      : AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.android_rounded,
                color: app.isPopularCloneTarget ? AppTheme.oledBlack : const Color(0xFF888888),
                size: 22,
              ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.liquidCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.liquidCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.liquidCyan,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
