import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../utils/app_theme.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final RecommendationService _service = RecommendationService();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  String _selectedOccasion = 'casual';
  String _selectedWeather = 'clear';

  final List<Map<String, dynamic>> _occasions = [
    {'label': 'Casual', 'value': 'casual', 'icon': Icons.weekend_outlined},
    {
      'label': 'Formal',
      'value': 'formal',
      'icon': Icons.business_center_outlined,
    },
    {'label': 'Party', 'value': 'party', 'icon': Icons.celebration_outlined},
    {'label': 'Work', 'value': 'work', 'icon': Icons.work_outline},
    {'label': 'Date', 'value': 'date', 'icon': Icons.favorite_outline},
    {
      'label': 'Sporty',
      'value': 'sporty',
      'icon': Icons.fitness_center_outlined,
    },
  ];

  final List<Map<String, dynamic>> _weathers = [
    {'label': 'Clear', 'value': 'clear', 'icon': Icons.wb_sunny_outlined},
    {'label': 'Cloudy', 'value': 'cloudy', 'icon': Icons.cloud_outlined},
    {'label': 'Rainy', 'value': 'rainy', 'icon': Icons.grain_outlined},
    {'label': 'Cold', 'value': 'cold', 'icon': Icons.ac_unit_outlined},
    {'label': 'Hot', 'value': 'hot', 'icon': Icons.whatshot_outlined},
  ];

  Future<void> _getRecommendation() async {
    setState(() => _isLoading = true);
    final result = await _service.getOutfitRecommendation(
      occasion: _selectedOccasion,
      weather: _selectedWeather,
    );
    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOutfit() async {
    if (_result == null) return;
    final saved = await _service.saveOutfit(
      recommendationText: _result!['recommendation'] ?? '',
      occasion: _selectedOccasion,
      weather: _selectedWeather,
    );
    if (mounted && saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Outfit saved to collection!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI Stylist',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalized outfit ideas generated from your wardrobe items.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ── Occasion Section ──
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'What\'s the occasion?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOccasionGrid(),
              const SizedBox(height: 32),

              // ── Weather Section ──
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'How\'s the weather?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeatherRow(),
              const SizedBox(height: 36),

              // ── Generate Button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: !_isLoading ? AppTheme.primaryGradient : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: !_isLoading ? AppTheme.primaryGlow : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _getRecommendation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? AppTheme.paleGray : Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox() // Handled by the loading card below
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Generate Outfit Recommendation',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              // ── Loading Card ──
              if (_isLoading) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: AppTheme.mediumShadow,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      const _PulsingSparkleIcon(),
                      const SizedBox(height: 20),
                      const Text(
                        'Analyzing your wardrobe...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Finding the perfect match for the occasion & weather',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceBlueTint,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Result Card ──
              if (_result != null && !_isLoading) ...[
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: AppTheme.mediumShadow,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top gradient accent bar
                      Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusXL),
                            topRight: Radius.circular(AppTheme.radiusXL),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceBlueTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'AI Recommendation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (_result!['model_used'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfacePinkTint,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: Text(
                                      _result!['model_used'] ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _result!['recommendation'] ?? 'No recommendation available.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Based on ${_result!['items_analyzed'] ?? 0} analyzed items in your closet',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _getRecommendation,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Try Again'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.secondaryGradient,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      boxShadow: AppTheme.secondaryGlow,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _saveOutfit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                        ),
                                      ),
                                      icon: const Icon(Icons.bookmark_add, size: 18),
                                      label: const Text('Save Outfit'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccasionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _occasions.length,
      itemBuilder: (context, index) {
        final o = _occasions[index];
        final isSelected = _selectedOccasion == o['value'];
        return GestureDetector(
          onTap: () {
            Feedback.forTap(context);
            setState(() => _selectedOccasion = o['value']);
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: isSelected
                  ? null
                  : Border.all(color: AppTheme.borderLight, width: 1.5),
              boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppTheme.durationFast,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.surfaceBlueTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    o['icon'],
                    size: 22,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  o['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherRow() {
    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weathers.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final w = _weathers[index];
          final isSelected = _selectedWeather == w['value'];

          Color weatherColor;
          switch (w['value']) {
            case 'clear':
              weatherColor = Colors.orange;
              break;
            case 'cloudy':
              weatherColor = Colors.blueGrey;
              break;
            case 'rainy':
              weatherColor = Colors.blue;
              break;
            case 'cold':
              weatherColor = Colors.cyan;
              break;
            case 'hot':
              weatherColor = Colors.deepOrange;
              break;
            default:
              weatherColor = AppTheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Feedback.forTap(context);
                setState(() => _selectedWeather = w['value']);
              },
              child: AnimatedContainer(
                duration: AppTheme.durationFast,
                width: 90,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.secondaryGradient : null,
                  color: isSelected ? null : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: isSelected
                      ? null
                      : Border.all(color: AppTheme.borderLight, width: 1.5),
                  boxShadow: isSelected ? AppTheme.secondaryGlow : AppTheme.softShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      w['icon'],
                      size: 24,
                      color: isSelected ? Colors.white : weatherColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
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
}

class _PulsingSparkleIcon extends StatefulWidget {
  const _PulsingSparkleIcon();

  @override
  State<_PulsingSparkleIcon> createState() => _PulsingSparkleIconState();
}

class _PulsingSparkleIconState extends State<_PulsingSparkleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.primaryGlow,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }
}
