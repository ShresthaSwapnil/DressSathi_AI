import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: const DressSathiApp(),
    ),
  );
}

class DressSathiApp extends StatelessWidget {
  const DressSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DressSathi',
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
                'DressSathi',
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

/// Main app shell with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RecommendationScreen(),
    FriendsScreen(),
    ProfileScreen(),
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
      MaterialPageRoute(builder: (context) => const UploadScreen()),
    );
    // If item was uploaded, refresh the home screen
    if (result == true && _currentIndex == 0) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeNav = _navIndexFromScreen(_currentIndex);

    return Scaffold(
      body: Stack(
        children: [
          // Screen content with bottom padding to avoid navbar overlap
          Padding(
            padding: const EdgeInsets.only(bottom: 74),
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          
          // Custom Bottom Navigation Bar positioned at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // The navbar background container
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(0, activeNav,
                              Icons.home_outlined, Icons.home_rounded, 'Home'),
                          _buildNavItem(1, activeNav,
                              Icons.checkroom_outlined, Icons.checkroom_rounded, 'Wardrobe'),
                          const SizedBox(width: 60), // Spacer for the popped out center button
                          _buildNavItem(3, activeNav,
                              Icons.people_outline, Icons.people_rounded, 'Social'),
                          _buildNavItem(4, activeNav,
                              Icons.person_outline, Icons.person_rounded, 'Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Popped out center button
                Positioned(
                  top: -24, // Pops out of the navbar
                  child: _buildCenterButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _onCenterTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondary, AppTheme.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: AppTheme.white,
            width: 3.5,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppTheme.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int navIndex, int activeNav, IconData icon, IconData activeIcon, String label) {
    final isSelected = activeNav == navIndex;
    return GestureDetector(
      onTap: () => _onNavTap(navIndex),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 24,
                color: isSelected ? AppTheme.primary : AppTheme.midGray,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.midGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
