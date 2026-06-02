import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ItemService _itemService = ItemService();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _styleController = TextEditingController();
  final _seasonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _styleController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  XFile? _imageFile;
  XFile? _backImageFile;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedCategory = 'Tops';

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _imageFile = pickedFile;
          _isAnalyzing = true;
        } else {
          _backImageFile = pickedFile;
        }
      });

      if (isFront) {
        final tags = await _itemService.analyzeImage(pickedFile);
        if (mounted && tags != null) {
          setState(() {
            if (tags['category'] != null) {
              final aiCat = tags['category'].toString().toLowerCase();
              for (var c in _categories) {
                if (c.toLowerCase() == aiCat) {
                  _selectedCategory = c;
                  break;
                }
              }
            }
            if (tags['color'] != null) {
              _colorController.text = tags['color'].toString();
            }
            if (tags['style'] != null) {
              _styleController.text = tags['style'].toString();
            }
            if (tags['season'] != null) {
              _seasonController.text = tags['season'].toString();
            }
            if (_nameController.text.isEmpty &&
                tags['color'] != null &&
                tags['category'] != null) {
              _nameController.text = "${tags['color']} ${tags['category']}";
            }
            _isAnalyzing = false;
          });
        } else {
          if (mounted) setState(() => _isAnalyzing = false);
        }
      }
    }
  }

  Future<void> _uploadAndSave() async {
    if (_imageFile == null) {
      _showError('Please select a front image first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload front image
      final imageUrl = await _itemService.uploadImage(_imageFile!);
      if (imageUrl == null) {
        _showError('Failed to upload front image.');
        return;
      }

      // 2. Upload back image if selected
      String? backImageUrl;
      if (_backImageFile != null) {
        backImageUrl = await _itemService.uploadImage(_backImageFile!);
        if (backImageUrl == null) {
          _showError('Failed to upload back image.');
          return;
        }
      }

      // 3. Create the clothing item with both URLs
      final item = await _itemService.createItem(
        imageUrl: imageUrl,
        backImageUrl: backImageUrl,
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        category: _selectedCategory,
        color: _colorController.text.isNotEmpty ? _colorController.text : null,
        style: _styleController.text.isNotEmpty ? _styleController.text : null,
        season: _seasonController.text.isNotEmpty
            ? _seasonController.text
            : null,
      );

      if (item != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Item added to wardrobe!'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError('Failed to save item details.');
      }
    } catch (e) {
      _showError('An error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.accentCoral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  Widget _buildImagePlaceholder(
    IconData icon,
    String label, {
    required bool isRequired,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isRequired ? AppTheme.accentCoral : AppTheme.primaryNavy)
                .withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isRequired ? AppTheme.accentCoral : AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteOverlay(VoidCallback onDelete) {
    return Stack(
      children: [
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              onDelete();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dual Image Slots ──
            Row(
              children: [
                // ── Front Image ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Front View *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImagePicker(true),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            border: Border.all(
                              color: _imageFile != null
                                  ? Colors.transparent
                                  : AppTheme.borderLight,
                              width: 1,
                            ),
                            boxShadow: AppTheme.softShadow,
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_imageFile!.path)
                                              as ImageProvider
                                        : FileImage(File(_imageFile!.path))
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imageFile == null
                              ? _buildImagePlaceholder(
                                  Icons.checkroom_rounded,
                                  'Add Front View',
                                  isRequired: true,
                                )
                              : _isAnalyzing
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accentCoral,
                                  ),
                                )
                              : _buildDeleteOverlay(() {
                                  setState(() {
                                    _imageFile = null;
                                  });
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ── Back Image ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Back View (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImagePicker(false),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            border: Border.all(
                              color: _backImageFile != null
                                  ? Colors.transparent
                                  : AppTheme.borderLight,
                              width: 1,
                            ),
                            boxShadow: AppTheme.softShadow,
                            image: _backImageFile != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_backImageFile!.path)
                                              as ImageProvider
                                        : FileImage(File(_backImageFile!.path))
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _backImageFile == null
                              ? _buildImagePlaceholder(
                                  Icons.flip_camera_android_rounded,
                                  'Add Back View',
                                  isRequired: false,
                                )
                              : _buildDeleteOverlay(() {
                                  setState(() {
                                    _backImageFile = null;
                                  });
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Category ──
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
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
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryNavy
                          : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: isSelected
                          ? null
                          : Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      cat,
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
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Name ──
            const Text(
              'Name',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Classic Navy Blazer',
              ),
            ),
            const SizedBox(height: 20),

            // ── Color ──
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(hintText: 'e.g., Navy Blue'),
            ),
            const SizedBox(height: 20),

            // ── Style ──
            const Text(
              'Style',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _styleController,
              decoration: const InputDecoration(hintText: 'e.g., Casual'),
            ),
            const SizedBox(height: 20),

            // ── Season ──
            const Text(
              'Season',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seasonController,
              decoration: const InputDecoration(hintText: 'e.g., Winter'),
            ),
            const SizedBox(height: 36),

            // ── CTA ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentCoral,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _uploadAndSave,
                      icon: const Icon(Icons.checkroom_rounded, size: 20),
                      label: const Text('Add to Wardrobe'),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(bool isFront) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFront
                  ? 'Choose Front Image Source'
                  : 'Choose Back Image Source',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.accentCoral,
                ),
              ),
              title: const Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Take a new photo',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isFront);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryNavy,
                ),
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Choose from your photos',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isFront);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
