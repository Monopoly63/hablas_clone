import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../domain/virtual_instance.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/glass_instance_card.dart';
import '../../../app_picker/presentation/screens/app_picker_screen.dart';

/// Dashboard Screen — Main hub displaying all virtual instances.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.oledBlack,
                AppTheme.liquidCyan.withOpacity(0.03 + _bgController.value * 0.02),
                AppTheme.cobaltBlue.withOpacity(0.02 + _bgController.value * 0.015),
                AppTheme.neonEmerald.withOpacity(0.015 + _bgController.value * 0.01),
                AppTheme.oledBlack,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.hub_rounded, color: AppTheme.oledBlack, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hablas', style: AppTheme.heading2),
                Text('Virtual Studio', style: AppTheme.bodySmall),
              ],
            ),
          ),
          BlocBuilder<DashboardBloc, DashboardState>(
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
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) return _buildLoadingState();
        if (state.instances.isEmpty) return _buildEmptyState();
        return _buildInstanceGrid(state);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.liquidCyan, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Loading instances...', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                boxShadow: [BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.oledBlack, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('No Virtual Instances Yet', style: AppTheme.heading2),
            const SizedBox(height: 8),
            Text('Tap the + button to clone your first app.\nWhatsApp, Telegram, and more — all running in parallel.', style: AppTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _buildQuickStartChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartChips() {
    const popularApps = [
      ('WhatsApp', 'com.whatsapp'),
      ('Telegram', 'org.telegram.messenger'),
      ('Instagram', 'com.instagram.android'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: popularApps.map((app) {
        return GestureDetector(
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
        );
      }).toList(),
    );
  }

  Widget _buildInstanceGrid(DashboardState state) {
    final grouped = state.groupedByPackage;
    return RefreshIndicator(
      color: AppTheme.liquidCyan,
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: () async { context.read<DashboardBloc>().add(RefreshDashboard()); },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
      _buildStatCard(icon: Icons.layers_rounded, value: '${state.totalInstanceCount}', label: 'Total', color: AppTheme.liquidCyan),
      const SizedBox(width: 10),
      _buildStatCard(icon: Icons.play_circle_outline_rounded, value: '${state.runningInstanceCount}', label: 'Active', color: AppTheme.neonEmerald),
      const SizedBox(width: 10),
      _buildStatCard(icon: Icons.storage_rounded, value: _formatBytes(state.totalStorageBytes), label: 'Storage', color: AppTheme.cobaltBlue),
    ]);
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Expanded(
      child: HablasGlassCard(
        padding: const EdgeInsets.all(12), applyBlur: false,
        decoration: GlassDecorations.glassCard(borderRadius: 12),
        child: Column(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.heading3.copyWith(fontSize: 16)),
          Text(label, style: AppTheme.caption.copyWith(color: color)),
        ]),
      ),
    );
  }

  Widget _buildAppGroup({required String packageName, required List<VirtualInstance> instances, required int totalStorage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(packageName.split('.').last.toUpperCase(), style: AppTheme.accentLabel),
          const SizedBox(width: 8),
          Text('${instances.length} instance${instances.length > 1 ? "s" : ""}', style: AppTheme.caption),
          const Spacer(),
          Text(_formatBytes(totalStorage), style: AppTheme.bodySmall.copyWith(color: AppTheme.cobaltBlue)),
        ]),
        const SizedBox(height: 8),
        ...instances.map((instance) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassInstanceCard(
            instance: instance,
            onLaunch: () => context.read<DashboardBloc>().add(LaunchInstance(instance.id)),
            onTerminate: () => context.read<DashboardBloc>().add(TerminateInstance(instance.id)),
            onMore: () => _showInstanceActions(instance),
          ),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

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

  void _openAppPicker() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppPickerScreen()));
    if (result != null && result is Map<String, dynamic> && context.mounted) {
      context.read<DashboardBloc>().add(AppAddedFromPicker(
        packageName: result['packageName'] as String,
        appName: result['appName'] as String,
        instanceId: result['instanceId'] as int,
      ));
    }
  }

  void _showInstanceActions(VirtualInstance instance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instance.customName, style: AppTheme.heading2),
            Text(instance.packageName, style: AppTheme.bodySmall),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.edit_rounded, color: AppTheme.liquidCyan), title: Text('Rename', style: AppTheme.body.copyWith(color: AppTheme.liquidCyan)), onTap: () { Navigator.pop(ctx); _showRenameDialog(instance); }),
            ListTile(leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.cobaltBlue), title: Text('Clear Cache', style: AppTheme.body.copyWith(color: AppTheme.cobaltBlue)), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.shortcut_rounded, color: AppTheme.neonEmerald), title: Text('Create Shortcut', style: AppTheme.body.copyWith(color: AppTheme.neonEmerald)), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.neonPink), title: Text('Delete', style: AppTheme.body.copyWith(color: AppTheme.neonPink)), onTap: () { Navigator.pop(ctx); _confirmDelete(instance); }),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(VirtualInstance instance) {
    final controller = TextEditingController(text: instance.customName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text('Rename Instance', style: AppTheme.heading3),
      content: TextField(controller: controller, style: AppTheme.body, decoration: GlassDecorations.glassInputDecoration(hintText: 'Enter new name...', prefixIcon: Icons.edit_rounded)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: AppTheme.bodySmall)),
        TextButton(onPressed: () { context.read<DashboardBloc>().add(RenameInstance(instance.id, controller.text)); Navigator.pop(ctx); }, child: Text('Save', style: AppTheme.accentLabel)),
      ],
    ));
  }

  void _confirmDelete(VirtualInstance instance) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text('Delete Instance?', style: AppTheme.heading3.copyWith(color: AppTheme.neonPink)),
      content: Text('This will permanently delete "${instance.customName}" and all its data.', style: AppTheme.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: AppTheme.bodySmall)),
        TextButton(onPressed: () { context.read<DashboardBloc>().add(DeleteInstance(instance.id)); Navigator.pop(ctx); }, child: Text('Delete', style: AppTheme.accentLabel.copyWith(color: AppTheme.neonPink))),
      ],
    ));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}
