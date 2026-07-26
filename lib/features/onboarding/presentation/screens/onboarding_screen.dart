import 'package:flutter/material.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_decorations.dart';
import '../../../core/theme/animated_liquid_background.dart';
import '../../../l10n/localization_service.dart';
import '../../../core/services/app_state_service.dart';

/// ─── Onboarding Wizard v2.0.0 — Skips if already completed ──────────
///
/// KEY FIX: In v1.x, onboarding ALWAYS showed on startup because
/// there was no state persistence. v2.0.0 saves onboarding_completed
/// to SharedPreferences so it's skipped on subsequent launches.
///
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final PageController _controller = PageController();

  final LocalizationService _loc = LocalizationService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Complete onboarding and persist state.
  void _completeOnboarding() {
    // PERSIST onboarding completion — next launch skips this screen
    sl<AppStateService>().setOnboardingCompleted();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.oledBlack,
      body: AnimatedLiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _buildWelcomeStep(),
                    _buildPermissionsStep(),
                    _buildCloneStep(),
                    _buildSecurityStep(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Welcome ────────────────────────────────────────────────

  Widget _buildWelcomeStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(color: AppTheme.liquidCyan.withOpacity(0.3), blurRadius: 30),
                ],
              ),
              child: const Icon(Icons.hub_rounded, color: AppTheme.oledBlack, size: 60),
            ),
            const SizedBox(height: 32),
            Text(
              _loc.get('onboardingWelcome'),
              style: AppTheme.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _loc.get('onboardingWelcomeHint'),
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 12, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _featureChip('📱', 'Dual WhatsApp'),
                _featureChip('🔒', 'Privacy Lock'),
                _featureChip('⚡', '120fps UI'),
                _featureChip('🇦🇪', 'Arabic RTL'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Permissions ─────────────────────────────────────────────

  Widget _buildPermissionsStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.liquidCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.liquidCyan.withOpacity(0.4)),
              ),
              child: const Icon(Icons.security_rounded, color: AppTheme.liquidCyan, size: 50),
            ),
            const SizedBox(height: 32),
            Text(_loc.get('onboardingPermissions'), style: AppTheme.heading2),
            const SizedBox(height: 16),
            Text(
              _loc.get('onboardingPermissionsHint'),
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _permissionCard('🔍', 'App List Access', 'To find apps you can clone'),
            const SizedBox(height: 8),
            _permissionCard('🔔', 'Notifications', 'To alert you about clone status'),
            const SizedBox(height: 8),
            _permissionCard('🔋', 'Keep Alive', 'To prevent clones from being killed'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonEmerald.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.neonEmerald, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Your data stays on your device. Zero tracking.', style: AppTheme.bodySmall.copyWith(color: AppTheme.neonEmerald))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Cloning ─────────────────────────────────────────────────

  Widget _buildCloneStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.neonEmerald.withOpacity(0.4)),
              ),
              child: const Icon(Icons.copy_rounded, color: AppTheme.neonEmerald, size: 50),
            ),
            const SizedBox(height: 32),
            Text(_loc.get('onboardingClone'), style: AppTheme.heading2),
            const SizedBox(height: 16),
            Text(
              _loc.get('onboardingCloneHint'),
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _flowStep('1', 'Tap + button', Icons.add_rounded),
            _flowStep('2', 'Choose app', Icons.list_rounded),
            _flowStep('3', 'Clone created!', Icons.check_circle_rounded),
            _flowStep('4', 'Launch independently', Icons.play_arrow_rounded),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: Security ────────────────────────────────────────────────

  Widget _buildSecurityStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.cobaltBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.cobaltBlue.withOpacity(0.4)),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.cobaltBlue, size: 50),
            ),
            const SizedBox(height: 32),
            Text(_loc.get('onboardingSecurity'), style: AppTheme.heading2),
            const SizedBox(height: 16),
            Text(
              _loc.get('onboardingSecurityHint'),
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _securityOption(Icons.pin_rounded, 'PIN Code', '4-6 digit code', AppTheme.liquidCyan),
            const SizedBox(height: 12),
            _securityOption(Icons.fingerprint_rounded, 'Biometric', 'Fingerprint or Face ID', AppTheme.neonEmerald),
            const SizedBox(height: 12),
            _securityOption(Icons.lock_open_rounded, 'No Lock', 'Skip security setup', const Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  Widget _featureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: GlassDecorations.glassCard(borderRadius: 10, fillColor: AppTheme.glassFillSubtle),
      child: Text('$emoji $label', style: AppTheme.bodySmall),
    );
  }

  Widget _permissionCard(String emoji, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GlassDecorations.glassCard(borderRadius: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                Text(desc, style: AppTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.neonEmerald, size: 20),
        ],
      ),
    );
  }

  Widget _flowStep(String num, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(num, style: const TextStyle(color: AppTheme.oledBlack, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppTheme.liquidCyan, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTheme.body),
        ],
      ),
    );
  }

  Widget _securityOption(IconData icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GlassDecorations.glassCard(
        borderRadius: 12,
        fillColor: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, color: color)),
                Text(desc, style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // Skip — completes onboarding immediately
          if (_step < 3)
            GestureDetector(
              onTap: _completeOnboarding,
              child: Text(_loc.get('skip'), style: AppTheme.bodySmall.copyWith(color: const Color(0xFF888888))),
            ),
          const Spacer(),
          // Step dots
          Row(
            children: List.generate(4, (i) => Container(
              width: i == _step ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == _step ? AppTheme.liquidCyan : AppTheme.glassFillSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const Spacer(),
          // Next / Get Started
          GestureDetector(
            onTap: () {
              if (_step < 3) {
                _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              } else {
                _completeOnboarding();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: GlassDecorations.glassButton(borderRadius: 12),
              child: Text(
                _step < 3 ? _loc.get('next') : _loc.get('getStarted'),
                style: const TextStyle(color: AppTheme.oledBlack, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
