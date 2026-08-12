import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_ui.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _service = ItemService();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _color = TextEditingController();
  final _style = TextEditingController();
  final _season = TextEditingController();
  final _categories = const [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];
  XFile? _front;
  XFile? _back;
  String _category = 'Tops';
  bool _analyzing = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _style.dispose();
    _season.dispose();
    super.dispose();
  }

  Future<ImageSource?> _source() => showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add a photo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Library',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _pick(bool front) async {
    HapticFeedback.selectionClick();
    final source = await _source();
    if (source == null) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (front) {
        _front = file;
        _analyzing = true;
      } else {
        _back = file;
      }
    });
    HapticFeedback.mediumImpact();
    if (!front) return;
    final tags = await _service.analyzeImage(file);
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (tags == null) return;
      final category = tags['category']?.toString();
      final matched = _categories
          .where((value) => value.toLowerCase() == category?.toLowerCase())
          .firstOrNull;
      if (matched != null) _category = matched;
      _color.text = tags['color']?.toString() ?? _color.text;
      _style.text = tags['style']?.toString() ?? _style.text;
      _season.text = tags['season']?.toString() ?? _season.text;
      if (_name.text.isEmpty &&
          tags['color'] != null &&
          tags['category'] != null) {
        _name.text = '${tags['color']} ${tags['category']}';
      }
    });
    if (tags != null) HapticFeedback.heavyImpact();
  }

  Future<void> _save() async {
    if (_front == null) {
      HapticFeedback.vibrate();
      _message('Add a front photo first.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _uploading = true);
    try {
      final frontUrl = await _service.uploadImage(_front!);
      if (frontUrl == null) {
        return _message('The front image could not be uploaded.');
      }
      final backUrl = _back == null ? null : await _service.uploadImage(_back!);
      if (_back != null && backUrl == null) {
        return _message('The back image could not be uploaded.');
      }
      final item = await _service.createItem(
        imageUrl: frontUrl,
        backImageUrl: backUrl,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        category: _category,
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        style: _style.text.trim().isEmpty ? null : _style.text.trim(),
        season: _season.text.trim().isEmpty ? null : _season.text.trim(),
      );
      if (!mounted) return;
      if (item == null) return _message('The piece could not be saved.');
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessCheck(),
              const SizedBox(height: 16),
              Text(
                'Welcome to the wardrobe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              const Text(
                'Your new piece is ready to style.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ).timeout(
        const Duration(milliseconds: 950),
        onTimeout: () {
          if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _message('Something interrupted the upload. Try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    setState(() => _uploading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton.outlined(
        tooltip: 'Close',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
      title: const Text('Add a piece'),
      actions: [
        TextButton(
          onPressed: _uploading ? null : _save,
          child: const Text('Save'),
        ),
        const SizedBox(width: 10),
      ],
    ),
    body: Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final photos = _PhotoSection(
              front: _front,
              back: _back,
              analyzing: _analyzing,
              onFront: () => _pick(true),
              onBack: () => _pick(false),
              onRemoveFront: () => setState(() => _front = null),
              onRemoveBack: () => setState(() => _back = null),
            );
            final details = _DetailsSection(
              categories: _categories,
              category: _category,
              onCategory: (value) {
                HapticFeedback.selectionClick();
                setState(() => _category = value);
              },
              name: _name,
              color: _color,
              style: _style,
              season: _season,
              uploading: _uploading,
              onSave: _save,
            );
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: photos),
                            const SizedBox(width: 34),
                            Expanded(
                              flex: 9,
                              child: SingleChildScrollView(child: details),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            photos,
                            const SizedBox(height: 28),
                            details,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _uploading
              ? Positioned.fill(
                  key: const ValueKey('uploading'),
                  child: ColoredBox(
                    color: AppTheme.offWhite.withValues(alpha: .94),
                    child: const Center(
                      child: LottieStatus(
                        asset: 'assets/animations/uploading.json',
                        title: 'Preparing your piece',
                        subtitle:
                            'Removing the background and organizing the details…',
                        size: 148,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('ready')),
        ),
      ],
    ),
  );
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.front,
    required this.back,
    required this.analyzing,
    required this.onFront,
    required this.onBack,
    required this.onRemoveFront,
    required this.onRemoveBack,
  });
  final XFile? front;
  final XFile? back;
  final bool analyzing;
  final VoidCallback onFront;
  final VoidCallback onBack;
  final VoidCallback onRemoveFront;
  final VoidCallback onRemoveBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Show us the piece',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 7),
      const Text(
        'Natural light and a simple background work best.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: .72,
              child: _PhotoTile(
                file: front,
                label: 'Front view',
                required: true,
                analyzing: analyzing,
                onTap: onFront,
                onRemove: onRemoveFront,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: .72,
              child: _PhotoTile(
                file: back,
                label: 'Back view',
                required: false,
                analyzing: false,
                onTap: onBack,
                onRemove: onRemoveBack,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'AI fills color, style, and season when it recognizes the piece.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.file,
    required this.label,
    required this.required,
    required this.analyzing,
    required this.onTap,
    required this.onRemove,
  });
  final XFile? file;
  final String label;
  final bool required;
  final bool analyzing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  ImageProvider? get _image => file == null
      ? null
      : kIsWeb
      ? NetworkImage(file!.path)
      : FileImage(File(file!.path));

  @override
  Widget build(BuildContext context) => Hero(
    tag: required ? 'upload-front' : 'upload-back',
    child: Material(
      color: Colors.transparent,
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: required ? AppTheme.lavender : AppTheme.white,
            image: _image == null
                ? null
                : DecorationImage(image: _image!, fit: BoxFit.cover),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: _image == null ? AppTheme.borderLight : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              if (_image == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: required ? AppTheme.primary : AppTheme.midGray,
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        required ? 'Required' : 'Optional',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (file != null)
                Positioned(
                  top: 9,
                  right: 9,
                  child: IconButton.filledTonal(
                    tooltip: 'Remove photo',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              if (analyzing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.black.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: const Center(
                      child: LottieStatus(
                        asset: 'assets/animations/ai_thinking.json',
                        title: 'Reading the details',
                        subtitle: 'Color, style, season…',
                        size: 86,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.categories,
    required this.category,
    required this.onCategory,
    required this.name,
    required this.color,
    required this.style,
    required this.season,
    required this.uploading,
    required this.onSave,
  });
  final List<String> categories;
  final String category;
  final ValueChanged<String> onCategory;
  final TextEditingController name;
  final TextEditingController color;
  final TextEditingController style;
  final TextEditingController season;
  final bool uploading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Add a little context',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 7),
      const Text(
        'These details make recommendations feel more personal.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: name,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Navy linen shirt',
          prefixIcon: Icon(Icons.checkroom_outlined),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: value == category,
                labelStyle: TextStyle(
                  color: value == category ? Colors.white : AppTheme.black,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => onCategory(value),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
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
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: uploading ? null : onSave,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add to wardrobe'),
        ),
      ),
    ],
  );
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
  );
}
