import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../../../core/theme/animated_liquid_background.dart';
import '../../../../core/persistence/instance_persistence_service.dart';
import '../../domain/virtual_instance.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/glass_instance_card.dart';
import '../../../app_picker/presentation/screens/app_picker_screen.dart';

/// ─── Dashboard Screen v2.0.0 — Real persistence, real clones ────────
///
/// KEY FIXES:
///   1. Dashboard ALWAYS loads from Hive on startup
///   2. App picker result → immediate persist → verify
///   3. Shows discovered app count for permission verification
///   4. Error recovery with detailed AppError info
///   5. Clone flow is bulletproof — icon → engine → persist → verify
///
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load persisted instances on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardBloc>().add(LoadDashboard());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedLiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state.hasError) return _buildErrorBanner(state);
                  return const SizedBox.shrink();
                },
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── Error Banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner(DashboardState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neonPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonPink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.neonPink, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(state.error ?? '', style: AppTheme.bodySmall.copyWith(color: AppTheme.neonPink), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          GestureDetector(
            onTap: () => context.read<DashboardBloc>().add(RetryLastAction()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Retry', style: TextStyle(color: AppTheme.neonEmerald, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _buildLogo(),
          const SizedBox(width: 12),
          Expanded(child: _buildTitle()),
          _buildInstanceCounter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.hub_rounded, color: AppTheme.oledBlack, size: 22),
    );
  }

  Widget _buildTitle() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hablas Clone', style: AppTheme.heading2),
            Text(
              state.discoveredAppCount > 0
                  ? '${state.totalInstanceCount} clones · ${state.discoveredAppCount} apps'
                  : 'Virtual Studio',
              style: AppTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstanceCounter() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: GlassDecorations.glassCard(borderRadius: 10, fillColor: AppTheme.glassFillSubtle),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_rounded, size: 16, color: AppTheme.liquidCyan),
              const SizedBox(width: 4),
              Text('${state.totalInstanceCount}', style: AppTheme.accentLabel),
            ],
          ),
        );
      },
    );
  }

  // ─── Body ───────────────────────────────────────────────────────────

  Widget _buildBody() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) return _buildLoading();
        if (state.instances.isEmpty) return _buildEmpty(state);
        return _buildInstanceList(state);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Loading your clones...', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmpty(DashboardState state) {
    final hasApps = state.discoveredAppCount > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.oledBlack, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('No Clones Yet', style: AppTheme.heading2),
            const SizedBox(height: 8),
            Text(
              hasApps
                  ? 'Tap + to clone your first app.\n${state.discoveredAppCount} apps available on your device.'
                  : 'Tap + to clone your first app.\nNo apps detected — check permissions.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (hasApps) _buildQuickStartChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartChips() {
    const apps = [
      ('WhatsApp', 'com.whatsapp'),
      ('Telegram', 'org.telegram.messenger'),
      ('Instagram', 'com.instagram.android'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: apps.map((app) => GestureDetector(
        onTap: () => context.read<DashboardBloc>().add(CloneApp(packageName: app.$2, appName: app.$1)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: GlassDecorations.glassCard(borderRadius: 10, fillColor: AppTheme.glassFillSubtle),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: AppTheme.liquidCyan),
              const SizedBox(width: 4),
              Text(app.$1, style: AppTheme.bodySmall.copyWith(color: AppTheme.liquidCyan)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ─── Instance List (120fps-optimized) ───────────────────────────────

  Widget _buildInstanceList(DashboardState state) {
    final grouped = state.groupedByPackage;

    return RefreshIndicator(
      color: AppTheme.liquidCyan,
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: () async => context.read<DashboardBloc>().add(RefreshDashboard()),
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        cacheExtent: 500,
        children: [
          _buildStatsBar(state),
          const SizedBox(height: 20),
          ...grouped.entries.map((entry) => _buildAppGroup(
            packageName: entry.key,
            instances: entry.value,
            totalStorage: state.totalStorageByApp[entry.key] ?? 0,
          )),
        ],
      ),
    );
  }

  Widget _buildStatsBar(DashboardState state) {
    return Row(children: [
      _buildStatCard(Icons.layers_rounded, '${state.totalInstanceCount}', 'Clones', AppTheme.liquidCyan),
      const SizedBox(width: 10),
      _buildStatCard(Icons.play_circle_outline_rounded, '${state.runningInstanceCount}', 'Active', AppTheme.neonEmerald),
      const SizedBox(width: 10),
      _buildStatCard(Icons.storage_rounded, _formatBytes(state.totalStorageBytes), 'Storage', AppTheme.cobaltBlue),
    ]);
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: RepaintBoundary(
        child: HablasGlassCard(
          padding: const EdgeInsets.all(12),
          decoration: GlassDecorations.glassCard(borderRadius: 12),
          child: Column(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.heading3.copyWith(fontSize: 16)),
            Text(label, style: AppTheme.caption.copyWith(color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAppGroup({required String packageName, required List<VirtualInstance> instances, required int totalStorage}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(packageName.split('.').last.toUpperCase(), style: AppTheme.accentLabel),
        const SizedBox(width: 8),
        Text('${instances.length} clone${instances.length > 1 ? "s" : ""}', style: AppTheme.caption),
        const Spacer(),
        Text(_formatBytes(totalStorage), style: AppTheme.bodySmall.copyWith(color: AppTheme.cobaltBlue)),
      ]),
      const SizedBox(height: 8),
      ...instances.map((instance) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RepaintBoundary(
          child: GlassInstanceCard(
            instance: instance,
            onLaunch: () => context.read<DashboardBloc>().add(LaunchInstance(instance.id)),
            onTerminate: () => context.read<DashboardBloc>().add(TerminateInstance(instance.id)),
            onMore: () => _showInstanceActions(instance),
          ),
        ),
      )),
      const SizedBox(height: 8),
    ]);
  }

  // ─── FAB ────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _openAppPicker,
      child: Container(
        width: 56, height: 56,
        decoration: GlassDecorations.glassButton(borderRadius: 16),
        child: const Icon(Icons.add_rounded, color: AppTheme.oledBlack, size: 28),
      ),
    );
  }

  // ─── Navigation to App Picker ────────────────────────────────────────

  void _openAppPicker() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AppPickerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (mounted && result != null) {
      String packageName = '';
      String appName = '';
      int instanceId = DateTime.now().millisecondsSinceEpoch % 100000;

      if (result is Map) {
        packageName = result['packageName']?.toString() ?? '';
        appName = result['appName']?.toString() ?? packageName.split('.').last;
        final rawId = result['instanceId'];
        if (rawId is int) {
          instanceId = rawId;
        } else if (rawId != null) {
          instanceId = int.tryParse(rawId.toString()) ?? instanceId;
        }

        // Save icon bytes from picker result
        final rawIcon = result['iconBytes'];
        if (rawIcon is Uint8List && rawIcon.isNotEmpty) {
          try {
            final persistence = sl<InstancePersistenceService>();
            await persistence.saveIconBytes(packageName, rawIcon);
          } catch (_) {}
        }
      }

      if (packageName.isNotEmpty) {
        // Use the legacy AppAddedFromPicker event for compatibility
        context.read<DashboardBloc>().add(AppAddedFromPicker(
          packageName: packageName,
          appName: appName,
          instanceId: instanceId,
        ));
      }
    }
  }

  // ─── Instance Actions Sheet ─────────────────────────────────────────

  void _showInstanceActions(VirtualInstance instance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(instance.customName, style: AppTheme.heading2),
              Text(instance.packageName, style: AppTheme.bodySmall),
              Text('${instance.status.emoji} ${instance.status.displayName}', style: AppTheme.bodySmall.copyWith(color: _statusColor(instance))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.liquidCyan),
                title: Text('Rename', style: AppTheme.body.copyWith(color: AppTheme.liquidCyan)),
                onTap: () { Navigator.pop(ctx); _showRename(instance); },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.cobaltBlue),
                title: Text('Clear Cache', style: AppTheme.body.copyWith(color: AppTheme.cobaltBlue)),
                subtitle: Text('${instance.storageSizeFormatted} storage', style: AppTheme.caption),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<DashboardBloc>().add(ClearInstanceCache(instance.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.neonEmerald),
                title: Text('Launch', style: AppTheme.body.copyWith(color: AppTheme.neonEmerald)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<DashboardBloc>().add(LaunchInstance(instance.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AppTheme.liquidCyan),
                title: Text('Sync with Engine', style: AppTheme.body.copyWith(color: AppTheme.liquidCyan)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<DashboardBloc>().add(SyncWithNativeEngine());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.neonPink),
                title: Text('Delete', style: AppTheme.body.copyWith(color: AppTheme.neonPink)),
                onTap: () { Navigator.pop(ctx); _confirmDelete(instance); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(VirtualInstance instance) => switch (instance.status) {
    InstanceStatus.running => AppTheme.neonEmerald,
    InstanceStatus.idle => AppTheme.cobaltBlue,
    InstanceStatus.sleeping => AppTheme.statusSleeping,
    InstanceStatus.error => AppTheme.neonPink,
  };

  void _showRename(VirtualInstance instance) {
    final ctrl = TextEditingController(text: instance.customName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text('Rename', style: AppTheme.heading3),
      content: TextField(controller: ctrl, style: AppTheme.body, decoration: GlassDecorations.glassInputDecoration(hintText: 'New name...', prefixIcon: Icons.edit_rounded)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: AppTheme.bodySmall)),
        TextButton(onPressed: () { context.read<DashboardBloc>().add(RenameInstance(instance.id, ctrl.text)); Navigator.pop(ctx); }, child: const Text('Save', style: AppTheme.accentLabel)),
      ],
    ));
  }

  void _confirmDelete(VirtualInstance instance) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text('Delete?', style: AppTheme.heading3.copyWith(color: AppTheme.neonPink)),
      content: Text('Delete "${instance.customName}" permanently? Cannot undo.', style: AppTheme.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: AppTheme.bodySmall)),
        TextButton(onPressed: () { context.read<DashboardBloc>().add(DeleteInstance(instance.id)); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neonPink))),
      ],
    ));
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1073741824).toStringAsFixed(1)} GB';
  }
}
