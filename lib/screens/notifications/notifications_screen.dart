import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../screens/forum/forum_topic_detail_screen.dart';
import '../../services/api_client.dart';
import '../../services/forum_service.dart';
import '../../services/notification_state.dart';
import '../../theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String type;
  final String message;
  final bool isRead;
  final int? referenceId;
  final String? referenceType;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.referenceId,
    this.referenceType,
    this.metadata,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      referenceId: json['reference_id'] is int
          ? json['reference_id']
          : int.tryParse(json['reference_id']?.toString() ?? ''),
      referenceType: json['reference_type']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        message: message,
        isRead: isRead ?? this.isRead,
        referenceId: referenceId,
        referenceType: referenceType,
        metadata: metadata,
        createdAt: createdAt,
      );

  // ── Navigation helpers ──────────────────────────────────────────────────────

  // reference_type routing (from API docs):
  //   'forum_topic'          → referenceId = topic_id  (navigate directly)
  //   'comment'              → referenceId = comment_id (resolve topic via GET /forum/comments/{id})
  //   'topic_access_request' → referenceId = access_request_id (show invite modal)

  bool get isTopicRef    => referenceType == 'forum_topic';
  bool get isCommentRef  => referenceType == 'comment';
  bool get isInviteRef   => referenceType == 'topic_access_request';

  bool get isForumType => type.startsWith('FORUM_');

  // ── Display helpers ─────────────────────────────────────────────────────────

  String get formattedDate {
    if (createdAt == null) return '';
    final d = createdAt!.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$min';
  }

  String get dayLabel {
    if (createdAt == null) return 'RECENTE';
    final d = createdAt!.toLocal();
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'HOJE';
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
      return 'ONTEM';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  IconData get icon {
    if (type == 'FORUM_JOIN_BY_CODE') return Icons.login_outlined;
    if (type.startsWith('FORUM_')) return Icons.forum_outlined;
    if (type.startsWith('QUIZ_')) return Icons.quiz_outlined;
    if (type == 'NEW_CONTENT') return Icons.article_outlined;
    if (type == 'FOLLOW_NEW') return Icons.person_add_outlined;
    if (type == 'ROLE_PROMOTED') return Icons.workspace_premium_outlined;
    return Icons.notifications_outlined;
  }

  Color get iconColor {
    if (type.startsWith('FORUM_')) return const Color(0xFF2563EB);
    if (type.startsWith('QUIZ_')) return AppColors.wine;
    if (type == 'NEW_CONTENT') return const Color(0xFF059669);
    if (type == 'FOLLOW_NEW') return const Color(0xFF7C3AED);
    if (type == 'ROLE_PROMOTED') return const Color(0xFFF59E0B);
    return AppColors.muted;
  }

  Color get iconBg {
    if (type.startsWith('FORUM_')) return const Color(0xFFEFF6FF);
    if (type.startsWith('QUIZ_')) return AppColors.wineBg;
    if (type == 'NEW_CONTENT') return const Color(0xFFECFDF5);
    if (type == 'FOLLOW_NEW') return const Color(0xFFF5F3FF);
    if (type == 'ROLE_PROMOTED') return const Color(0xFFFFFBEB);
    return const Color(0xFFF1F5F9);
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Opens the notifications panel as a bottom sheet from [context].
Future<void> showNotificationsPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationsPanel(outerContext: context),
  );
}

// ── Panel (bottom sheet) ──────────────────────────────────────────────────────

class _NotificationsPanel extends StatefulWidget {
  final BuildContext outerContext;
  const _NotificationsPanel({required this.outerContext});

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  int _tab = 0;
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<String> get _tabLabels => [
        'Todas',
        _unreadCount > 0 ? 'Não lidas ($_unreadCount)' : 'Não lidas',
        'Quiz',
        'Fórum',
        'Conteúdo',
      ];

  List<AppNotification> get _filtered {
    switch (_tab) {
      case 1:
        return _notifications.where((n) => !n.isRead).toList();
      case 2:
        return _notifications.where((n) => n.type.startsWith('QUIZ_')).toList();
      case 3:
        return _notifications.where((n) => n.type.startsWith('FORUM_')).toList();
      case 4:
        return _notifications.where((n) => n.type == 'NEW_CONTENT').toList();
      default:
        return _notifications;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/notifications', authenticated: true);
      final list = data is Map ? data['data'] : data;
      if (list is List) {
        final parsed = list
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
        if (mounted) setState(() => _notifications = parsed);
        NotificationState.instance.setUnreadCount(
          parsed.where((n) => !n.isRead).length,
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    final wasUnread = _notifications.any((n) => n.id == id && !n.isRead);
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
    });
    if (wasUnread) NotificationState.instance.decrement();
    ApiClient.instance
        .put('/notifications/$id/read', body: {}, authenticated: true)
        .catchError((_) {});
  }

  Future<void> _markAllRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    NotificationState.instance.setUnreadCount(0);
    ApiClient.instance
        .put('/notifications/read-all', body: {}, authenticated: true)
        .catchError((_) {});
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.isRead) _markRead(n.id);
    if (!n.isForumType) return;

    // Convite — referenceId é o access_request_id, não o topic_id
    if (n.isInviteRef && n.referenceId != null) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.outerContext.mounted) _showInvite(widget.outerContext, n);
      });
      return;
    }

    // Notificação de comentário — referenceId é comment_id; resolver topic_id via API
    if (n.isCommentRef && n.referenceId != null) {
      try {
        final ref = await ForumService.instance.getComment(n.referenceId!);
        if (!mounted) return;
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.outerContext.mounted) return;
          Navigator.of(widget.outerContext).push(MaterialPageRoute(
            builder: (_) => ForumTopicDetailScreen(
              topic: ForumTopic(
                id: ref.topicId, title: '', excerpt: '',
                authorName: '', authorInitials: '?',
                category: TopicCategory.tudo, timeAgo: '', comments: 0, likes: 0,
              ),
              highlightCommentId: n.referenceId,
            ),
          ));
        });
      } on ApiException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir a notificação.')),
          );
        }
      }
      return;
    }

    // Referência directa ao tópico (forum_topic)
    final topicId = n.referenceId;
    if (topicId == null || topicId <= 0) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.outerContext.mounted) return;
      Navigator.of(widget.outerContext).push(MaterialPageRoute(
        builder: (_) => ForumTopicDetailScreen(
          topic: ForumTopic(
            id: topicId, title: '', excerpt: '', authorName: '',
            authorInitials: '?', category: TopicCategory.tudo,
            timeAgo: '', comments: 0, likes: 0,
          ),
        ),
      ));
    });
  }

  void _showInvite(BuildContext ctx, AppNotification n) {
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _InviteBottomSheet(
        message: n.message,
        onAccept: () async {
          Navigator.pop(sheetCtx);
          try {
            final topicId = await ForumService.instance.acceptInvite(n.referenceId!);
            if (ctx.mounted) {
              Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => ForumTopicDetailScreen(
                  topic: ForumTopic(
                    id: topicId,
                    title: '',
                    excerpt: '',
                    authorName: '',
                    authorInitials: '?',
                    category: TopicCategory.tudo,
                    timeAgo: '',
                    comments: 0,
                    likes: 0,
                  ),
                ),
              ));
            }
          } on ApiException catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
        onReject: () async {
          Navigator.pop(sheetCtx);
          try {
            await ForumService.instance.rejectInvite(n.referenceId!);
          } on ApiException {
            // falha silenciosa
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.88,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: c.textMain,
                  ),
                ),
                const Spacer(),
                if (_unreadCount > 0)
                  IconButton(
                    icon: Icon(Icons.done_all, color: c.wine, size: 20),
                    onPressed: _markAllRead,
                    tooltip: 'Marcar todas como lidas',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.wine,
                          ),
                        )
                      : Icon(Icons.refresh, color: c.textSecondary, size: 20),
                  onPressed: _loading ? null : _load,
                  tooltip: 'Actualizar',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tabs
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _tabLabels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = i == _tab;
                return GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? c.winePill : c.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _tabLabels[i],
                      style: TextStyle(
                        color: active ? c.wine : c.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: c.border, height: 1),
          // Content — RefreshIndicator always present so pull-to-refresh works
          Expanded(
            child: _error != null && _notifications.isEmpty
                ? _PanelError(error: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.wine,
                    onRefresh: _load,
                    child: _loading && _notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: CircularProgressIndicator(color: AppColors.wine),
                              ),
                            ],
                          )
                        : _PanelList(
                            notifications: _filtered,
                            onTap: _onTap,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Panel list ────────────────────────────────────────────────────────────────

class _PanelList extends StatelessWidget {
  final List<AppNotification> notifications;
  final void Function(AppNotification) onTap;

  const _PanelList({required this.notifications, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'Sem notificações',
              style: TextStyle(color: c.muted, fontSize: 14),
            ),
          ),
        ],
      );
    }

    final items = <Widget>[];
    String? lastDay;

    for (final n in notifications) {
      final day = n.dayLabel;
      if (day != lastDay) {
        if (items.isNotEmpty) {
          items.add(Divider(color: c.border, height: 1));
        }
        items.add(_DayHeader(label: day));
        lastDay = day;
      }
      items.add(_PanelTile(notification: n, onTap: () => onTap(n)));
    }
    items.add(const SizedBox(height: 32));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: items,
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: context.c.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PanelTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _PanelTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    return InkWell(
      onTap: onTap,
      child: Builder(builder: (context) {
        final c = context.c;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: unread
                ? Border(left: BorderSide(color: c.wine, width: 3))
                : null,
            color: unread ? c.wineBg : c.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: n.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(n.icon, color: n.iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textMain,
                        fontSize: 12,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (n.formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        n.formattedDate,
                        style: TextStyle(color: c.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PanelError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _PanelError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, style: TextStyle(color: context.c.muted, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

// ── Legacy full-screen (kept for compatibility) ───────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0;
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  static const _filters = ['Tudo', 'Fórum', 'Quiz', 'Conteúdo', 'Outros'];

  List<AppNotification> get _filtered {
    if (_selectedFilter == 0) return _notifications;
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case 1:
          return n.type.startsWith('FORUM_');
        case 2:
          return n.type.startsWith('QUIZ_');
        case 3:
          return n.type == 'NEW_CONTENT';
        default:
          return !n.type.startsWith('FORUM_') &&
              !n.type.startsWith('QUIZ_') &&
              n.type != 'NEW_CONTENT';
      }
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/notifications', authenticated: true);
      final list = data is Map ? data['data'] : data;
      if (list is List) {
        final parsed = list
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
        if (mounted) setState(() => _notifications = parsed);
        NotificationState.instance.setUnreadCount(
          parsed.where((n) => !n.isRead).length,
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    final wasUnread = _notifications.any((n) => n.id == id && !n.isRead);
    setState(() {
      _notifications =
          _notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    });
    if (wasUnread) NotificationState.instance.decrement();
    ApiClient.instance
        .put('/notifications/$id/read', body: {}, authenticated: true)
        .catchError((_) {});
  }

  Future<void> _markAllRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    NotificationState.instance.setUnreadCount(0);
    ApiClient.instance
        .put('/notifications/read-all', body: {}, authenticated: true)
        .catchError((_) {});
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.isRead) _markRead(n.id);
    if (!n.isForumType) return;

    // Convite — referenceId é o access_request_id
    if (n.isInviteRef && n.referenceId != null) {
      _showInviteSheet(n);
      return;
    }

    // Comentário — referenceId é comment_id; resolver topic_id via API
    if (n.isCommentRef && n.referenceId != null) {
      try {
        final ref = await ForumService.instance.getComment(n.referenceId!);
        if (!mounted) return;
        _navigateToTopic(ref.topicId, highlightCommentId: n.referenceId);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return;
    }

    // Referência directa ao tópico (forum_topic)
    final topicId = n.referenceId;
    if (topicId == null || topicId <= 0) return;
    _navigateToTopic(topicId);
  }

  void _navigateToTopic(int topicId, {int? highlightCommentId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForumTopicDetailScreen(
          topic: ForumTopic(
            id: topicId,
            title: '',
            excerpt: '',
            authorName: '',
            authorInitials: '?',
            category: TopicCategory.tudo,
            timeAgo: '',
            comments: 0,
            likes: 0,
          ),
          highlightCommentId: highlightCommentId,
        ),
      ),
    );
  }

  void _showInviteSheet(AppNotification n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _InviteBottomSheet(
        message: n.message,
        onAccept: () async {
          Navigator.pop(sheetCtx);
          try {
            final topicId = await ForumService.instance.acceptInvite(n.referenceId!);
            if (mounted) _navigateToTopic(topicId);
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          }
        },
        onReject: () async {
          Navigator.pop(sheetCtx);
          try {
            await ForumService.instance.rejectInvite(n.referenceId!);
          } on ApiException {
            // falha silenciosa
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        toolbarHeight: 56,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: c.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _unreadCount > 0 ? 'Notificações ($_unreadCount)' : 'Notificações',
          style: TextStyle(
            color: c.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.wine, size: 19),
              onPressed: _markAllRead,
              tooltip: 'Marcar todas como lidas',
            ),
          const SizedBox(width: 8),
        ],
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final active = index == _selectedFilter;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedFilter = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.winePill : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: active ? AppColors.wine : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.wine))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13)),
                            const SizedBox(height: 12),
                            TextButton(
                                onPressed: _load,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Sem notificações',
                              style: TextStyle(color: AppColors.muted, fontSize: 14),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.wine,
                            onRefresh: _load,
                            child: _PanelList(
                              notifications: _filtered,
                              onTap: _onTap,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Invite Bottom Sheet ───────────────────────────────────────────────────────

class _InviteBottomSheet extends StatefulWidget {
  final String message;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _InviteBottomSheet({
    required this.message,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<_InviteBottomSheet> {
  bool _loading = false;

  Future<void> _handle(Future<void> Function() action) async {
    setState(() => _loading = true);
    await action();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.lock_open_outlined, color: AppColors.wine, size: 26),
            ),
            const SizedBox(height: 14),
            const Text(
              'Convite para tópico privado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: CircularProgressIndicator(color: AppColors.wine),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handle(widget.onReject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Recusar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handle(widget.onAccept),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Aceitar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
