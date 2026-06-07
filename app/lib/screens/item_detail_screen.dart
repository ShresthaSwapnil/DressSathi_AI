import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  final ItemService _itemService = ItemService();
  late Map<String, dynamic> _item;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  String _selectedCategory = 'Tops';

  int _currentPage = 0;
  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _slideUpAnimation;

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _nameController = TextEditingController(text: _item['name'] ?? '');
    _colorController = TextEditingController(text: _item['color'] ?? '');
    _selectedCategory = _item['category'] ?? 'Tops';
    _pageController = PageController();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideUpAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.surfaceWhite,
          child: Center(
            child: Icon(
              Icons.checkroom_outlined,
              size: 56,
              color: AppTheme.lightGray.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateItem() async {
    final updated = await _itemService.updateItem(
      _item['id'],
      name: _nameController.text,
      category: _selectedCategory,
      color: _colorController.text,
    );
    if (updated != null && mounted) {
      setState(() {
        _item = updated;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Item updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Remove Item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently remove this item from your wardrobe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final success = await _itemService.deleteItem(_item['id']);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBackImage = _item['back_image_url'] != null;
    final pageCount = hasBackImage ? 2 : 1;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: CustomScrollView(
        slivers: [
          // ── Image Hero Area ──
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppTheme.surfaceWhite,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildCircleButton(
                  icon: _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isEditing = !_isEditing);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCircleButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.secondary,
                  onTap: _deleteItem,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image / carousel
                  if (hasBackImage)
                    PageView(
                      controller: _pageController,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      children: [
                        _buildNetworkImage(
                          '${Constants.baseUrl}${_item['image_url']}',
                        ),
                        _buildNetworkImage(
                          '${Constants.baseUrl}${_item['back_image_url']}',
                        ),
                      ],
                    )
                  else
                    _buildNetworkImage(
                      '${Constants.baseUrl}${_item['image_url']}',
                    ),

                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.surfaceWhite.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Page indicator
                  if (hasBackImage)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.offBlack.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(pageCount, (i) {
                              final isActive = _currentPage == i;
                              return Container(
                                width: isActive ? 20 : 6,
                                height: 6,
                                margin: EdgeInsets.only(right: i < pageCount - 1 ? 6 : 0),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Details ──
          SliverToBoxAdapter(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_slideUpAnimation),
              child: FadeTransition(
                opacity: _slideUpAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: _isEditing ? _buildEditForm() : _buildDetails(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, size: 18, color: color ?? AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item name
        Text(
          _item['name'] ?? 'Unnamed Item',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),

        // Properties card
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              _buildDetailRow(
                Icons.category_rounded,
                'Category',
                _item['category'] ?? 'Not set',
                AppTheme.primary,
                isFirst: true,
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.palette_rounded,
                'Color',
                _item['color'] ?? 'Not set',
                AppTheme.secondary,
              ),
              if (_item['style'] != null) ...[
                _buildDivider(),
                _buildDetailRow(
                  Icons.style_rounded,
                  'Style',
                  _item['style'],
                  const Color(0xFF8B5CF6),
                ),
              ],
              if (_item['season'] != null) ...[
                _buildDivider(),
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Season',
                  _item['season'],
                  AppTheme.successGreen,
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppTheme.borderLight.withValues(alpha: 0.5)),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Item',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Name field
        _buildFieldLabel('Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Item name'),
        ),
        const SizedBox(height: 20),

        // Category
        _buildFieldLabel('Category'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: AppTheme.durationMedium,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: isSelected
                      ? null
                      : Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Color field
        _buildFieldLabel('Color'),
        const SizedBox(height: 8),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(hintText: 'Item color'),
        ),
        const SizedBox(height: 28),

        // Save button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.primaryGlow,
            ),
            child: ElevatedButton(
              onPressed: _updateItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
