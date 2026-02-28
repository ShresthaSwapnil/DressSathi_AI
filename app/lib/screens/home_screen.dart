import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ItemService _itemService = ItemService();
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _itemService.getItems();
    if (mounted) {
      setState(() {
        _items = items ?? [];
        _filterItems();
        _isLoading = false;
      });
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesCategory =
            _selectedCategory == 'All' ||
            (item['category'] ?? '').toString().toLowerCase() ==
                _selectedCategory.toLowerCase();
        final matchesSearch =
            _searchController.text.isEmpty ||
            (item['name'] ?? '').toString().toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.user?['email'] ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Wardrobe',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_items.length} items • Just now',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await authProvider.logout();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: AppTheme.softShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search wardrobe...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Tabs ──
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => _selectCategory(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
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
                      child: Text(
                        category,
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
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Items Grid ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentCoral,
                      ),
                    )
                  : _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checkroom_outlined,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _items.isEmpty
                                ? 'Your wardrobe is empty'
                                : 'No items match your filter',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items.isEmpty
                                ? 'Tap + to add your first item'
                                : 'Try a different category or search term',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      color: AppTheme.accentCoral,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final fullImageUrl =
                              '${Constants.baseUrl}${item['image_url']}';

                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                              boxShadow: AppTheme.softShadow,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceWhite,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Image.network(
                                      fullImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.checkroom_outlined,
                                                size: 40,
                                                color: AppTheme.textSecondary
                                                    .withOpacity(0.3),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Unnamed Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['category'] ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadScreen()),
          );
          if (result == true) _loadItems();
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
