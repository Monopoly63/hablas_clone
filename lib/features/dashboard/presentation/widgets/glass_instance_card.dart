import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../../domain/virtual_instance.dart';

/// Glass Instance Card — Displays a single virtual app instance with
/// Liquid Glass morphism, live status badge, and action controls.
class GlassInstanceCard extends StatelessWidget {
  final VirtualInstance instance;
  final VoidCallback? onTap;
  final VoidCallback? onLaunch;
  final VoidCallback? onTerminate;
  final VoidCallback? onMore;
  final bool isCompact;

  const GlassInstanceCard({
    super.key,
    required this.instance,
    this.onTap,
    this.onLaunch,
    this.onTerminate,
    this.onMore,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HablasGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        decoration: GlassDecorations.glassCardAccent(
          borderRadius: 16,
          accentColor: _statusColor,
        ),
        applyBlur: false,
        child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
      ),
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Top Row: Icon + Status + More ────────────────────────────
        Row(
          children: [
            _buildAppIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance.customName,
                    style: AppTheme.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instance.packageName,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildStatusBadge(),
            const SizedBox(width: 8),
            _buildMoreButton(),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Info Row ─────────────────────────────────────────────────
        Row(
          children: [
            _buildInfoChip(
              icon: Icons.storage_outlined,
              label: instance.storageSizeFormatted,
              color: AppTheme.cobaltBlue,
            ),
            const SizedBox(width: 12),
            _buildInfoChip(
              icon: Icons.access_time_outlined,
              label: _formatTimeAgo(instance.lastActiveAt ?? instance.createdAt),
              color: AppTheme.neonEmerald,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Action Buttons ───────────────────────────────────────────
        Row(
          children: [
            if (instance.status != InstanceStatus.running)
              Expanded(
                child: _buildActionButton(
                  label: 'Launch',
                  icon: Icons.play_arrow_rounded,
                  color: AppTheme.neonEmerald,
                  onTap: onLaunch,
                ),
              )
            else
              Expanded(
                child: _buildActionButton(
                  label: 'Terminate',
                  icon: Icons.stop_circle_outlined,
                  color: AppTheme.neonPink,
                  onTap: onTerminate,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        _buildAppIcon(size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.customName,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${instance.status.emoji} ${instance.status.displayName}',
                style: AppTheme.bodySmall.copyWith(color: _statusColor),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildAppIcon({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.liquidCyan.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.android_rounded,
        color: AppTheme.oledBlack,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            instance.status.displayName,
            style: AppTheme.caption.copyWith(color: _statusColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodySmall.copyWith(color: color)),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: onMore,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.glassFillSubtle,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: Color(0xFF888888),
          size: 20,
        ),
      ),
    );
  }

  Color get _statusColor => switch (instance.status) {
    InstanceStatus.running => AppTheme.neonEmerald,
    InstanceStatus.idle => AppTheme.cobaltBlue,
    InstanceStatus.sleeping => AppTheme.statusSleeping,
    InstanceStatus.error => AppTheme.neonPink,
  };

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
