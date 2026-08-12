import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/friends_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/upload_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.offWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const DressMateApp(),
    ),
  );
}

class DressMateApp extends StatelessWidget {
  const DressMateApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DressMate',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const AuthWrapper(),
  );
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
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: auth.isLoading
          ? const _LaunchLoader(key: ValueKey('loading'))
          : auth.isAuthenticated
          ? const AppShell(key: ValueKey('app'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}

class _LaunchLoader extends StatefulWidget {
  const _LaunchLoader({super.key});

  @override
  State<_LaunchLoader> createState() => _LaunchLoaderState();
}

class _LaunchLoaderState extends State<_LaunchLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_controller),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.04).animate(_controller),
          child: Hero(
            tag: 'brand-logo',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/logo.png', width: 82, height: 82),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  late final _screens = <Widget>[
    HomeScreen(key: _homeKey),
    const RecommendationScreen(),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  static const _destinations = [
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Wardrobe'),
    (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Stylist'),
    (Icons.people_alt_rounded, Icons.people_alt_outlined, 'Social'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'You'),
  ];

  void _select(int value) {
    if (value == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = value);
  }

  Future<void> _addItem() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: const UploadScreen(),
        ),
      ),
    );
    if (result == true) _homeKey.currentState?.refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = Stack(
      children: List.generate(
        _screens.length,
        (screenIndex) => Positioned.fill(
          child: IgnorePointer(
            ignoring: screenIndex != _index,
            child: AnimatedOpacity(
              key: ValueKey('screen-opacity-$screenIndex'),
              opacity: screenIndex == _index ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: TickerMode(
                enabled: screenIndex == _index,
                child: _screens[screenIndex],
              ),
            ),
          ),
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopRail(index: _index, onSelect: _select, onAdd: _addItem),
            const VerticalDivider(width: 1, color: AppTheme.borderLight),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: content,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-item',
        tooltip: 'Add wardrobe item',
        onPressed: _addItem,
        backgroundColor: AppTheme.black,
        foregroundColor: AppTheme.white,
        elevation: 8,
        child: const Icon(Icons.add_rounded, size: 29),
      ),
      bottomNavigationBar: _MobileNav(index: _index, onSelect: _select),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    decoration: BoxDecoration(
      color: AppTheme.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppTheme.borderLight),
      boxShadow: AppTheme.mediumShadow,
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: List.generate(_AppShellState._destinations.length + 1, (
          slot,
        ) {
          if (slot == 2) return const Expanded(child: SizedBox(height: 54));
          final itemIndex = slot > 2 ? slot - 1 : slot;
          final item = _AppShellState._destinations[itemIndex];
          final selected = itemIndex == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: item.$3,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelect(itemIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: selected ? 34 : 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.lavender
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          selected ? item.$1 : item.$2,
                          size: 20,
                          color: selected ? AppTheme.primary : AppTheme.midGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? AppTheme.black : AppTheme.midGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    width: 108,
    color: AppTheme.white,
    child: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 18),
          Hero(
            tag: 'brand-logo',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/logo.png', width: 46, height: 46),
            ),
          ),
          const SizedBox(height: 30),
          for (var i = 0; i < _AppShellState._destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RailButton(
                item: _AppShellState._destinations[i],
                selected: i == index,
                onTap: () => onSelect(i),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton.filled(
              tooltip: 'Add item',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final (IconData, IconData, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.$3,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              selected ? item.$1 : item.$2,
              color: selected ? AppTheme.primary : AppTheme.midGray,
            ),
            const SizedBox(height: 4),
            Text(
              item.$3,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.black : AppTheme.midGray,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
