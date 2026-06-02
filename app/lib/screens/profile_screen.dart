import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/item_service.dart';
import '../services/recommendation_service.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ItemService _itemService = ItemService();
  final RecommendationService _recService = RecommendationService();
  int _totalItems = 0;
  int _savedOutfits = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final items = await _itemService.getItems();
    final outfits = await _recService.getSavedOutfits();
    if (mounted) {
      setState(() {
        _totalItems = items?.length ?? 0;
        _savedOutfits = outfits?.length ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.user?['email'] ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // ── Avatar ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: Center(
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DressMate Member',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // ── Stats ──
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.accentCoral)
              else
                Row(
                  children: [
                    _buildStatCard(
                      Icons.checkroom_rounded,
                      '$_totalItems',
                      'Items',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      Icons.auto_awesome,
                      '$_savedOutfits',
                      'Saved Outfits',
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // ── Menu Items ──
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About DressMate',
                subtitle: 'Your smart wardrobe companion',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'DressMate',
                    applicationVersion: '1.0.0',
                    children: [
                      const Text(
                        'AI-powered wardrobe management and outfit recommendations.',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                isDestructive: true,
                onTap: () async {
                  await authProvider.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.accentCoral),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.accentCoral.withValues(alpha: 0.1)
                    : AppTheme.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? AppTheme.accentCoral
                    : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppTheme.accentCoral
                          : AppTheme.textPrimary,
                    ),
                  ),
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
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
