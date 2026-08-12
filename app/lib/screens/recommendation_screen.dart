import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/recommendation_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key, this.service});
  final RecommendationService? service;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late final RecommendationService _service =
      widget.service ?? RecommendationService();
  final _friends = FriendService();
  final _weather = TextEditingController(text: 'mild and clear');
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _occasions = const [
    ('casual', Icons.weekend_outlined),
    ('work', Icons.work_outline_rounded),
    ('formal', Icons.business_center_outlined),
    ('party', Icons.celebration_outlined),
    ('date', Icons.favorite_border_rounded),
    ('sporty', Icons.directions_run_rounded),
  ];
  String _occasion = 'casual';
  bool _liveWeather = true;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _weather.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final values = await _service.getSavedOutfits();
    if (mounted) setState(() => _history = values ?? []);
  }

  Future<void> _generate() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final result = await _service.getOutfitRecommendation(
      occasion: _occasion,
      weather: _weather.text.trim(),
      useLiveWeather: _liveWeather,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
      _error = result == null
          ? 'Your stylist could not complete that look. Add a few wardrobe pieces or try again.'
          : null;
    });
    result == null ? HapticFeedback.vibrate() : HapticFeedback.heavyImpact();
  }

  Future<void> _save() async {
    if (_result == null) return;
    HapticFeedback.mediumImpact();
    final saved = await _service.saveOutfit(_result!);
    if (!mounted) return;
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this outfit.')),
      );
      return;
    }
    await _loadHistory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessCheck(),
            const SizedBox(height: 15),
            Text('Outfit saved', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            const Text(
              'It’s waiting in your lookbook.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    HapticFeedback.mediumImpact();
    if (await _service.deleteOutfit(id)) _loadHistory();
  }

  Future<void> _share(int outfitId) async {
    final values = await _friends.getFriends();
    if (!mounted) return;
    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a friend before sharing a look.')),
      );
      return;
    }
    final friendId = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share with', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final friend in values)
              ListTile(
                leading: CircleAvatar(
                  child: Text('${friend['friend_email']}'[0].toUpperCase()),
                ),
                title: Text(friend['friend_email'] ?? 'Friend'),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () =>
                    Navigator.pop(context, friend['friend_user_id'] as int),
              ),
          ],
        ),
      ),
    );
    if (friendId == null) return;
    HapticFeedback.mediumImpact();
    final ok = await _friends.shareOutfit(outfitId, friendId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Look shared privately.' : 'Could not share this look.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPage(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            eyebrow: 'Personal AI stylist',
            title: 'What are we dressing for?',
            subtitle: 'A thoughtful look, made only from pieces you own.',
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(99),
              ),
              labelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Create a look'),
                Tab(text: 'Saved  ${_history.length}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_createView, _savedView],
            ),
          ),
        ],
      ),
    ),
  );

  Widget get _createView => ListView(
    padding: EdgeInsets.zero,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final controls = _StylistControls(
            occasions: _occasions,
            selected: _occasion,
            liveWeather: _liveWeather,
            weather: _weather,
            onOccasion: (value) {
              HapticFeedback.selectionClick();
              setState(() => _occasion = value);
            },
            onLiveWeather: (value) {
              HapticFeedback.selectionClick();
              setState(() => _liveWeather = value);
            },
            onGenerate: _generate,
            loading: _loading,
          );
          final output = AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            child: _loading
                ? const _ThinkingCard(key: ValueKey('thinking'))
                : _result != null
                ? _ResultCard(
                    key: const ValueKey('result'),
                    result: _result!,
                    onSave: _save,
                  )
                : _error != null
                ? _ErrorCard(
                    key: const ValueKey('error'),
                    message: _error!,
                    onRetry: _generate,
                  )
                : const _StylistIntro(key: ValueKey('intro')),
          );
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: controls),
                    const SizedBox(width: 18),
                    Expanded(flex: 11, child: output),
                  ],
                )
              : Column(
                  children: [controls, const SizedBox(height: 16), output],
                );
        },
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget get _savedView => _history.isEmpty
      ? const EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'Your lookbook is empty',
          subtitle: 'Save a recommendation and it will live here.',
        )
      : RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final outfit = _history[index] as Map<String, dynamic>;
              return Reveal(
                delay: Duration(milliseconds: 35 * index.clamp(0, 7)),
                child: _SavedLook(
                  outfit: outfit,
                  onShare: () => _share(outfit['id'] as int),
                  onDelete: () => _delete(outfit['id'] as int),
                ),
              );
            },
          ),
        );
}

class _StylistControls extends StatelessWidget {
  const _StylistControls({
    required this.occasions,
    required this.selected,
    required this.liveWeather,
    required this.weather,
    required this.onOccasion,
    required this.onLiveWeather,
    required this.onGenerate,
    required this.loading,
  });
  final List<(String, IconData)> occasions;
  final String selected;
  final bool liveWeather;
  final TextEditingController weather;
  final ValueChanged<String> onOccasion;
  final ValueChanged<bool> onLiveWeather;
  final VoidCallback onGenerate;
  final bool loading;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a mood', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: occasions.map((value) {
              final active = value.$1 == selected;
              return ChoiceChip(
                avatar: Icon(
                  value.$2,
                  size: 17,
                  color: active ? Colors.white : AppTheme.midGray,
                ),
                label: Text(value.$1[0].toUpperCase() + value.$1.substring(1)),
                selected: active,
                labelStyle: TextStyle(
                  color: active ? Colors.white : AppTheme.black,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => onOccasion(value.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Semantics(
            button: true,
            toggled: liveWeather,
            label: 'Use live weather',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: () => onLiveWeather(!liveWeather),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppTheme.lavender,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_outlined, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use live weather',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'From your saved location',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: liveWeather, onChanged: onLiveWeather),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: liveWeather
                ? const SizedBox(height: 14)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: weather,
                      decoration: const InputDecoration(
                        labelText: 'Describe the weather',
                        prefixIcon: Icon(Icons.thermostat_outlined),
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate outfit'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard({super.key});
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: LottieStatus(
        asset: 'assets/animations/ai_thinking.json',
        title: 'Styling your wardrobe',
        subtitle: 'Balancing occasion, weather, color, and comfort…',
        size: 150,
      ),
    ),
  );
}

class _StylistIntro extends StatelessWidget {
  const _StylistIntro({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.black, AppTheme.charcoal],
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      boxShadow: AppTheme.mediumShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.auto_awesome, color: AppTheme.secondaryLight),
        ),
        const SizedBox(height: 40),
        Text(
          'Made from your wardrobe.\nMade for this moment.',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your stylist never invents pieces you do not own.',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'The stylist needs another moment',
        subtitle: message,
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result, required this.onSave});
  final Map<String, dynamic> result;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final items = result['items'] as List<dynamic>? ?? [];
    final explanation = result['explanation'] as List<dynamic>? ?? [];
    return Reveal(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SuccessCheck(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['title'] ?? 'Your look',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          result['weather_summary'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lavender,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${result['model_used'] ?? 'AI'}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isNotEmpty)
                SizedBox(
                  height: 174,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, index) => _ResultItem(
                      item: items[index] as Map<String, dynamic>,
                      index: index,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              for (final line in explanation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('• $line')),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to lookbook'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({required this.item, required this.index});
  final Map<String, dynamic> item;
  final int index;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Hero(
            tag: 'recommendation-${item['clothing_item_id']}-$index',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                '${Constants.baseUrl}${item['image_url']}',
                headers: AuthService.cachedHeaders,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppTheme.offWhite,
                  child: Center(child: Icon(Icons.checkroom_outlined)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          item['name'] ?? item['category'] ?? 'Piece',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        Text(
          item['reason'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    ),
  );
}

class _SavedLook extends StatelessWidget {
  const _SavedLook({
    required this.outfit,
    required this.onShare,
    required this.onDelete,
  });
  final Map<String, dynamic> outfit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final items = outfit['items'] as List<dynamic>? ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: items.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        '${Constants.baseUrl}${items.first['item']['image_url']}',
                        headers: AuthService.cachedHeaders,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit['title'] ?? 'Saved look',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${outfit['occasion'] ?? 'Everyday'} · ${items.length} pieces',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (outfit['weather'] != null)
                    Text(
                      outfit['weather'],
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
            IconButton(
              tooltip: 'Share look',
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              tooltip: 'Delete look',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
