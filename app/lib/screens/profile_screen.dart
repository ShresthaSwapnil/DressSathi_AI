import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/item_service.dart';
import '../services/recommendation_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _items = ItemService();
  final _recommendations = RecommendationService();
  int _totalItems = 0;
  int _savedOutfits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final values = await Future.wait<dynamic>([
      _items.getItems(),
      _recommendations.getSavedOutfits(),
    ]);
    if (!mounted) return;
    setState(() {
      _totalItems = (values[0] as List<dynamic>?)?.length ?? 0;
      _savedOutfits = (values[1] as List<dynamic>?)?.length ?? 0;
      _loading = false;
    });
  }

  Future<void> _editPreferences(AuthProvider auth) async {
    HapticFeedback.selectionClick();
    final user = auth.user ?? {};
    final name = TextEditingController(text: user['display_name'] ?? '');
    final preferences = TextEditingController(
      text: user['style_preferences'] ?? '',
    );
    final location = TextEditingController(text: user['location_name'] ?? '');
    final latitude = TextEditingController(
      text: user['latitude']?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: user['longitude']?.toString() ?? '',
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make it personal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: preferences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Your style in a few words',
                  hintText: 'Minimal, relaxed, neutral…',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: location,
                decoration: const InputDecoration(
                  labelText: 'City or location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: longitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (save == true) {
      final ok = await auth.updateProfile({
        'display_name': name.text.trim().isEmpty ? null : name.text.trim(),
        'style_preferences': preferences.text.trim().isEmpty
            ? null
            : preferences.text.trim(),
        'location_name': location.text.trim().isEmpty
            ? null
            : location.text.trim(),
        'latitude': double.tryParse(latitude.text.trim()),
        'longitude': double.tryParse(longitude.text.trim()),
      });
      if (mounted) {
        ok ? HapticFeedback.heavyImpact() : HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Your style profile is refreshed.'
                  : 'Could not update your profile.',
            ),
          ),
        );
      }
    }
    name.dispose();
    preferences.dispose();
    location.dispose();
    latitude.dispose();
    longitude.dispose();
  }

  Future<void> _signOut(AuthProvider auth) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.paleGray,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            const _RoundIcon(
              icon: Icons.logout_rounded,
              color: AppTheme.secondary,
              size: 58,
            ),
            const SizedBox(height: 15),
            Text(
              'Sign out for now?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your wardrobe stays safely in your account.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign out'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay signed in'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? {};
    final email = user['email']?.toString() ?? 'Your account';
    final name = user['display_name']?.toString().trim();
    final label = name == null || name.isEmpty ? email.split('@').first : name;
    final location = user['location_name']?.toString();
    final style = user['style_preferences']?.toString();

    return Scaffold(
      body: AppPage(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const AppHeader(
                eyebrow: 'Your space',
                title: 'A wardrobe that feels like you.',
                subtitle:
                    'Tune your profile and watch your personal archive grow.',
              ),
              const SizedBox(height: 20),
              Reveal(
                child: _ProfileHero(
                  name: label,
                  email: email,
                  location: location,
                  style: style,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stats = [
                    _StatCard(
                      icon: Icons.checkroom_outlined,
                      value: _totalItems,
                      label: 'Pieces',
                      color: AppTheme.primary,
                      loading: _loading,
                    ),
                    _StatCard(
                      icon: Icons.auto_awesome_outlined,
                      value: _savedOutfits,
                      label: 'Saved looks',
                      color: AppTheme.secondary,
                      loading: _loading,
                    ),
                  ];
                  return Row(
                    children: [
                      Expanded(child: stats[0]),
                      const SizedBox(width: 10),
                      Expanded(child: stats[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Reveal(
                delay: const Duration(milliseconds: 60),
                child: _SettingRow(
                  icon: Icons.tune_rounded,
                  title: 'Style & weather',
                  subtitle: 'Personalize your AI stylist',
                  color: AppTheme.primary,
                  onTap: () => _editPreferences(auth),
                ),
              ),
              const SizedBox(height: 9),
              Reveal(
                delay: const Duration(milliseconds: 100),
                child: _SettingRow(
                  icon: Icons.info_outline_rounded,
                  title: 'About DressMate',
                  subtitle: 'Version 1.0 · Made for better mornings',
                  color: AppTheme.black,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showAboutDialog(
                      context: context,
                      applicationName: 'DressMate',
                      applicationVersion: '1.0.0',
                      applicationIcon: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                      children: const [
                        Text(
                          'A private, AI-powered wardrobe and styling companion.',
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 9),
              Reveal(
                delay: const Duration(milliseconds: 140),
                child: _SettingRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'Your wardrobe will stay right here',
                  color: AppTheme.secondary,
                  onTap: () => _signOut(auth),
                ),
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'DRESSMATE · WORN WITH INTENTION',
                  style: TextStyle(
                    color: AppTheme.lightGray,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    this.location,
    this.style,
  });
  final String name;
  final String email;
  final String? location;
  final String? style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.black, AppTheme.charcoal],
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      boxShadow: AppTheme.mediumShadow,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _HeroTag(
                  icon: Icons.location_on_outlined,
                  text: location?.isNotEmpty == true
                      ? location!
                      : 'Add your city',
                ),
                _HeroTag(
                  icon: Icons.auto_awesome_outlined,
                  text: style?.isNotEmpty == true
                      ? style!
                      : 'Define your style',
                ),
              ],
            ),
          ],
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isEmpty ? 'U' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 17),
            Expanded(child: identity),
          ],
        );
      },
    ),
  );
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 190),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.loading,
  });
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          _RoundIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.paleGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                else
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value.toDouble()),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (_, number, _) => Text(
                      '${number.round()}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(size * .34),
    ),
    child: Icon(icon, size: size * .46, color: color),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _RoundIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.lightGray,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}
