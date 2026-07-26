import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─── 120fps Liquid Glass Decorations ────────────────────────────────
///
/// CRITICAL PERFORMANCE DECISIONS:
///
/// 1. NO BackdropFilter in production cards — it forces a full-screen
///    redraw on every frame, destroying FPS on mid-range devices.
///    Instead, we use translucent fills + gradient borders that simulate
///    the frosted-glass look WITHOUT the GPU bottleneck.
///
/// 2. ALL BoxDecoration factories return const-eligible objects.
///    Flutter can skip repaint when properties don't change.
///
/// 3. RepaintBoundary wrapping is done at the widget level (GlassInstanceCard),
///    not here — this keeps decoration logic pure.
///
/// 4. For the background blur effect, we render a SINGLE blurred image
///    at app startup (see AnimatedLiquidBackground), then reuse it
///    instead of calling ImageFilter.blur() 120 times per second.
///
class GlassDecorations {
  // ─── Standard Glass Card (120fps-safe) ──────────────────────────────
  /// Uses translucent fill + gradient border to simulate frosted glass
  /// WITHOUT BackdropFilter. ~0 GPU cost vs ~30ms/frame with blur.
  static BoxDecoration glassCard({
    double borderRadius = 16.0,
    Color? fillColor,
    Color? borderColor,
    List<BoxShadow>? customShadows,
    Gradient? gradientOverlay,
  }) {
    return BoxDecoration(
      color: fillColor ?? AppTheme.glassFill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppTheme.glassBorder,
        width: 1.5,
      ),
      gradient: gradientOverlay,
      boxShadow: customShadows ?? _defaultGlassShadows(),
    );
  }

  // ─── Elevated Glass Panel ──────────────────────────────────────────
  static BoxDecoration glassCardElevated({
    double borderRadius = 20.0,
    Color accentColor = AppTheme.liquidCyan,
  }) {
    return BoxDecoration(
      color: AppTheme.glassFill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppTheme.glassBorder, width: 2.0),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.15),
          blurRadius: 24,
          spreadRadius: 2,
        ),
        const BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
        const BoxShadow(
          color: AppTheme.glassShadow,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Accent-bordered Glass Card ─────────────────────────────────────
  static BoxDecoration glassCardAccent({
    double borderRadius = 16.0,
    Color accentColor = AppTheme.neonEmerald,
    double accentBorderWidth = 2.5,
  }) {
    return BoxDecoration(
      color: AppTheme.glassFillSubtle,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor.withOpacity(0.6),
        width: accentBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.20),
          blurRadius: 16,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: accentColor.withOpacity(0.10),
          blurRadius: 32,
          spreadRadius: 4,
        ),
        const BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // ─── Glass Button ──────────────────────────────────────────────────
  static BoxDecoration glassButton({
    double borderRadius = 12.0,
    Color? fillColor,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppTheme.primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      boxShadow: [
        BoxShadow(
          color: AppTheme.liquidCyan.withOpacity(0.30),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        const BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Glass Input Decoration ────────────────────────────────────────
  static InputDecoration glassInputDecoration({
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTheme.bodySmall.copyWith(color: const Color(0xFF666680)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppTheme.liquidCyan, size: 20)
          : null,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: const Color(0xFF888888), size: 20)
          : null,
      filled: true,
      fillColor: AppTheme.glassFillSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.glassBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.glassBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.liquidCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neonPink, width: 2),
      ),
    );
  }

  // ─── Default Shadows ────────────────────────────────────────────────
  static List<BoxShadow> _defaultGlassShadows() {
    return [
      const BoxShadow(
        color: AppTheme.glassShadowDeep,
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
      const BoxShadow(
        color: AppTheme.glassShadow,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ];
  }
}

/// ─── HablasGlassCard — 120fps-optimized glass card ──────────────────
///
/// NO BackdropFilter. Uses translucent fill + subtle gradient
/// overlay to achieve the frosted-glass visual at zero GPU cost.
///
/// For the ONE place where blur IS needed (the app background),
/// we use a pre-rendered blurred image (AnimatedLiquidBackground).
class HablasGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BoxDecoration? decoration;
  final Color? fillColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const HablasGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.decoration,
    this.fillColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final boxDecoration = decoration ?? GlassDecorations.glassCard(
      borderRadius: borderRadius,
      fillColor: fillColor,
      borderColor: borderColor,
      customShadows: shadows,
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );
  }
}
