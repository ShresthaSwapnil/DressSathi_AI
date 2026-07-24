import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const DressMateApp(),
    ),
  );
}

class DressMateApp extends StatelessWidget {
  const DressMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DressMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.errorRed,
                  size: 22,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Expired',
                        style: TextStyle(
                          color: AppTheme.offBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Please log in again to continue.',
                        style: TextStyle(
                          color: AppTheme.midGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.white,
            behavior: SnackBarBehavior.floating,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: const BorderSide(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          ),
        );
        authProvider.clearSessionExpired();
      });
    }

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'DressMate',
                style: TextStyle(
                  color: AppTheme.offBlack,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const AppShell();
    }

    return const OnboardingScreen();
  }
}

/// Main app shell with premium bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    const RecommendationScreen(),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  // Maps nav position (0-4, skipping center) to screen index (0-3)
  int _screenIndexFromNav(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex - 1; // 3→2, 4→3
  }

  void _onNavTap(int navIndex) {
    final screenIndex = _screenIndexFromNav(navIndex);
    if (_currentIndex != screenIndex) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = screenIndex);
    }
  }

  int _navIndexFromScreen(int screenIndex) {
    if (screenIndex < 2) return screenIndex;
    return screenIndex + 1; // 2→3, 3→4
  }

  Future<void> _onCenterTap() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UploadScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    // If item was uploaded, refresh the home screen data
    if (result == true) {
      _homeKey.currentState?.refreshItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeNav = _navIndexFromScreen(_currentIndex);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Screen content
          Positioned.fill(
            bottom: 72 + bottomPadding,
            child: AnimatedSwitcher(
              duration: AppTheme.durationMedium,
              child: IndexedStack(
                key: ValueKey(_currentIndex),
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),

          // Frosted glass bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(activeNav, bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int activeNav, double bottomPadding) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Frosted glass background
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.85),
                border: const Border(
                  top: BorderSide(
                    color: Color(0xFFEAECF0),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 72,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, activeNav, Icons.checkroom_outlined,
                            Icons.checkroom_rounded, 'Wardrobe'),
                        _buildNavItem(1, activeNav, Icons.auto_awesome_outlined,
                            Icons.auto_awesome_rounded, 'AI Stylist'),
                        const SizedBox(width: 64),
                        _buildNavItem(3, activeNav, Icons.people_outline,
                            Icons.people_rounded, 'Social'),
                        _buildNavItem(4, activeNav, Icons.person_outline,
                            Icons.person_rounded, 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Floating center button
        Positioned(
          top: -26,
          child: _buildCenterButton(),
        ),
      ],
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _onCenterTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.secondaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.secondaryGlow,
          border: Border.all(
            color: AppTheme.white,
            width: 4,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppTheme.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int navIndex, int activeNav, IconData icon, IconData activeIcon,
      String label) {
    final isSelected = activeNav == navIndex;
    return GestureDetector(
      onTap: () => _onNavTap(navIndex),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppTheme.durationMedium,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: AnimatedSwitcher(
                duration: AppTheme.durationFast,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey('$navIndex-$isSelected'),
                  size: 24,
                  color: isSelected ? AppTheme.primary : AppTheme.lightGray,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppTheme.durationFast,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.lightGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
                letterSpacing: -0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
