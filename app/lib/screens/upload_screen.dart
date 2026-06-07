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

  final List<Map<String, dynamic>> _categoriesData = [
    {'label': 'Tops', 'icon': Icons.checkroom_rounded},
    {'label': 'Bottoms', 'icon': Icons.style_outlined},
    {'label': 'Dresses', 'icon': Icons.woman_rounded},
    {'label': 'Outerwear', 'icon': Icons.layers_outlined},
    {'label': 'Shoes', 'icon': Icons.hiking_rounded},
    {'label': 'Accessories', 'icon': Icons.watch_rounded},
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
              for (var c in _categoriesData) {
                if (c['label'].toString().toLowerCase() == aiCat) {
                  _selectedCategory = c['label'];
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
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Item added to wardrobe successfully!'),
                ],
              ),
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
      _showError('An error occurred while uploading.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.errorRed,
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
    return CustomPaint(
      painter: DashedBorderPainter(
        color: isRequired ? AppTheme.secondary.withValues(alpha: 0.4) : AppTheme.borderLight,
      ),
      child: Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isRequired ? AppTheme.secondary : AppTheme.primary)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isRequired ? AppTheme.secondary : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRequired ? 'Required' : 'Optional',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteOverlay(VoidCallback onDelete) {
    return Positioned(
      top: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          onDelete();
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow,
          ),
          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
        ),
      ),
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
              border: Border.all(color: AppTheme.borderLight),
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
          'Add New Item',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      Row(
                        children: [
                          const Text(
                            'Front View',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showImagePicker(true),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (_imageFile == null)
                                _buildImagePlaceholder(
                                  Icons.checkroom_rounded,
                                  'Add Front View',
                                  isRequired: true,
                                )
                              else ...[
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    image: DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_imageFile!.path) as ImageProvider
                                          : FileImage(File(_imageFile!.path)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Analysis Loader Overlay
                                if (_isAnalyzing)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                                SizedBox(width: 4),
                                                Text(
                                                  'AI Scanning...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (!_isAnalyzing)
                                  _buildDeleteOverlay(() {
                                    setState(() {
                                      _imageFile = null;
                                    });
                                  }),
                              ],
                            ],
                          ),
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
                        'Back View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showImagePicker(false),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (_backImageFile == null)
                                _buildImagePlaceholder(
                                  Icons.flip_camera_android_rounded,
                                  'Add Back View',
                                  isRequired: false,
                                )
                              else ...[
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    image: DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_backImageFile!.path) as ImageProvider
                                          : FileImage(File(_backImageFile!.path)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                _buildDeleteOverlay(() {
                                  setState(() {
                                    _backImageFile = null;
                                  });
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Category Section ──
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
                  'Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _categoriesData.map((cat) {
                final isSelected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['label']),
                  child: AnimatedContainer(
                    duration: AppTheme.durationFast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: isSelected
                          ? null
                          : Border.all(color: AppTheme.borderLight, width: 1.5),
                      boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Text Inputs Section ──
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
                  'Clothing Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Item Name ──
            const Text(
              'Item Name',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Classic Navy Blazer',
                  prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Color ──
            const Text(
              'Color',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
              child: TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Dark Navy Blue',
                  prefixIcon: Icon(Icons.palette_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Style ──
            const Text(
              'Style',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
              child: TextField(
                controller: _styleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Smart Casual',
                  prefixIcon: Icon(Icons.style_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Season ──
            const Text(
              'Season',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
              child: TextField(
                controller: _seasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Autumn / Winter',
                  prefixIcon: Icon(Icons.wb_sunny_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── CTA Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: (!_isLoading && _imageFile != null) ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: (!_isLoading && _imageFile != null) ? AppTheme.primaryGlow : null,
                ),
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _imageFile == null) ? null : _uploadAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_imageFile == null)
                        ? AppTheme.paleGray
                        : (_isLoading ? AppTheme.primaryNavy : Colors.transparent),
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.checkroom_rounded, size: 20),
                  label: Text(
                    _isLoading ? 'Adding Item...' : 'Add to Wardrobe',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFront ? 'Choose Front Image' : 'Choose Back Image',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFront
                  ? 'We will automatically scan this image using AI to extract style tags.'
                  : 'Add a secondary angle for complete details (optional).',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera, isFront);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlueTint,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Take Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use your camera',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, isFront);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfacePinkTint,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: AppTheme.secondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Upload Gallery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose from photos',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(AppTheme.radiusLarge),
      ));

    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = gap;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += length * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
