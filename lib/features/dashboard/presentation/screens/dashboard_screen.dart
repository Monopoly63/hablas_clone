import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../../../core/theme/animated_liquid_background.dart';
import '../../domain/virtual_instance.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/glass_instance_card.dart';
import '../../../app_picker/presentation/screens/app_picker_screen.dart';

/// ─── Dashboard Screen — 120fps Optimized ────────────────────────────
///
/// PERFORMANCE OPTIMIZATIONS:
/// 1. AnimatedLiquidBackground replaces manual AnimatedBuilder + gradient rebuilds
/// 2. RepaintBoundary on every GlassInstanceCard isolates repaints
/// 3. const constructors wherever possible
/// 4. No BackdropFilter anywhere — uses translucent fills instead
/// 5. ListView instead of Column+Expanded for better scroll performance
/// 6. GlobalKey-free widget tree for efficient diffing
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
    // Trigger initial data load after first frame renders
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hablas Clone', style: AppTheme.heading2),
        Text('Virtual Studio', style: AppTheme.bodySmall),
      ],
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
        if (state.instances.isEmpty) return _buildEmpty();
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
          Text('Loading instances...', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand logo
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
            const Text('No Virtual Instances Yet', style: AppTheme.heading2),
            const SizedBox(height: 8),
            const Text(
              'Tap + to clone your first app.\n'
              'WhatsApp, Telegram — all running in parallel.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildQuickStartChips(),
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
        onTap: () => context.read<DashboardBloc>().add(CloneNewApp(app.$2)),
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
        // physics: BouncingScrollPhysics() for 120fps smooth feel
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        cacheExtent: 500, // Pre-cache 500px below viewport
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
      _buildStatCard(Icons.layers_rounded, '${state.totalInstanceCount}', 'Total', AppTheme.liquidCyan),
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
        Text('${instances.length} instance${instances.length > 1 ? "s" : ""}', style: AppTheme.caption),
        const Spacer(),
        Text(_formatBytes(totalStorage), style: AppTheme.bodySmall.copyWith(color: AppTheme.cobaltBlue)),
      ]),
      const SizedBox(height: 8),
      // RepaintBoundary per instance card — isolated repaints
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

  // ─── Navigation ─────────────────────────────────────────────────────
  void _openAppPicker() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AppPickerScreen(),
        // Smooth 120fps transition
        fullscreenDialog: true,
      ),
    );
    if (result != null && result is Map<String, dynamic> && mounted) {
      context.read<DashboardBloc>().add(AppAddedFromPicker(
        packageName: result['packageName'] as String,
        appName: result['appName'] as String,
        instanceId: result['instanceId'] as int,
      ));
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
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.liquidCyan),
                title: Text('Rename', style: AppTheme.body.copyWith(color: AppTheme.liquidCyan)),
                onTap: () { Navigator.pop(ctx); _showRename(instance); },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.cobaltBlue),
                title: Text('Clear Cache', style: AppTheme.body.copyWith(color: AppTheme.cobaltBlue)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.shortcut_rounded, color: AppTheme.neonEmerald),
                title: Text('Create Shortcut', style: AppTheme.body.copyWith(color: AppTheme.neonEmerald)),
                onTap: () => Navigator.pop(ctx),
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
