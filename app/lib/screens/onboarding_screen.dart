import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToRegister() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageCardHeight = screenHeight * 0.38;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: Column(
          children: [
            // ── Top: Dark image area ──
            ScaleTransition(
              scale: _cardScale,
              child: SizedBox(
                height: imageCardHeight + 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Dark background
                    Container(
                      height: imageCardHeight,
                      width: double.infinity,
                      color: AppTheme.offBlack,
                    ),

                    // Logo + app name on top of dark bg
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 24,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'DressMate',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tilted overlapping cards
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 56,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: SizedBox(
                          width: screenWidth * 0.7,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Back card (tilted left)
                              Positioned(
                                left: 0,
                                child: Transform.rotate(
                                  angle: -6 * math.pi / 180,
                                  child: Container(
                                    width: screenWidth * 0.44,
                                    height: imageCardHeight * 0.82,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.black
                                              .withValues(alpha: 0.25),
                                          blurRadius: 24,
                                          offset: const Offset(-4, 8),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/onboarding_1.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // Front card (tilted right)
                              Positioned(
                                right: 0,
                                child: Transform.rotate(
                                  angle: 4 * math.pi / 180,
                                  child: Container(
                                    width: screenWidth * 0.44,
                                    height: imageCardHeight * 0.82,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 24,
                                          offset: const Offset(4, 8),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/onboarding_2.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // "Joined by" badge
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.offBlack,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Overlapping mini avatars
                            SizedBox(
                              width: 40,
                              height: 24,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: _buildMiniAvatar(AppTheme.primary),
                                  ),
                                  Positioned(
                                    left: 16,
                                    child: _buildMiniAvatar(AppTheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Join the Style Revolution',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom: Text + buttons ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                          ),
                          child: const Text(
                            'AI-POWERED STYLING',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Heading
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.black,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                            children: [
                              TextSpan(text: 'Your Personal\n'),
                              TextSpan(
                                text: 'Style Companion.',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle
                        const Text(
                          'Organize your wardrobe, get AI outfit\nrecommendations, and share your style\nwith friends effortlessly.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.midGray,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                        ),

                        const Spacer(),

                        // Get Started button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _navigateToRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _navigateToLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '© 2026 DressMate. All Rights Reserved.',
                                style: TextStyle(
                                  color: AppTheme.lightGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Privacy',
                                    style: TextStyle(
                                      color: AppTheme.midGray,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'Terms',
                                      style: TextStyle(
                                        color: AppTheme.midGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Contact',
                                    style: TextStyle(
                                      color: AppTheme.midGray,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.offBlack, width: 2),
      ),
      child: const Icon(
        Icons.person,
        color: AppTheme.white,
        size: 12,
      ),
    );
  }
}
