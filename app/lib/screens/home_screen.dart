import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _service = ItemService();
  final _search = TextEditingController();
  final _categories = const [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];
  List<dynamic> _items = [];
  String _category = 'All';
  bool _loading = true;
  bool _failed = false;

  List<dynamic> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _items.where((item) {
      final category = '${item['category'] ?? ''}'.toLowerCase();
      final matchesCategory =
          _category == 'All' || category == _category.toLowerCase();
      final haystack = '${item['name'] ?? ''} ${item['color'] ?? ''} $category'
          .toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> refreshItems() => _load();

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final items = await _service.getItems();
    if (!mounted) return;
    setState(() {
      _items = items ?? [];
      _failed = items == null;
      _loading = false;
    });
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    HapticFeedback.selectionClick();
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};
    final name = (user['display_name'] ?? user['email'] ?? 'there').toString();
    final shortName = name.contains('@')
        ? name.split('@').first
        : name.split(' ').first;
    return Scaffold(
      body: AppPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(
              eyebrow: _greeting,
              title: 'Hey, $shortName',
              subtitle: _items.isEmpty
                  ? 'Let’s build a wardrobe you love wearing.'
                  : '${_items.length} pieces, ready to become an outfit.',
              action: _Avatar(name: name),
            ),
            const SizedBox(height: 24),
            _WardrobeInsight(items: _items),
            const SizedBox(height: 22),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search pieces, colors, categories…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final value = _categories[index];
                  return ChoiceChip(
                    label: Text(value),
                    selected: value == _category,
                    labelStyle: TextStyle(
                      color: value == _category
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _category = value);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: _content),
          ],
        ),
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Widget get _content {
    if (_loading) return const _WardrobeSkeleton();
    if (_failed) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Your wardrobe is out of reach',
        subtitle: 'Check your connection and try once more.',
        action: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return EmptyState(
        icon: _items.isEmpty
            ? Icons.add_photo_alternate_outlined
            : Icons.search_off_rounded,
        title: _items.isEmpty ? 'Your wardrobe starts here' : 'No pieces found',
        subtitle: _items.isEmpty
            ? 'Tap the + button and add your first favorite piece.'
            : 'Try another search or category.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveColumns(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: _load,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: constraints.maxWidth < 400 ? .69 : .76,
            ),
            itemCount: visible.length,
            itemBuilder: (_, index) => Reveal(
              delay: Duration(milliseconds: 35 * (index.clamp(0, 8))),
              child: _WardrobeCard(
                item: visible[index] as Map<String, dynamic>,
                onTap: () => _openItem(visible[index] as Map<String, dynamic>),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primary, AppTheme.secondary],
      ),
      borderRadius: BorderRadius.circular(17),
      boxShadow: AppTheme.softShadow,
    ),
    alignment: Alignment.center,
    child: Text(
      name.isEmpty ? 'D' : name[0].toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _WardrobeInsight extends StatelessWidget {
  const _WardrobeInsight({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final categories = items
        .map((item) => item['category'])
        .whereType<String>()
        .toSet()
        .length;
    return Reveal(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.black,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.mediumShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.secondaryLight,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items.isEmpty
                        ? 'Ready for your first piece?'
                        : '$categories categories in rotation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items.isEmpty
                        ? 'Photos become organized wardrobe cards.'
                        : 'Your AI stylist can mix every saved item.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${items.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  const _WardrobeCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'wardrobe-item-${item['id']}',
              child: Material(
                color: AppTheme.white,
                child: Image.network(
                  '${Constants.baseUrl}${item['image_url']}',
                  headers: AuthService.cachedHeaders,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      size: 38,
                      color: AppTheme.lightGray,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unnamed piece',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [item['category'], item['color']]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _WardrobeSkeleton extends StatefulWidget {
  const _WardrobeSkeleton();

  @override
  State<_WardrobeSkeleton> createState() => _WardrobeSkeletonState();
}

class _WardrobeSkeletonState extends State<_WardrobeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) => GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: .76,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: Color.lerp(
            AppTheme.white,
            AppTheme.borderLight,
            _controller.value * .55,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    ),
  );
}
