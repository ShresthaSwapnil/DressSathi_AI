import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ItemService _itemService = ItemService();
  late Map<String, dynamic> _item;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  String _selectedCategory = 'Tops';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
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
          content: const Text('Item updated!'),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to remove this from your wardrobe?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.accentCoral),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _itemService.deleteItem(_item['id']);
      if (success && mounted) {
        Navigator.pop(context, true); // return true to refresh parent
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = '${Constants.baseUrl}${_item['image_url']}';

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: CustomScrollView(
        slivers: [
          // ── Image App Bar ──
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppTheme.surfaceWhite,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.close : Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppTheme.accentCoral,
                  ),
                ),
                onPressed: _deleteItem,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceWhite,
                    child: const Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Details ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _isEditing ? _buildEditForm() : _buildDetails(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _item['name'] ?? 'Unnamed Item',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailChip(
          Icons.category_outlined,
          'Category',
          _item['category'] ?? 'Not set',
        ),
        const SizedBox(height: 10),
        _buildDetailChip(
          Icons.palette_outlined,
          'Color',
          _item['color'] ?? 'Not set',
        ),
        if (_item['style'] != null) ...[
          const SizedBox(height: 10),
          _buildDetailChip(Icons.style_outlined, 'Style', _item['style']),
        ],
        if (_item['season'] != null) ...[
          const SizedBox(height: 10),
          _buildDetailChip(
            Icons.calendar_today_outlined,
            'Season',
            _item['season'],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentCoral),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Item',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Item name'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryNavy : AppTheme.cardWhite,
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
        const SizedBox(height: 16),
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(hintText: 'Item color'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _updateItem,
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
