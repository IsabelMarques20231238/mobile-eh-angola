import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../screens/forum/forum_topic_detail_screen.dart';
import '../../screens/quiz/quiz_admin_approval_screen.dart';
import '../../screens/quiz/quiz_ai_review_screen.dart';
import '../../screens/quiz/quiz_deletion_requests_screen.dart';
import '../../screens/quiz/quiz_detail_screen.dart';
import '../../services/api_client.dart';
import '../../services/forum_service.dart';
import '../../services/notification_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

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

  bool get isTopicRef   => referenceType == 'forum_topic';
  bool get isCommentRef => referenceType == 'comment';

  // Pedido de acesso: pode chegar com diferentes tipos/referenceTypes da API.
  bool get isInviteRef =>
      referenceType == 'topic_access_request' ||
      type.toUpperCase().contains('ACCESS_REQUEST');

  // ID do pedido de acesso. Prioridade:
  //   1) referenceType == 'topic_access_request' → referenceId é o request_id
  //   2) metadata com campos access_request_id / request_id / ...
  //   3) Fallback: usa referenceId directamente (API pode enviar request_id
  //      mesmo com referenceType='forum_topic')
  int? get accessRequestId {
    if (referenceType == 'topic_access_request') return referenceId;
    final meta = metadata;
    if (meta != null) {
      for (final key in ['access_request_id', 'request_id', 'forum_access_request_id']) {
        final val = meta[key];
        if (val != null) {
          final parsed = val is int ? val : int.tryParse(val.toString());
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }
    if (referenceId != null && referenceId! > 0) return referenceId;
    return null;
  }

  // ID do tópico associado ao pedido de acesso.
  int? get accessRequestTopicId {
    final meta = metadata;
    if (meta != null) {
      for (final key in ['forum_topic_id', 'topic_id']) {
        final val = meta[key];
        if (val != null) {
          final parsed = val is int ? val : int.tryParse(val.toString());
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }
    // Quando referenceType == 'forum_topic', referenceId é o topicId
    if (referenceType == 'forum_topic' && referenceId != null && referenceId! > 0) {
      return referenceId;
    }
    return null;
  }

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
    if (isInviteRef) return Icons.person_add_alt_1_outlined;
    if (type == 'FORUM_JOIN_BY_CODE') return Icons.login_outlined;
    if (type.startsWith('FORUM_')) return Icons.forum_outlined;
    if (type.startsWith('QUIZ_')) return Icons.quiz_outlined;
    if (type == 'NEW_CONTENT') return Icons.article_outlined;
    if (type == 'FOLLOW_NEW') return Icons.person_add_outlined;
    if (type == 'ROLE_PROMOTED') return Icons.workspace_premium_outlined;
    return Icons.notifications_outlined;
  }

  Color get iconColor {
    if (isInviteRef) return AppColors.wine;
    if (type.startsWith('FORUM_')) return const Color(0xFF2563EB);
    if (type.startsWith('QUIZ_')) return AppColors.wine;
    if (type == 'NEW_CONTENT') return const Color(0xFF059669);
    if (type == 'FOLLOW_NEW') return const Color(0xFF7C3AED);
    if (type == 'ROLE_PROMOTED') return const Color(0xFFF59E0B);
    return AppColors.muted;
  }

  Color get iconBg {
    if (isInviteRef) return AppColors.wineBg;
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
  final _quizService = QuizService(ApiClient.instance);

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

    // ── Quiz notifications ─────────────────────────────────────────────────────
    if (n.type.startsWith('QUIZ_')) {
      if (n.referenceId == null) return;
      final quizId = n.referenceId!;
      if (n.type == 'QUIZ_PENDING_REVIEW') {
        _closeAndRun(() => Navigator.of(widget.outerContext).push(
          MaterialPageRoute(
            builder: (_) => QuizAdminApprovalScreen(quizId: quizId),
          ),
        ));
      } else if (n.type == 'QUIZ_APPROVED') {
        try {
          final quiz = await _quizService.getQuiz(quizId);
          if (!mounted) return;
          _closeAndRun(() => Navigator.of(widget.outerContext).push(
            MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: quiz)),
          ));
        } catch (_) {
          if (mounted) _closeAndRun(() {});
        }
      } else if (n.type == 'QUIZ_REJECTED') {
        final msg = n.message;
        final oc = widget.outerContext;
        try {
          final quiz = await _quizService.getQuiz(quizId);
          if (!mounted) return;
          final s = quiz.status.toUpperCase();
          if (s == 'APPROVED') {
            _closeAndRun(() => showAppToast(oc,
                'Este quiz já foi aprovado e publicado.',
                type: AppToastType.success));
          } else if (s == 'PENDING') {
            _closeAndRun(() => showAppToast(oc,
                'Este quiz já foi submetido e aguarda revisão.',
                type: AppToastType.info));
          } else {
            _closeAndRun(() => showModalBottomSheet(
              context: oc,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _QuizRejectedSheet(
                quizId: quizId,
                message: msg,
                outerContext: oc,
              ),
            ));
          }
        } on ApiException {
          if (!mounted) return;
          _closeAndRun(() => showAppToast(oc,
              'Este quiz já não está disponível.',
              type: AppToastType.info));
        }
      } else if (n.type == 'QUIZ_DELETION_REQUESTED') {
        _closeAndRun(() => Navigator.of(widget.outerContext).push(
          MaterialPageRoute(builder: (_) => const QuizDeletionRequestsScreen()),
        ));
      } else if (n.type == 'QUIZ_DELETION_APPROVED') {
        _closeAndRun(() => showAppToast(
          widget.outerContext,
          n.message,
          type: AppToastType.info,
        ));
      } else if (n.type == 'QUIZ_DELETION_REJECTED') {
        _closeAndRun(() => showAppToast(
          widget.outerContext,
          n.message,
          type: AppToastType.warning,
        ));
      }
      return;
    }

    // ── Pedido de acesso ───────────────────────────────────────────────────────
    if (n.isInviteRef) {
      final topicId = n.accessRequestTopicId;
      if (topicId != null) {
        _closeAndRun(() => _showInvite(widget.outerContext, topicId));
        return;
      }
    }

    // Resolver topicId e commentId preferencialmente via metadata
    final meta = n.metadata;
    int? topicId = _metaInt(meta, 'forum_topic_id');
    int? commentId = _metaInt(meta, 'comment_id');

    // Fallback: comentário sem metadata — resolver topic via API
    if (topicId == null && n.isCommentRef && n.referenceId != null && n.referenceId! > 0) {
      try {
        final ref = await ForumService.instance.getComment(n.referenceId!);
        if (!mounted) return;
        topicId = ref.topicId;
        commentId ??= n.referenceId;
      } on ApiException {
        if (mounted) showAppToast(context, 'Não foi possível abrir a notificação.', type: AppToastType.error);
        return;
      }
    }

    // Último fallback: usar referenceId directamente
    topicId ??= n.referenceId;
    if (topicId == null || topicId <= 0) return;

    final tid = topicId;
    final cid = commentId;
    _closeAndRun(() => Navigator.of(widget.outerContext).push(MaterialPageRoute(
      builder: (_) => ForumTopicDetailScreen(
        topic: ForumTopic(
          id: tid, title: '', excerpt: '', authorName: '',
          authorInitials: '?', category: TopicCategory.tudo,
          timeAgo: '', comments: 0, likes: 0,
        ),
        highlightCommentId: cid,
      ),
    )));
  }

  static int? _metaInt(Map<String, dynamic>? meta, String key) {
    if (meta == null) return null;
    final v = meta[key];
    if (v is int && v > 0) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  // Fecha o painel pelo navigator do contexto pai e executa a acção seguinte.
  void _closeAndRun(VoidCallback action) {
    if (!widget.outerContext.mounted) return;
    Navigator.of(widget.outerContext).pop();
    action();
  }

  void _showInvite(BuildContext ctx, int topicId) {
    showModalBottomSheet<_AccessRequestResult>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccessRequestDetailSheet(topicId: topicId),
    ).then((result) {
      if (!ctx.mounted || result == null) return;
      if (result.approved) {
        showAppToast(ctx, 'Pedido aprovado. O utilizador foi notificado.', type: AppToastType.success);
        if (result.topicId > 0) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => ForumTopicDetailScreen(
              topic: ForumTopic(
                id: result.topicId, title: '', excerpt: '', authorName: '',
                authorInitials: '?', category: TopicCategory.tudo, timeAgo: '', comments: 0, likes: 0,
              ),
            ),
          ));
        }
      } else {
        showAppToast(ctx, 'Pedido rejeitado. O utilizador foi notificado.', type: AppToastType.info);
      }
    });
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
  final _quizService = QuizService(ApiClient.instance);

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

    // ── Quiz notifications ─────────────────────────────────────────────────────
    if (n.type.startsWith('QUIZ_')) {
      if (n.referenceId == null) return;
      final quizId = n.referenceId!;
      if (n.type == 'QUIZ_PENDING_REVIEW') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuizAdminApprovalScreen(quizId: quizId),
        ));
      } else if (n.type == 'QUIZ_APPROVED') {
        try {
          final quiz = await _quizService.getQuiz(quizId);
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => QuizDetailScreen(quiz: quiz),
          ));
        } catch (_) {}
      } else if (n.type == 'QUIZ_REJECTED') {
        try {
          final quiz = await _quizService.getQuiz(quizId);
          if (!mounted) return;
          final s = quiz.status.toUpperCase();
          if (s == 'APPROVED') {
            showAppToast(context,
                'Este quiz já foi aprovado e publicado.',
                type: AppToastType.success);
          } else if (s == 'PENDING') {
            showAppToast(context,
                'Este quiz já foi submetido e aguarda revisão.',
                type: AppToastType.info);
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _QuizRejectedSheet(
                quizId: quizId,
                message: n.message,
                outerContext: context,
              ),
            );
          }
        } on ApiException {
          if (!mounted) return;
          showAppToast(context,
              'Este quiz já não está disponível.',
              type: AppToastType.info);
        }
      } else if (n.type == 'QUIZ_DELETION_REQUESTED') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const QuizDeletionRequestsScreen(),
        ));
      } else if (n.type == 'QUIZ_DELETION_APPROVED') {
        showAppToast(context, n.message, type: AppToastType.info);
      } else if (n.type == 'QUIZ_DELETION_REJECTED') {
        showAppToast(context, n.message, type: AppToastType.warning);
      }
      return;
    }

    // ── Pedido de acesso ───────────────────────────────────────────────────────
    if (n.isInviteRef) {
      final topicId = n.accessRequestTopicId;
      if (topicId != null) {
        _showInviteSheet(topicId);
        return;
      }
    }

    // Sem referência de navegação
    if (n.referenceId == null || n.referenceId! <= 0) return;

    // Comentário — resolver topic_id via API
    if (n.isCommentRef) {
      try {
        final ref = await ForumService.instance.getComment(n.referenceId!);
        if (!mounted) return;
        _navigateToTopic(ref.topicId, highlightCommentId: n.referenceId);
      } on ApiException catch (e) {
        if (mounted) showAppToast(context, e.message, type: AppToastType.error);
      }
      return;
    }

    // Qualquer outra notificação com referenceId → navega para o tópico
    _navigateToTopic(n.referenceId!);
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

  void _showInviteSheet(int topicId) {
    showModalBottomSheet<_AccessRequestResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccessRequestDetailSheet(topicId: topicId),
    ).then((result) {
      if (!mounted || result == null) return;
      if (result.approved) {
        showAppToast(context, 'Pedido aprovado. O utilizador foi notificado.', type: AppToastType.success);
        if (result.topicId > 0) _navigateToTopic(result.topicId);
      } else {
        showAppToast(context, 'Pedido rejeitado. O utilizador foi notificado.', type: AppToastType.info);
      }
    });
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

// ── Access request result ─────────────────────────────────────────────────────

class _AccessRequestResult {
  final bool approved;
  final int topicId;
  const _AccessRequestResult({required this.approved, required this.topicId});
}

// ── Access Request Detail Sheet ───────────────────────────────────────────────

class _AccessRequestDetailSheet extends StatefulWidget {
  final int topicId;

  const _AccessRequestDetailSheet({required this.topicId});

  @override
  State<_AccessRequestDetailSheet> createState() => _AccessRequestDetailSheetState();
}

class _AccessRequestDetailSheetState extends State<_AccessRequestDetailSheet> {
  List<AccessRequestDetail> _requests = [];
  bool _loading = true;
  String? _loadError;
  final Set<int> _actioning = {};
  bool _anyApproved = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final list = await ForumService.instance.getAccessRequests(widget.topicId);
      if (mounted) setState(() { _requests = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loadError = e.message; _loading = false; });
    }
  }

  Future<void> _approve(AccessRequestDetail req) async {
    setState(() => _actioning.add(req.id));
    try {
      await ForumService.instance.approveAccessRequest(widget.topicId, req.id);
      if (!mounted) return;
      showAppToast(context, '${req.requesterName} aprovado(a).', type: AppToastType.success);
      setState(() {
        _actioning.remove(req.id);
        _requests = _requests.where((r) => r.id != req.id).toList();
        _anyApproved = true;
      });
      if (_requests.isEmpty) {
        Navigator.pop(context, _AccessRequestResult(approved: true, topicId: widget.topicId));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actioning.remove(req.id));
        showAppToast(context, e.message, type: AppToastType.error);
      }
    }
  }

  Future<void> _reject(AccessRequestDetail req) async {
    setState(() => _actioning.add(req.id));
    try {
      await ForumService.instance.rejectAccessRequest(widget.topicId, req.id);
      if (!mounted) return;
      showAppToast(context, 'Pedido rejeitado.', type: AppToastType.info);
      setState(() {
        _actioning.remove(req.id);
        _requests = _requests.where((r) => r.id != req.id).toList();
      });
      if (_requests.isEmpty) {
        Navigator.pop(context, _anyApproved
            ? _AccessRequestResult(approved: true, topicId: widget.topicId)
            : _AccessRequestResult(approved: false, topicId: 0));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actioning.remove(req.id));
        showAppToast(context, e.message, type: AppToastType.error);
      }
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.toLocal();
    final day = dd.day.toString().padLeft(2, '0');
    final month = dd.month.toString().padLeft(2, '0');
    final hh = dd.hour.toString().padLeft(2, '0');
    final min = dd.minute.toString().padLeft(2, '0');
    return '$day/$month/${dd.year} às $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          // Header
          Row(
            children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.winePill, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.person_add_alt_1_outlined, color: c.wine, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Pedidos de acesso',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c.textMain),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: c.wine, strokeWidth: 2),
              ),
            )
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: c.muted, size: 32),
                    const SizedBox(height: 8),
                    Text(_loadError!, style: TextStyle(color: c.muted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Não há pedidos pendentes.',
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _requests.length,
                separatorBuilder: (_, _) => Divider(color: c.border, height: 24),
                itemBuilder: (_, i) {
                  final req = _requests[i];
                  final isActioning = _actioning.contains(req.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Solicitante
                      Row(
                        children: [
                          AppAvatar(
                            initials: req.requesterInitials,
                            size: 44,
                            bg: req.avatarBg,
                            fg: req.avatarFg,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.requesterName,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textMain),
                                ),
                                if (req.requesterRole.isNotEmpty)
                                  Text(req.requesterRole, style: TextStyle(fontSize: 12, color: c.muted)),
                              ],
                            ),
                          ),
                          if (req.requestedAt != null)
                            Text(
                              _formatDate(req.requestedAt!),
                              style: TextStyle(fontSize: 10, color: c.muted),
                            ),
                        ],
                      ),
                      // Motivação
                      if (req.message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            req.message,
                            style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Botões
                      if (isActioning)
                        Center(child: CircularProgressIndicator(color: c.wine, strokeWidth: 2))
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _reject(req),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: c.textMain,
                                  side: BorderSide(color: c.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Rejeitar', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approve(req),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.wine,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Aprovar', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quiz rejection sheet ──────────────────────────────────────────────────────

class _QuizRejectedSheet extends StatefulWidget {
  final int quizId;
  final String message;
  final BuildContext outerContext;

  const _QuizRejectedSheet({
    required this.quizId,
    required this.message,
    required this.outerContext,
  });

  @override
  State<_QuizRejectedSheet> createState() => _QuizRejectedSheetState();
}

class _QuizRejectedSheetState extends State<_QuizRejectedSheet> {
  final _service = QuizService(ApiClient.instance);
  bool _loading = false;

  Future<void> _editQuiz() async {
    setState(() => _loading = true);
    try {
      final quiz = await _service.getQuiz(widget.quizId);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.outerContext.mounted) {
        Navigator.of(widget.outerContext).push(MaterialPageRoute(
          builder: (_) =>
              QuizAIReviewScreen(quiz: quiz, isAiGenerated: quiz.isAiGenerated),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppToast(context, e.message, type: AppToastType.error);
      }
    }
  }

  Future<void> _deleteQuiz() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar quiz?'),
        content: const Text('Esta acção é permanente e não pode ser revertida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await _service.deleteQuiz(widget.quizId);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.outerContext.mounted) {
        showAppToast(widget.outerContext, 'Quiz apagado com sucesso.',
            type: AppToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppToast(context, e.message, type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Rejeitado',
                      style: TextStyle(
                          color: c.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'O teu quiz não foi aprovado.',
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                    color: c.textSecondary, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.wine))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editQuiz,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar Quiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.wine,
                        side: const BorderSide(color: AppColors.wine),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteQuiz,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Apagar Quiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
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

