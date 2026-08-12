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
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // ── Header Title ──
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'My Space',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Premium Avatar ──
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.primaryGlow,
                  ),
                  padding: const EdgeInsets.all(3.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Email and Verified Badge ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Member Badge ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlueTint,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: const Text(
                    'DressMate Member',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Stats Section ──
                if (_isLoading)
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: AppTheme.primary),
                  )
                else
                  Row(
                    children: [
                      _buildStatCard(
                        Icons.checkroom_rounded,
                        '$_totalItems',
                        'Wardrobe Items',
                        AppTheme.primaryGradient,
                        AppTheme.primaryGlow,
                      ),
                      const SizedBox(width: 14),
                      _buildStatCard(
                        Icons.auto_awesome,
                        '$_savedOutfits',
                        'Saved Outfits',
                        AppTheme.secondaryGradient,
                        AppTheme.secondaryGlow,
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // ── Menu Options ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About DressMate',
                      subtitle: 'Smart closet companion info',
                      iconColor: AppTheme.primary,
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'DressMate',
                          applicationVersion: '1.0.0',
                          applicationIcon: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: const Icon(
                              Icons.checkroom_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          children: const [
                            SizedBox(height: 12),
                            Text(
                              'DressMate is an AI-powered wardrobe organizer and social fashion stylist that suggests fits based on the current weather and your physical items.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Safely disconnect account',
                      iconColor: AppTheme.secondary,
                      isDestructive: true,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.cardWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            ),
                            title: const Text(
                              'Sign Out',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Are you sure you want to log out of your DressMate account?',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await authProvider.logout();
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 48),
                // ── Footer Branding ──
                Text(
                  'D R E S S M A T E',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary.withValues(alpha: 0.35),
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0 (Beta)',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    LinearGradient gradient,
    List<BoxShadow> glow,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: glow,
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDestructive ? AppTheme.surfacePinkTint : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: isDestructive ? AppTheme.secondary.withValues(alpha: 0.1) : AppTheme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppTheme.secondary.withValues(alpha: 0.15)
                      : AppTheme.surfaceBlueTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDestructive ? AppTheme.secondary : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDestructive ? AppTheme.secondary.withValues(alpha: 0.7) : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive
                    ? AppTheme.secondary.withValues(alpha: 0.4)
                    : AppTheme.textSecondary.withValues(alpha: 0.45),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
