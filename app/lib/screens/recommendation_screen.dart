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
      'label': 'Sport',
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
          content: const Text('Outfit saved!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              const Text(
                'AI Stylist',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Get outfit recommendations from your wardrobe',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Occasion Selector ──
              const Text(
                'What\'s the occasion?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _occasions.map((o) {
                  final isSelected = _selectedOccasion == o['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOccasion = o['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryNavy
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        border: isSelected
                            ? null
                            : Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            o['icon'],
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            o['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Weather Selector ──
              const Text(
                'How\'s the weather?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weathers.map((w) {
                  final isSelected = _selectedWeather == w['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWeather = w['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentCoral
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        border: isSelected
                            ? null
                            : Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            w['icon'],
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            w['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // ── Generate Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentCoral,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _getRecommendation,
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Get Recommendation'),
                      ),
              ),
              const SizedBox(height: 24),

              // ── Result Card ──
              if (_result != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    boxShadow: AppTheme.mediumShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: AppTheme.accentCoral,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'AI Recommendation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _result!['model_used'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _result!['recommendation'] ?? 'No recommendation.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_result!['items_analyzed'] ?? 0} items analyzed',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _getRecommendation,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Try Again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveOutfit,
                              icon: const Icon(
                                Icons.bookmark_add_outlined,
                                size: 16,
                              ),
                              label: const Text('Save'),
                            ),
                          ),
                        ],
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
}
