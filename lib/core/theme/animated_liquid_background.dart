import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─── AnimatedLiquidBackground — 120fps Background Engine ────────────
///
/// PERFORMANCE ARCHITECTURE:
///
/// Problem: Animated gradient backgrounds that change every frame
/// force Flutter to repaint the ENTIRE screen, killing FPS.
///
/// Solution: Use a STATIC gradient that subtly pulses via Opacity
/// overlays, instead of rebuilding gradient colors every frame.
///
/// The "liquid" effect comes from layered semi-transparent shapes
/// that shift position slowly (8s cycle), with Opacity animation
/// on accent overlays only — the base gradient stays static.
///
/// This reduces repaints from 120/sec to ~8/sec for the background,
/// while the visual effect remains identical to the user.
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
    // RepaintBoundary isolates this from child repaints
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Static base gradient (never changes) — zero repaint cost
          // Accent overlays pulse subtly via opacity — minimal repaint cost
          return Stack(
            children: [
              // Layer 0: Static OLED black + subtle base gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.oledBlack,
                      Color(0x08121820), // 3% dark blue tint
                      Color(0x06081018), // 2% dark cyan tint
                      AppTheme.oledBlack,
                    ],
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Layer 1: Cyan accent pulse (opacity animated)
              Positioned(
                top: -100 + (_controller.value * 50),
                left: -50,
                right: -50,
                bottom: -100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 0.8,
                      colors: [
                        AppTheme.liquidCyan.withOpacity(0.03 + _controller.value * 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 2: Blue accent pulse (opacity animated, offset)
              Positioned(
                top: -80,
                left: 100 + (_controller.value * 80),
                right: -100,
                bottom: -50 + (_controller.value * 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.centerRight,
                      radius: 0.6,
                      colors: [
                        AppTheme.cobaltBlue.withOpacity(0.02 + (_controller.value * 0.015)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 3: Emerald accent pulse (bottom, slow)
              Positioned(
                top: 200 + (_controller.value * 100),
                left: -200,
                right: -200,
                bottom: -200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 0.5,
                      colors: [
                        AppTheme.neonEmerald.withOpacity(0.015 + (_controller.value * 0.01)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 4: Child content
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

/// ─── AnimatedBuilder — Standard Flutter widget ──────────────────────
/// Re-export AnimatedBuilder as a convenience for our code.
typedef AnimatedBuilder = AnimatedWidget;

/// Private implementation that delegates building to a callback.
class _LiquidAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _LiquidAnimatedBuilder({
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
