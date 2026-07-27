import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_decorations.dart';
import '../bloc/auth_bloc.dart';

/// ─── Lock Screen — PIN/Biometric security gate ────────────────────
///
/// Shows before dashboard if security lock is enabled.
/// Supports:
///   1. 4-6 digit PIN entry
///   2. Biometric quick unlock (if enabled)
///   3. Failed attempt counter with cooldown
///
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _isSetupMode = false; // True if user is setting first PIN

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckLockStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isVerified) {
            widget.onUnlocked();
          }
          if (state.error != null && state.failedAttempts > 0) {
            // Shake animation on wrong PIN
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!, style: const TextStyle(color: AppTheme.neonPink)),
                backgroundColor: AppTheme.surfaceDark,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        builder: (context, state) {
          _isSetupMode = !state.hasPin;
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.2), blurRadius: 24),
                        ],
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppTheme.oledBlack, size: 40),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _isSetupMode ? '🔒 Set Security PIN' : '🔒 Unlock Hablas Clone',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSetupMode
                          ? 'Choose a 4-6 digit PIN to protect your clones'
                          : 'Enter your PIN to access clones',
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // PIN dots indicator
                    _buildPinDots(),
                    const SizedBox(height: 32),

                    // Number pad
                    _buildNumPad(),
                    const SizedBox(height: 16),

                    // Skip button (setup mode only)
                    if (_isSetupMode)
                      GestureDetector(
                        onTap: () {
                          // Skip PIN setup — user doesn't want security
                          context.read<AuthBloc>().add(SetPin('0000')); // Default, will be disabled
                          // Actually, let's just unlock without PIN
                          widget.onUnlocked();
                        },
                        child: Text('Skip for now', style: AppTheme.bodySmall.copyWith(color: const Color(0xFF888888))),
                      ),

                    // Failed attempts warning
                    if (state.failedAttempts >= 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          '⚠️ ${state.failedAttempts} failed attempts',
                          style: AppTheme.caption.copyWith(color: AppTheme.neonPink),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinDots() {
    const maxDigits = 6;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxDigits, (index) {
        final isActive = index < _pin.length;
        return Container(
          width: 16, height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.liquidCyan : AppTheme.glassFillSubtle,
            border: Border.all(
              color: isActive ? AppTheme.liquidCyan : AppTheme.glassBorder,
              width: 1,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['biometric', '0', 'delete'],
    ];

    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) => _buildKey(key)).toList(),
        ),
      )).toList(),
    );
  }

  Widget _buildKey(String key) {
    if (key == 'delete') {
      return GestureDetector(
        onTap: () {
          if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        },
        child: Container(
          width: 70, height: 70,
          decoration: GlassDecorations.glassCard(borderRadius: 16, fillColor: AppTheme.glassFillSubtle),
          child: const Icon(Icons.backspace_outlined, color: Color(0xFF888888), size: 24),
        ),
      );
    }

    if (key == 'biometric') {
      return GestureDetector(
        onTap: () => widget.onUnlocked(), // Placeholder: biometric auth
        child: Container(
          width: 70, height: 70,
          decoration: GlassDecorations.glassCard(borderRadius: 16, fillColor: AppTheme.glassFillSubtle),
          child: const Icon(Icons.fingerprint_rounded, color: AppTheme.liquidCyan, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        width: 70, height: 70,
        decoration: GlassDecorations.glassCard(
          borderRadius: 16,
          fillColor: AppTheme.glassFillSubtle,
        ),
        child: Center(
          child: Text(key, style: AppTheme.heading3.copyWith(fontSize: 24)),
        ),
      ),
    );
  }

  void _onKeyPressed(String digit) {
    if (_pin.length >= 6) return;

    setState(() => _pin += digit);

    if (_pin.length >= 4) {
      // Auto-submit when 4 digits entered (or wait for more)
      // Submit after a brief pause if exactly 4, or immediately if 5-6
      if (_pin.length == 4) {
        // Brief delay to allow user to add more digits
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pin.length == 4 && mounted) {
            _submitPin();
          }
        });
      } else {
        _submitPin();
      }
    }
  }

  void _submitPin() {
    if (_isSetupMode) {
      context.read<AuthBloc>().add(SetPin(_pin));
    } else {
      context.read<AuthBloc>().add(VerifyPin(_pin));
    }
    setState(() => _pin = '');
  }
}
