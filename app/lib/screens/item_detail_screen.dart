import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});
  final Map<String, dynamic> item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _service = ItemService();
  final _categories = const [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];
  late Map<String, dynamic> _item = Map.of(widget.item);
  late final _name = TextEditingController(text: _item['name'] ?? '');
  late final _color = TextEditingController(text: _item['color'] ?? '');
  late final _style = TextEditingController(text: _item['style'] ?? '');
  late final _season = TextEditingController(text: _item['season'] ?? '');
  late String _category = _categories.contains(_item['category'])
      ? _item['category']
      : 'Tops';
  bool _editing = false;
  bool _saving = false;
  int _imageIndex = 0;

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _style.dispose();
    _season.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final updated = await _service.updateItem(
      _item['id'] as int,
      name: _name.text.trim(),
      category: _category,
      color: _color.text.trim(),
      style: _style.text.trim(),
      season: _season.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (updated != null) {
        _item = updated;
        _editing = false;
      }
    });
    if (updated != null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piece updated — looking good.')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppTheme.blush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove this piece?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'It will also disappear from saved outfits that use it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep it'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    if (await _service.deleteItem(_item['id'] as int) && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton.outlined(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context, _editing ? null : true),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(_editing ? 'Edit piece' : 'Piece details'),
      actions: [
        IconButton(
          tooltip: _editing ? 'Cancel editing' : 'Edit piece',
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _editing = !_editing);
          },
          icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete piece',
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final image = _ImageGallery(
          item: _item,
          index: _imageIndex,
          onChanged: (value) => setState(() => _imageIndex = value),
        );
        final details = AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          child: _editing
              ? _EditForm(
                  key: const ValueKey('edit'),
                  name: _name,
                  color: _color,
                  style: _style,
                  season: _season,
                  categories: _categories,
                  category: _category,
                  saving: _saving,
                  onCategory: (value) => setState(() => _category = value),
                  onSave: _save,
                )
              : _Details(key: const ValueKey('details'), item: _item),
        );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: AspectRatio(aspectRatio: .82, child: image),
                        ),
                        const SizedBox(width: 34),
                        Expanded(
                          flex: 9,
                          child: SingleChildScrollView(child: details),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        AspectRatio(aspectRatio: .9, child: image),
                        const SizedBox(height: 24),
                        details,
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.item,
    required this.index,
    required this.onChanged,
  });
  final Map<String, dynamic> item;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final urls = [
      item['image_url'],
      if (item['back_image_url'] != null) item['back_image_url'],
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: onChanged,
            itemBuilder: (_, imageIndex) {
              final image = Image.network(
                '${Constants.baseUrl}${urls[imageIndex]}',
                headers: AuthService.cachedHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppTheme.white,
                  child: Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      size: 64,
                      color: AppTheme.lightGray,
                    ),
                  ),
                ),
              );
              return imageIndex == 0
                  ? Hero(
                      tag: 'wardrobe-item-${item['id']}',
                      child: Material(color: AppTheme.white, child: image),
                    )
                  : image;
            },
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    index == 0 ? 'Front view' : 'Back view',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({super.key, required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Reveal(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['category']?.toString().toUpperCase() ?? 'WARDROBE PIECE',
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['name'] ?? 'Unnamed piece',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _Meta(
              icon: Icons.palette_outlined,
              value: item['color'] ?? 'Color not set',
            ),
            _Meta(
              icon: Icons.style_outlined,
              value: item['style'] ?? 'Style not set',
            ),
            _Meta(
              icon: Icons.calendar_today_outlined,
              value: item['season'] ?? 'Any season',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.lavender,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This piece is available to your AI stylist for new outfit ideas.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 7),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    super.key,
    required this.name,
    required this.color,
    required this.style,
    required this.season,
    required this.categories,
    required this.category,
    required this.saving,
    required this.onCategory,
    required this.onSave,
  });
  final TextEditingController name;
  final TextEditingController color;
  final TextEditingController style;
  final TextEditingController season;
  final List<String> categories;
  final String category;
  final bool saving;
  final ValueChanged<String> onCategory;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Make it yours', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 7),
      const Text(
        'Clear details help your stylist make better choices.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: name,
        decoration: const InputDecoration(
          labelText: 'Piece name',
          prefixIcon: Icon(Icons.checkroom_outlined),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: category,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: categories
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => onCategory(value!),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: color,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: style,
              decoration: const InputDecoration(labelText: 'Style'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: season,
        decoration: const InputDecoration(
          labelText: 'Season',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(saving ? 'Saving…' : 'Save changes'),
        ),
      ),
    ],
  );
}
