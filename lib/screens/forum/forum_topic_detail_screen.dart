import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/forum_service.dart';
import '../../services/realtime_event.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import 'criar_topico_screen.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final ForumTopic topic;
  final int? highlightCommentId;

  const ForumTopicDetailScreen({super.key, required this.topic, this.highlightCommentId});

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  final _searchController = TextEditingController();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  final _scrollController = ScrollController();
  List<ForumComment> _comments = [];
  late ForumTopic _topic;
  late bool _saved;
  String? _topicBody;
  List<String> _topicTags = [];
  bool _isLoadingComments = false;
  bool _isLoadingTopic = false;
  String? _commentsError;
  String? _topicError;
  bool _showSearch = false;
  int? _replyParentId;
  String? _replyToName;
  // Highlight & scroll
  final Map<int, GlobalKey> _commentKeys = {};
  int? _scrollTargetId;      // ID do comentário de topo para onde rolar
  int? _autoExpandParentId;  // ID do comentário de topo cujas replies se expandem auto
  int? _activeHighlightId;   // ID do comentário/reply a destacar
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
    _saved = widget.topic.isSaved;
    if (widget.topic.id > 0) {
      _loadTopicDetail();
      _subscribeToRealtime();
    }
  }

  Future<void> _loadTopicDetail() async {
    final needsTopicLoad = _topic.title.isEmpty;
    setState(() {
      _isLoadingComments = true;
      _isLoadingTopic = needsTopicLoad;
      _commentsError = null;
      _topicError = null;
    });
    try {
      final detail = await ForumService.instance.getTopicDetail(_topic.id);
      if (!mounted) return;
      setState(() {
        if (detail.topic != null) _topic = detail.topic!;
        _topicBody = detail.body.isNotEmpty ? detail.body : null;
        _saved = detail.isSaved;
        _comments = detail.comments;
        _topicTags = detail.tags;
        _isLoadingComments = false;
        _isLoadingTopic = false;
      });
      _resolveHighlight();
      _scheduleScrollToHighlight();
    } on ApiException catch (e) {
      if (!mounted) return;
      final friendlyMsg = (e.statusCode == 404 || e.statusCode == 403)
          ? 'Tópico não encontrado ou sem acesso.'
          : e.message.contains('No query results')
              ? 'Tópico não encontrado.'
              : e.message;
      setState(() {
        if (needsTopicLoad) _topicError = friendlyMsg;
        _commentsError = needsTopicLoad ? null : friendlyMsg;
        _isLoadingComments = false;
        _isLoadingTopic = false;
      });
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    if (widget.topic.id > 0) {
      WebSocketService.instance.unsubscribeFromTopic(_topic.id);
    }
    _searchController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Tempo real ───────────────────────────────────────────────────────────

  void _subscribeToRealtime() {
    WebSocketService.instance.subscribeToTopic(_topic.id);
    _realtimeSub = WebSocketService.instance.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;
    switch (event) {
      case CommentCreatedEvent(:final topicId, :final comment):
        if (topicId != _topic.id) return;
        setState(() {
          if (comment.parentId == null) {
            _comments = [..._comments, comment];
          } else {
            _comments = _insertReply(_comments, comment);
          }
        });

      case CommentLikeUpdatedEvent(:final commentId, :final likesCount):
        setState(() {
          _comments = _updateCommentLike(_comments, commentId, likesCount);
        });

      case TopicLikeUpdatedEvent(:final topicId, :final likesCount, :final isLiked):
        if (topicId != _topic.id) return;
        setState(() => _topic = _topic.copyWith(likes: likesCount, isLiked: isLiked));

      case TopicUpdatedEvent(:final topicId, :final isReadOnly, :final title, :final commentsCount):
        if (topicId != _topic.id) return;
        setState(() => _topic = _topic.copyWith(
              isReadOnly: isReadOnly,
              title: title,
              comments: commentsCount,
            ));
    }
  }

  /// Insere uma reply no comentário pai correcto (só um nível de profundidade).
  List<ForumComment> _insertReply(List<ForumComment> list, ForumComment reply) {
    return list.map((c) {
      if (c.numericId == reply.parentId) {
        return c.copyWith(replies: [...c.replies, reply]);
      }
      return c;
    }).toList();
  }

  /// Actualiza cirurgicamente o contador de likes num comentário ou numa reply.
  List<ForumComment> _updateCommentLike(
    List<ForumComment> list,
    int commentId,
    int likesCount,
  ) {
    return list.map((c) {
      if (c.numericId == commentId) return c.copyWith(likes: likesCount);
      if (c.replies.isNotEmpty) {
        return c.copyWith(
          replies: _updateCommentLike(c.replies, commentId, likesCount),
        );
      }
      return c;
    }).toList();
  }

  int get _commentCount =>
      _comments.fold(0, (sum, comment) => sum + 1 + comment.replies.length);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return EhAngolaScaffold(
      bottomNavIndex: 1,
      searchController: _searchController,
      showSearch: _showSearch,
      onSearchChanged: (_) => setState(() {}),
      onSearchTap: () => setState(() => _showSearch = !_showSearch),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Cabeçalho + corpo do tópico + cabeçalho dos comentários ──────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 22,
              compact ? 24 : 36,
              compact ? 14 : 22,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _BackToForumHeader(),
                const SizedBox(height: 28),
                if (_isLoadingTopic)
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE6ECF3)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.wine),
                    ),
                  )
                else if (_topicError != null)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE6ECF3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.wine, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          _topicError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadTopicDetail,
                          child: const Text('Tentar novamente',
                              style: TextStyle(color: AppColors.wine)),
                        ),
                      ],
                    ),
                  )
                else
                  _TopicBodyCard(
                    topic: _topic,
                    fullBody: _topicBody,
                    tags: _topicTags,
                    saved: _saved,
                    onSave: _toggleSave,
                    onEdit: _topic.permissions.canEdit ? _openEdit : null,
                    onDelete:
                        _topic.permissions.canDelete ? _deleteTopic : null,
                  ),
                const SizedBox(height: 32),
                _RepliesHeader(count: _commentCount),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── Lista de comentários (lazy) ───────────────────────────────────
          if (_isLoadingComments)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22),
              sliver: const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.wine)),
                ),
              ),
            )
          else if (_commentsError != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _commentsError!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22),
              sliver: SliverList.builder(
                itemCount: _comments.length,
                itemBuilder: (context, i) {
                  final comment = _comments[i];
                  final commentKey = _commentKeys.putIfAbsent(
                      comment.numericId, () => GlobalKey());
                  final isHighlighted = _activeHighlightId == comment.numericId;
                  final isParent = _autoExpandParentId == comment.numericId;
                  return Column(
                    key: commentKey,
                    children: [
                      if (i > 0)
                        const Divider(color: Color(0xFFE8EDF3), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: _CommentCard(
                          comment: comment,
                          onReply: _startReply,
                          onDelete: _deleteComment,
                          isHighlighted: isHighlighted,
                          highlightedReplyId:
                              isParent ? _activeHighlightId : null,
                          autoExpandReplies: isParent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
          ),
          if (_topic.isReadOnly)
            const _ReadOnlyBanner()
          else
            _InstagramComposerBar(
              controller: _replyController,
              focusNode: _replyFocusNode,
              onSend: _sendComment,
              replyToName: _replyToName,
              onCancelReply: _cancelReply,
            ),
        ],
      ),
    );
  }

  Future<void> _toggleSave() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() => _saved = !_saved);
    if (_topic.id <= 0) return;
    try {
      final bookmarked = await ForumService.instance.bookmarkTopic(_topic.id);
      if (mounted) setState(() => _saved = bookmarked);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saved = !_saved);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openEdit() async {
    final refreshed = await Navigator.push<bool>(
      context,
      AppRoutes.bottomSlideRoute(
        builder: (_) => CriarTopicoScreen(
          editTopic: _topic,
          editBody: _topicBody,
          editTags: _topicTags,
        ),
      ),
    );
    if (refreshed == true && mounted) _loadTopicDetail();
  }

  Future<void> _deleteTopic() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar tópico'),
        content: const Text(
          'Tens a certeza que queres apagar este tópico? Esta acção é irreversível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ForumService.instance.deleteTopic(_topic.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _startReply(ForumComment comment) {
    setState(() {
      _replyParentId = comment.numericId > 0 ? comment.numericId : null;
      _replyToName = comment.authorName;
    });
    _replyController.text = '@${comment.authorName} ';
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _replyController.text.length),
    );
    _replyFocusNode.requestFocus();
  }

  void _cancelReply() {
    final prefix = _replyToName != null ? '@$_replyToName ' : null;
    setState(() { _replyParentId = null; _replyToName = null; });
    if (prefix != null && _replyController.text.startsWith(prefix)) {
      _replyController.text = _replyController.text.substring(prefix.length);
    }
  }

  Future<void> _sendComment() async {
    if (!AuthState.requireAuth(context)) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final parentId = _replyParentId;
    _replyController.clear();
    FocusScope.of(context).unfocus();
    setState(() { _replyParentId = null; _replyToName = null; });

    if (_topic.id > 0) {
      try {
        final comment = await ForumService.instance.postComment(_topic.id, text, parentId: parentId);
        if (!mounted) return;
        if (parentId != null) {
          _silentRefreshComments();
        } else {
          setState(() => _comments.insert(0, comment));
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } else if (parentId == null) {
      setState(() {
        _comments.insert(
          0,
          ForumComment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            authorName: 'Tu',
            authorInitials: 'TU',
            avatarBg: const Color(0xFFEC4899),
            avatarFg: Colors.white,
            text: text,
            timeAgo: 'Agora',
            likes: 0,
          ),
        );
      });
    }
  }

  Future<void> _silentRefreshComments() async {
    try {
      final detail = await ForumService.instance.getTopicDetail(_topic.id);
      if (mounted) setState(() => _comments = detail.comments);
    } catch (_) {}
  }

  Future<void> _deleteComment(ForumComment comment) async {
    try {
      await ForumService.instance.deleteComment(comment.numericId);
      if (!mounted) return;
      await _silentRefreshComments();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Determina qual comentário de topo deve ser expandido/scrollado para
  /// corresponder ao [widget.highlightCommentId].
  void _resolveHighlight() {
    final targetId = widget.highlightCommentId;
    if (targetId == null) return;
    for (final comment in _comments) {
      if (comment.numericId == targetId) {
        // É um comentário de topo
        setState(() {
          _scrollTargetId = comment.numericId;
          _activeHighlightId = targetId;
        });
        return;
      }
      for (final reply in comment.replies) {
        if (reply.numericId == targetId) {
          // É uma reply — expande o pai e rola até ele
          setState(() {
            _scrollTargetId = comment.numericId;
            _autoExpandParentId = comment.numericId;
            _activeHighlightId = targetId;
          });
          return;
        }
      }
    }
  }

  /// Agenda o scroll para depois do primeiro frame (após o build).
  void _scheduleScrollToHighlight() {
    if (_scrollTargetId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _commentKeys[_scrollTargetId!];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }
}

class _BackToForumHeader extends StatelessWidget {
  const _BackToForumHeader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, color: Color(0xFF7B001C), size: 20),
          SizedBox(width: 8),
          Text(
            'Voltar ao Fórum',
            style: TextStyle(
              color: Color(0xFF7B001C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicBodyCard extends StatelessWidget {
  final ForumTopic topic;
  final String? fullBody;
  final List<String> tags;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TopicBodyCard({
    required this.topic,
    this.fullBody,
    this.tags = const [],
    required this.saved,
    required this.onSave,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 30,
        compact ? 20 : 30,
        compact ? 18 : 30,
        compact ? 22 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: compact ? 12 : 18,
            runSpacing: 10,
            children: [
              AppAvatar(
                initials: topic.authorInitials,
                size: compact ? 46 : 54,
                bg: topic.avatarBg ?? AppColors.wine,
                fg: topic.avatarFg ?? Colors.white,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? 230 : 420,
                  minWidth: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.authorName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.authorRole,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _PublicBadge(isPrivate: topic.visibility == TopicVisibility.privado),
              const SizedBox(width: 14),
              Text(
                topic.timeAgo,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showTopicMenu(context),
                child: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            topic.title,
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: compact ? 22 : 27,
              height: 1.28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _bodyFor(topic),
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: tags
                  .map((tag) => Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Color(0xFF7B001C),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (topic.imageUrl != null) ...[
            const SizedBox(height: 28),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: compact ? 16 / 10 : 16 / 7,
                child: Image.network(
                  topic.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF94A3B8),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTopicMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: const Color(0xFF64748B),
              ),
              title: Text(saved ? 'Guardado' : 'Guardar'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onSave();
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF64748B)),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: const Text('Eliminar', style: TextStyle(color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onDelete!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
              title: const Text('Partilhar'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  String _bodyFor(ForumTopic topic) {
    if (fullBody != null && fullBody!.isNotEmpty) return fullBody!;
    return topic.excerpt;
  }
}

// ── Banner de apenas leitura ─────────────────────────────────────────────────

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F7))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline_rounded,
                  size: 15, color: Color(0xFF94A3B8)),
              SizedBox(width: 8),
              Text(
                'Este tópico está em modo de apenas leitura.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barra de comentário estilo Instagram ─────────────────────────────────────

class _InstagramComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final String? replyToName;
  final VoidCallback? onCancelReply;

  const _InstagramComposerBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.replyToName,
    this.onCancelReply,
  });

  @override
  State<_InstagramComposerBar> createState() => _InstagramComposerBarState();
}

class _InstagramComposerBarState extends State<_InstagramComposerBar> {
  bool _hasText = false;


  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }


  @override
  Widget build(BuildContext context) {
    final initials = AuthState.instance.isAuthenticated
        ? AuthState.instance.initials
        : '?';
    final avatarBg = AuthState.instance.isAuthenticated
        ? AppColors.wine
        : const Color(0xFF94A3B8);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F7))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner "A responder a @nome"
            if (widget.replyToName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'A responder a @${widget.replyToName}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: const Icon(Icons.close_rounded,
                          size: 15, color: AppColors.muted),
                    ),
                  ],
                ),
              ),

            // Linha principal: avatar + campo + Publicar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppAvatar(
                    initials: initials,
                    size: 34,
                    bg: avatarBg,
                    fg: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 5,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMain,
                            height: 1.4),
                        decoration: const InputDecoration(
                          hintText: 'Junta-te à conversa...',
                          hintStyle: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  if (_hasText) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onSend,
                      child: const Text(
                        'Publicar',
                        style: TextStyle(
                          color: AppColors.wine,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),



            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RepliesHeader extends StatelessWidget {
  final int count;

  const _RepliesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$count Respostas',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Text(
              'Mais recentes',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: Color(0xFFE8EDF3)),
      ],
    );
  }
}

class _CommentCard extends StatefulWidget {
  final ForumComment comment;
  final void Function(ForumComment) onReply;
  final void Function(ForumComment) onDelete;
  final bool nested;
  final bool isHighlighted;
  final int? highlightedReplyId;
  final bool autoExpandReplies;

  const _CommentCard({
    required this.comment,
    required this.onReply,
    required this.onDelete,
    this.nested = false,
    this.isHighlighted = false,
    this.highlightedReplyId,
    this.autoExpandReplies = false,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  late int _likes;
  late bool _liked;
  late bool _repliesExpanded;
  bool _activeHighlight = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _liked = widget.comment.isLiked;
    _repliesExpanded = widget.autoExpandReplies || widget.comment.replies.length <= 2;
    if (widget.isHighlighted) _startHighlight();
  }

  void _startHighlight() {
    setState(() => _activeHighlight = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _activeHighlight = false);
    });
  }

  Future<void> _toggleLike() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; });
    if (widget.comment.numericId <= 0) return;
    try {
      final r = await ForumService.instance.likeComment(widget.comment.numericId);
      if (mounted) setState(() { _liked = r.liked; _likes = r.likesCount; });
    } on ApiException {
      if (mounted) setState(() { _liked = !_liked; _likes += _liked ? -1 : 1; });
    }
  }

  void _showOptions(BuildContext context) {
    final isOwner = AuthState.instance.user?.id == widget.comment.authorId
        && widget.comment.authorId > 0;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: const Text('Apagar comentário',
                    style: TextStyle(color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  widget.onDelete(widget.comment);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Color(0xFF64748B)),
              title: const Text('Reportar comentário'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comentário reportado')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Color(0xFF64748B)),
              title: const Text('Copiar texto'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
              title: const Text('Partilhar'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined, color: Color(0xFF64748B)),
              title: const Text('Bloquear utilizador'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isReply = widget.nested;
    final avatarSize = isReply ? 32.0 : 40.0;

    // Text content: @mention bold inline for replies
    final textWidget = isReply && comment.mentionUserName != null
        ? Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '@${comment.mentionUserName} ',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                ),
              ),
              TextSpan(
                text: comment.text,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ]),
          )
        : Text(
            comment.text,
            style: TextStyle(
              color: const Color(0xFF1E293B),
              fontSize: isReply ? 14.0 : 15.0,
              height: 1.5,
            ),
          );

    // Actions: Gosto · Responder · …
    final actionsRow = Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Text(
            'Gosto',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _liked ? const Color(0xFF7B001C) : const Color(0xFF64748B),
            ),
          ),
        ),
        if (_likes > 0) ...[
          const SizedBox(width: 4),
          Text(
            '$_likes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _liked ? const Color(0xFF7B001C) : const Color(0xFF64748B),
            ),
          ),
        ],
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => widget.onReply(comment),
          child: const Text(
            'Responder',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showOptions(context),
          child: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 20),
        ),
      ],
    );

    // Content column (name + text + actions)
    Widget contentCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: comment.authorName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: ' • ${comment.timeAgo}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        textWidget,
        const SizedBox(height: 8),
        actionsRow,
      ],
    );

    // Replies get a bubble background
    if (isReply) {
      contentCol = Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: contentCol,
      );
    }

    // Row: avatar + content
    final commentRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          initials: comment.authorInitials,
          size: avatarSize,
          bg: comment.avatarBg,
          fg: comment.avatarFg,
        ),
        const SizedBox(width: 10),
        Expanded(child: contentCol),
      ],
    );

    // Thread section: vertical line + toggle + expanded replies (root only)
    Widget? threadSection;
    if (!isReply && comment.replies.isNotEmpty) {
      final firstReply = comment.replies.first;
      final replyCount = comment.replies.length;

      final toggleRow = GestureDetector(
        onTap: () => setState(() => _repliesExpanded = !_repliesExpanded),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_repliesExpanded) ...[
              AppAvatar(
                initials: firstReply.authorInitials,
                size: 20,
                bg: firstReply.avatarBg,
                fg: firstReply.avatarFg,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                _repliesExpanded
                    ? 'Ocultar respostas'
                    : '${firstReply.authorName} respondeu · $replyCount respostas',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _repliesExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      );

      threadSection = Padding(
        padding: const EdgeInsets.only(top: 8, left: 20),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
          ),
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              toggleRow,
              if (_repliesExpanded) ...[
                const SizedBox(height: 10),
                ...comment.replies.asMap().entries.map((e) => Padding(
                      padding: EdgeInsets.only(top: e.key == 0 ? 0 : 12),
                      child: _CommentCard(
                        comment: e.value,
                        onReply: widget.onReply,
                        onDelete: widget.onDelete,
                        nested: true,
                        isHighlighted:
                            e.value.numericId == widget.highlightedReplyId,
                      ),
                    )),
              ],
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      padding: _activeHighlight ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _activeHighlight
            ? const Color(0xFF7B001C).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _activeHighlight
              ? const Color(0xFF7B001C).withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commentRow,
          ?threadSection,
        ],
      ),
    );
  }
}

class _PublicBadge extends StatelessWidget {
  final bool isPrivate;

  const _PublicBadge({required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF1F2) : const Color(0xFFEAFBF1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_outline_rounded : Icons.circle,
            size: isPrivate ? 15 : 8,
            color: isPrivate
                ? const Color(0xFFE11D48)
                : const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Text(
            isPrivate ? 'PRIVADO' : 'PÚBLICO',
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
