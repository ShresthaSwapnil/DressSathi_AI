import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/item_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_ui.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _service = FriendService();
  final _itemService = ItemService();
  final _emailController = TextEditingController();
  bool _loading = true;
  List<dynamic> _friends = [];
  List<dynamic> _requests = [];
  List<dynamic> _feedback = [];
  List<dynamic> _shares = [];
  List<dynamic> _notifications = [];
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final values = await Future.wait<dynamic>([
      _service.getFriends(),
      _service.getFriendRequests(),
      _service.getSentRequests(),
      _service.getFeedbackRequests(),
      _service.getFeedbackRequests(box: 'sent'),
      _service.getWardrobeShares(),
      _service.getWardrobeShares(box: 'granted'),
      _service.getNotifications(),
      _itemService.getItems(),
    ]);
    if (!mounted) return;
    setState(() {
      _friends = values[0] as List<dynamic>;
      _requests = [
        for (final row in values[1] as List<dynamic>)
          {...row, '_direction': 'incoming'},
        for (final row in values[2] as List<dynamic>)
          {...row, '_direction': 'sent'},
      ];
      _feedback = [
        for (final row in values[3] as List<dynamic>) {...row, '_box': 'inbox'},
        for (final row in values[4] as List<dynamic>) {...row, '_box': 'sent'},
      ];
      _shares = [
        for (final row in values[5] as List<dynamic>)
          {...row, '_box': 'received'},
        for (final row in values[6] as List<dynamic>)
          {...row, '_box': 'granted'},
      ];
      _notifications = values[7] as List<dynamic>;
      _items = values[8] as List<dynamic>? ?? [];
      _loading = false;
    });
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _sendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    HapticFeedback.mediumImpact();
    final ok = await _service.sendFriendRequest(email);
    _message(ok ? 'Friend request sent.' : 'Could not send friend request.');
    if (ok) {
      _emailController.clear();
      _load();
    }
  }

  Future<void> _searchUsers() async {
    final query = _emailController.text.trim();
    if (query.length < 2) return;
    final users = await _service.searchUsers(query);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: users.isEmpty
            ? const EmptyState(
                icon: Icons.person_search_outlined,
                title: 'No people found',
                subtitle: 'Try their full email address.',
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (_, index) => ListTile(
                  leading: _Avatar(email: users[index]['email'] ?? 'U'),
                  title: Text(
                    users[index]['display_name'] ?? users[index]['email'],
                  ),
                  subtitle: Text(users[index]['email']),
                  trailing: const Icon(Icons.add),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _emailController.text = users[index]['email'];
                    Navigator.pop(context);
                    _sendRequest();
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _requestFeedback(Map<String, dynamic> friend) async {
    if (_items.isEmpty) {
      _message('Add a wardrobe item before requesting feedback.');
      return;
    }
    var itemId = _items.first['id'] as int;
    final messageController = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request outfit feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: itemId,
                decoration: const InputDecoration(labelText: 'Wardrobe item'),
                items: _items
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(item['name'] ?? 'Item ${item['id']}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => itemId = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (send == true) {
      final ok = await _service.requestFeedback(
        recipientId: friend['friend_user_id'] as int,
        itemIds: [itemId],
        message: messageController.text,
      );
      _message(ok ? 'Feedback request sent.' : 'Could not request feedback.');
      if (ok) _load();
    }
    messageController.dispose();
  }

  Future<void> _shareWardrobe(Map<String, dynamic> friend) async {
    var shareAll = true;
    var itemId = _items.isEmpty ? null : _items.first['id'] as int;
    final share = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share wardrobe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share entire wardrobe'),
                value: shareAll,
                onChanged: (value) => setDialogState(() => shareAll = value!),
              ),
              if (!shareAll && _items.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: itemId,
                  decoration: const InputDecoration(
                    labelText: 'Share one item',
                  ),
                  items: _items
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(item['name'] ?? 'Item ${item['id']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => itemId = value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: !shareAll && itemId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
    if (share == true) {
      final ok = await _service.shareWardrobe(
        friend['friend_user_id'] as int,
        itemIds: shareAll ? [] : [itemId!],
      );
      _message(ok ? 'Wardrobe access shared.' : 'Could not share wardrobe.');
      if (ok) _load();
    }
  }

  Future<void> _respond(Map<String, dynamic> request) async {
    var rating = 4;
    final commentController = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Give feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: [1, 2, 3, 4, 5]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value / 5'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => rating = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    if (send == true) {
      final ok = await _service.respondToFeedback(
        request['id'] as int,
        rating: rating,
        comment: commentController.text,
      );
      _message(ok ? 'Feedback sent.' : 'Could not send feedback.');
      if (ok) _load();
    }
    commentController.dispose();
  }

  Future<void> _viewShare(int shareId) async {
    final items = await _service.getSharedWardrobeItems(shareId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shared wardrobe'),
        content: SizedBox(
          width: 420,
          child: items.isEmpty
              ? const Text('No items shared.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: Image.network(
                      '${Constants.baseUrl}${items[index]['image_url']}',
                      headers: AuthService.cachedHeaders,
                      width: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.checkroom),
                    ),
                    title: Text(items[index]['name'] ?? 'Wardrobe item'),
                    subtitle: Text(items[index]['category'] ?? ''),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: AppPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                eyebrow: 'Style circle',
                title: 'People who get your style.',
                subtitle:
                    'Share pieces, trade feedback, and dress better together.',
                action:
                    _notifications
                        .where((value) => value['read'] != true)
                        .isEmpty
                    ? null
                    : _CountBadge(
                        count: _notifications
                            .where((value) => value['read'] != true)
                            .length,
                      ),
              ),
              const SizedBox(height: 18),
              Reveal(child: _inviteCard()),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: AppTheme.black,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  tabs: [
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                    Tab(text: 'Feedback'),
                    Tab(text: 'Wardrobes'),
                    Tab(text: 'Alerts'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _loading
                      ? const _SocialSkeleton(key: ValueKey('loading'))
                      : TabBarView(
                          key: const ValueKey('loaded'),
                          children: [
                            _friendsList(),
                            _requestsList(),
                            _feedbackList(),
                            _sharesList(),
                            _notificationsList(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inviteCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.lavender, AppTheme.blush],
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final field = TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _searchUsers(),
          decoration: InputDecoration(
            hintText: 'Find by name or email',
            prefixIcon: const Icon(Icons.person_search_outlined),
            suffixIcon: IconButton(
              tooltip: 'Search people',
              onPressed: _searchUsers,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
        );
        final button = FilledButton.icon(
          onPressed: _sendRequest,
          icon: const Icon(Icons.near_me_outlined),
          label: const Text('Invite'),
        );
        return constraints.maxWidth >= 600
            ? Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 10),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 9), button],
              );
      },
    ),
  );

  Widget _friendsList() => _listOrEmpty(
    _friends,
    const EmptyState(
      icon: Icons.people_outline_rounded,
      title: 'Build your style circle',
      subtitle: 'Invite someone above to start swapping wardrobe ideas.',
    ),
    (friend) => _SocialRow(
      leading: _Avatar(email: friend['friend_email'] ?? 'F'),
      title: friend['friend_email'] ?? 'Friend',
      subtitle: 'Connected wardrobe friend',
      trailing: PopupMenuButton<String>(
        tooltip: 'Friend actions',
        onSelected: (action) async {
          HapticFeedback.selectionClick();
          if (action == 'feedback') await _requestFeedback(friend);
          if (action == 'share') await _shareWardrobe(friend);
          if (action == 'remove' &&
              await _service.removeFriend(friend['id'] as int)) {
            HapticFeedback.mediumImpact();
            _load();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'feedback', child: Text('Request feedback')),
          PopupMenuItem(value: 'share', child: Text('Share wardrobe')),
          PopupMenuItem(value: 'remove', child: Text('Remove friend')),
        ],
      ),
    ),
  );

  Widget _requestsList() => _listOrEmpty(
    _requests,
    const EmptyState(
      icon: Icons.mark_email_read_outlined,
      title: 'All caught up',
      subtitle: 'New invitations will appear here.',
    ),
    (request) => _SocialRow(
      leading: _Avatar(email: request['friend_email'] ?? 'F'),
      title: request['friend_email'] ?? 'Friend request',
      subtitle: request['_direction'] == 'incoming'
          ? 'Wants to join your circle'
          : 'Invitation is on its way',
      trailing: request['_direction'] == 'sent'
          ? IconButton(
              tooltip: 'Cancel request',
              onPressed: () async {
                if (await _service.cancelFriendRequest(request['id'] as int)) {
                  HapticFeedback.mediumImpact();
                  _load();
                }
              },
              icon: const Icon(Icons.cancel_outlined),
            )
          : Wrap(
              children: [
                IconButton(
                  tooltip: 'Reject',
                  onPressed: () async {
                    if (await _service.rejectFriendRequest(
                      request['id'] as int,
                    )) {
                      HapticFeedback.mediumImpact();
                      _load();
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
                IconButton.filled(
                  tooltip: 'Accept',
                  onPressed: () async {
                    if (await _service.acceptFriendRequest(
                      request['id'] as int,
                    )) {
                      HapticFeedback.heavyImpact();
                      _load();
                    }
                  },
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
    ),
  );

  Widget _feedbackList() => _listOrEmpty(
    _feedback,
    const EmptyState(
      icon: Icons.rate_review_outlined,
      title: 'No fit checks yet',
      subtitle: 'Ask a friend for an honest second opinion.',
    ),
    (request) => _SocialRow(
      leading: _IconTile(
        icon: Icons.chat_bubble_outline_rounded,
        color: AppTheme.secondary,
      ),
      title: request['_box'] == 'inbox'
          ? 'From ${request['requester_email']}'
          : 'To ${request['recipient_email']}',
      subtitle: request['message'] ?? 'Outfit feedback · ${request['status']}',
      trailing: request['_box'] == 'inbox' && request['status'] == 'pending'
          ? FilledButton(
              onPressed: () => _respond(request),
              child: const Text('Reply'),
            )
          : Text(
              request['rating'] == null
                  ? request['status']
                  : '${request['rating']}/5',
            ),
    ),
  );

  Widget _sharesList() => _listOrEmpty(
    _shares,
    const EmptyState(
      icon: Icons.checkroom_outlined,
      title: 'No shared wardrobes',
      subtitle: 'Closets shared with friends stay private and appear here.',
    ),
    (share) => _SocialRow(
      leading: const _IconTile(
        icon: Icons.checkroom_outlined,
        color: AppTheme.primary,
      ),
      title: share['_box'] == 'received'
          ? share['owner_email']
          : 'Shared with ${share['friend_email']}',
      subtitle: '${share['scope']} wardrobe access',
      trailing: share['_box'] == 'received'
          ? TextButton(
              onPressed: () => _viewShare(share['id'] as int),
              child: const Text('View'),
            )
          : IconButton(
              tooltip: 'Revoke',
              onPressed: () async {
                if (await _service.revokeWardrobeShare(share['id'] as int)) {
                  HapticFeedback.mediumImpact();
                  _load();
                }
              },
              icon: const Icon(Icons.link_off),
            ),
    ),
  );

  Widget _notificationsList() => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () async {
            if (await _service.readAllNotifications()) {
              HapticFeedback.selectionClick();
              _load();
            }
          },
          child: const Text('Mark all read'),
        ),
      ),
      Expanded(
        child: _listOrEmpty(
          _notifications,
          const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Quiet for now',
            subtitle: 'Social updates will land here.',
          ),
          (notification) => _SocialRow(
            leading: _IconTile(
              icon: notification['read']
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_outlined,
              color: notification['read']
                  ? AppTheme.midGray
                  : AppTheme.secondary,
            ),
            title: notification['title'],
            subtitle: notification['message'],
            trailing: const SizedBox(width: 8),
          ),
        ),
      ),
    ],
  );

  Widget _listOrEmpty(
    List<dynamic> values,
    Widget empty,
    Widget Function(dynamic) builder,
  ) {
    if (values.isEmpty) return Center(child: empty);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 18),
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (_, index) => Reveal(
          delay: Duration(milliseconds: 35 * index.clamp(0, 7)),
          child: builder(values[index]),
        ),
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          trailing,
        ],
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 23,
    backgroundColor: AppTheme.lavender,
    child: Text(
      email.isEmpty ? 'U' : email[0].toUpperCase(),
      style: const TextStyle(
        color: AppTheme.primary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: color, size: 21),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppTheme.blush,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.notifications_active_outlined,
          color: AppTheme.secondary,
          size: 17,
        ),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: const TextStyle(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SocialSkeleton extends StatelessWidget {
  const _SocialSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (index) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    ),
  );
}
