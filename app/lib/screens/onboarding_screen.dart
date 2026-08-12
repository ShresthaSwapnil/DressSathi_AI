import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';
import '../widgets/app_ui.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _open(BuildContext context, Widget page) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 430),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final visual = Reveal(child: _Visual(wide: wide));
          final pitch = _Pitch(
            wide: wide,
            onRegister: () => _open(context, const RegisterScreen()),
            onLogin: () => _open(context, const LoginScreen()),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.all(wide ? 24 : 16),
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 11, child: visual),
                          const SizedBox(width: 56),
                          Expanded(flex: 9, child: pitch),
                        ],
                      )
                    : ListView(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight * 0.48,
                            child: visual,
                          ),
                          const SizedBox(height: 32),
                          pitch,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _Visual extends StatelessWidget {
  const _Visual({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/onboarding_1.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x10111217), Color(0xB8111217)],
            ),
          ),
        ),
        Positioned(
          top: 22,
          left: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primary, size: 16),
                SizedBox(width: 7),
                Text(
                  'AI-powered styling',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Row(
            children: [
              Expanded(
                child: _GlassStat(value: '1 tap', label: 'to build an outfit'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlassStat(value: '100%', label: 'your own clothes'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.black.withValues(alpha: 0.64),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.wide,
    required this.onRegister,
    required this.onLogin,
  });

  final bool wide;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Reveal(
        delay: const Duration(milliseconds: 80),
        child: Row(
          children: [
            Hero(
              tag: 'brand-logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/logo.png', width: 48, height: 48),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'DressMate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: wide ? 54 : 28),
      Reveal(
        delay: const Duration(milliseconds: 150),
        child: Text(
          'A wardrobe that\nthinks with you.',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: wide ? 56 : 40),
        ),
      ),
      const SizedBox(height: 18),
      Reveal(
        delay: const Duration(milliseconds: 220),
        child: Text(
          'Organize what you own, get weather-aware outfit ideas, and share your style with people you trust.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
      const SizedBox(height: 28),
      Reveal(
        delay: const Duration(milliseconds: 290),
        child: Wrap(
          spacing: 9,
          runSpacing: 9,
          children: const [
            _Feature(icon: Icons.checkroom_outlined, label: 'Digital closet'),
            _Feature(icon: Icons.cloud_outlined, label: 'Live weather'),
            _Feature(icon: Icons.people_outline, label: 'Private sharing'),
          ],
        ),
      ),
      const SizedBox(height: 36),
      Reveal(
        delay: const Duration(milliseconds: 360),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLogin,
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Private by design. Your wardrobe stays yours.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    ],
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
