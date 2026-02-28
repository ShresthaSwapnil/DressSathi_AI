import 'dart:io';
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

  XFile? _imageFile;
  bool _isLoading = false;
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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _uploadAndSave() async {
    if (_imageFile == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _itemService.uploadImage(_imageFile!);

      if (imageUrl != null) {
        final item = await _itemService.createItem(
          imageUrl: imageUrl,
          name: _nameController.text.isNotEmpty ? _nameController.text : null,
          category: _selectedCategory,
          color: _colorController.text.isNotEmpty
              ? _colorController.text
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
      } else {
        _showError('Failed to upload image.');
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
            // ── Image Preview ──
            GestureDetector(
              onTap: () => _showImagePicker(),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.softShadow,
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(File(_imageFile!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 28,
                              color: AppTheme.accentCoral,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to add photo',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo or choose from gallery',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            // ── Camera/Gallery Buttons ──
            if (_imageFile != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Retake'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Choose Another'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
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

  void _showImagePicker() {
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
            const Text(
              'Choose Image Source',
              style: TextStyle(
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
                  color: AppTheme.accentCoral.withOpacity(0.1),
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
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withOpacity(0.1),
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
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
