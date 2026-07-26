import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─── AnimatedLiquidBackground — 120fps Background Engine ────────────
///
/// Layered gradient overlays with opacity animation.
/// No BackdropFilter. No per-frame gradient rebuilds.
///
class AnimatedLiquidBackground extends StatefulWidget {
  final Widget child;
  const AnimatedLiquidBackground({super.key, required this.child});

  @override
  State<AnimatedLiquidBackground> createState() => _AnimatedLiquidBackgroundState();
}

class _AnimatedLiquidBackgroundState extends State<AnimatedLiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            children: [
              // Static base gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.oledBlack,
                      Color(0x08121820),
                      Color(0x06081018),
                      AppTheme.oledBlack,
                    ],
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
              // Cyan pulse
              Positioned(
                top: -100 + (t * 50), left: -50, right: -50, bottom: -100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft, radius: 0.8,
                      colors: [AppTheme.liquidCyan.withOpacity(0.03 + t * 0.02), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Blue pulse
              Positioned(
                top: -80, left: 100 + (t * 80), right: -100, bottom: -50 + (t * 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.centerRight, radius: 0.6,
                      colors: [AppTheme.cobaltBlue.withOpacity(0.02 + t * 0.015), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Emerald pulse
              Positioned(
                top: 200 + (t * 100), left: -200, right: -200, bottom: -200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter, radius: 0.5,
                      colors: [AppTheme.neonEmerald.withOpacity(0.015 + t * 0.01), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Child content
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
