import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Liquid Glass Card — The foundational UI building block for Hablas Studio.
/// Implements a frosted-glass panel with blurred backdrop, translucent fill,
/// luminous borders, and multi-layered glow shadows.
class GlassDecorations {
  // ─── Standard Glass Card Decoration ──────────────────────────────────
  static BoxDecoration glassCard({
    double borderRadius = 16.0,
    double blurSigma = 20.0,
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

  // ─── Elevated Glass Panel (more prominent) ──────────────────────────
  static BoxDecoration glassCardElevated({
    double borderRadius = 20.0,
    Color accentColor = AppTheme.liquidCyan,
  }) {
    return BoxDecoration(
      color: AppTheme.glassFill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppTheme.glassBorder,
        width: 2.0,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.15),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 0),
        ),
        const BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 16,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
        const BoxShadow(
          color: AppTheme.glassShadow,
          blurRadius: 8,
          spreadRadius: 0,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Accent-bordered Glass Card (status indicators) ──────────────────
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
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: accentColor.withOpacity(0.10),
          blurRadius: 32,
          spreadRadius: 4,
          offset: const Offset(0, 0),
        ),
        const BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // ─── Danger Glass Card ──────────────────────────────────────────────
  static BoxDecoration glassCardDanger({double borderRadius = 16.0}) {
    return glassCardAccent(
      borderRadius: borderRadius,
      accentColor: AppTheme.neonPink,
    );
  }

  // ─── Glass Button Style ─────────────────────────────────────────────
  static BoxDecoration glassButton({
    double borderRadius = 12.0,
    Color? fillColor,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppTheme.primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.liquidCyan.withOpacity(0.30),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppTheme.glassShadowDeep,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Glass Input Field Decoration ───────────────────────────────────
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

  // ─── Private Helpers ─────────────────────────────────────────────────
  static List<BoxShadow> _defaultGlassShadows() {
    return [
      const BoxShadow(
        color: AppTheme.glassShadowDeep,
        blurRadius: 16,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
      const BoxShadow(
        color: AppTheme.glassShadow,
        blurRadius: 8,
        spreadRadius: 0,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: AppTheme.liquidCyan.withOpacity(0.06),
        blurRadius: 24,
        spreadRadius: 2,
        offset: const Offset(0, 0),
      ),
    ];
  }
}

/// ─── HablasGlassCard Widget ──────────────────────────────────────────
/// A pre-built frosted-glass card widget with BackdropFilter blur.
class HablasGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BoxDecoration? decoration;
  final Color? fillColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final Gradient? gradientOverlay;
  final bool applyBlur;

  const HablasGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.decoration,
    this.fillColor,
    this.borderColor,
    this.shadows,
    this.gradientOverlay,
    this.applyBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final boxDecoration = decoration ?? GlassDecorations.glassCard(
      borderRadius: borderRadius,
      fillColor: fillColor,
      borderColor: borderColor,
      customShadows: shadows,
      gradientOverlay: gradientOverlay,
    );

    Widget inner = Container(
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );

    if (applyBlur) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: inner,
        ),
      );
    }

    return Container(
      margin: margin,
      child: inner,
    );
  }
}
