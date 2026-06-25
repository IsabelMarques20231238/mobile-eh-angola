import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/forum_service.dart';
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
  final _replySectionKey = GlobalKey();
  List<ForumComment> _comments = [];
  late ForumTopic _topic;
  late int _likes;
  late bool _liked;
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

  @override
  void initState() {
    super.initState();
    _topic = widget.topic;
    _likes = widget.topic.likes;
    _liked = widget.topic.isLiked;
    _saved = widget.topic.isSaved;
    // Se veio de uma notificação, o título está vazio — precisamos de carregar
    if (widget.topic.id > 0) _loadTopicDetail();
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
        _likes = detail.likesCount;
        _liked = detail.isLiked;
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
    _searchController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 22,
          compact ? 24 : 36,
          compact ? 14 : 22,
          28,
        ),
        children: [
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
                  const Icon(Icons.error_outline_rounded, color: AppColors.wine, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    _topicError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadTopicDetail,
                    child: const Text('Tentar novamente', style: TextStyle(color: AppColors.wine)),
                  ),
                ],
              ),
            )
          else
          _TopicBodyCard(
            topic: _topic,
            fullBody: _topicBody,
            likes: _likes,
            liked: _liked,
            comments: _commentCount,
            saved: _saved,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: _scrollToReply,
            onEdit: _topic.permissions.canEdit ? _openEdit : null,
          ),
          if (_topic.permissions.canComment) ...[
            const SizedBox(height: 32),
            _ReplyComposer(
              key: _replySectionKey,
              controller: _replyController,
              focusNode: _replyFocusNode,
              onSend: _sendComment,
              replyToName: _replyToName,
              onCancelReply: _cancelReply,
            ),
            const SizedBox(height: 36),
          ] else
            const SizedBox(height: 32),
          _RepliesHeader(count: _commentCount),
          const SizedBox(height: 20),
          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: AppColors.wine)),
            )
          else if (_commentsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _commentsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            )
          else
          ..._comments.asMap().entries.map((entry) {
            final i = entry.key;
            final comment = entry.value;
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
                    isHighlighted: isHighlighted,
                    highlightedReplyId: isParent ? _activeHighlightId : null,
                    autoExpandReplies: isParent,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; });
    if (_topic.id <= 0) return;
    try {
      final r = await ForumService.instance.likeTopic(_topic.id);
      if (mounted) setState(() { _liked = r.liked; _likes = r.likesCount; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _liked = !_liked; _likes += _liked ? -1 : 1; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

  void _scrollToReply() {
    final context = _replySectionKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
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
    _scrollToReply();
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
  final int likes;
  final bool liked;
  final int comments;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback? onEdit;

  const _TopicBodyCard({
    required this.topic,
    this.fullBody,
    required this.likes,
    required this.liked,
    required this.comments,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    this.onEdit,
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
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF94A3B8)),
                  tooltip: 'Editar tópico',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
          const SizedBox(height: 28),
          ForumInteractionBar(
            locked: !AuthState.instance.isAuthenticated,
            likes: likes,
            liked: liked,
            comments: comments,
            saved: saved,
            onLike: onLike,
            onComment: onComment,
            onSave: onSave,
          ),
        ],
      ),
    );
  }

  String _bodyFor(ForumTopic topic) {
    if (fullBody != null && fullBody!.isNotEmpty) return fullBody!;
    return topic.excerpt;
  }
}

class _ReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final String? replyToName;
  final VoidCallback? onCancelReply;

  const _ReplyComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.replyToName,
    this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARTICIPAR NO DEBATE',
            style: TextStyle(
              color: Color(0xFF8A9AB2),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (replyToName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 15, color: AppColors.wine),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'A responder a @$replyToName',
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.wine),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                initials: AuthState.instance.isAuthenticated
                    ? AuthState.instance.initials
                    : '?',
                size: 44,
                bg: AuthState.instance.isAuthenticated
                    ? AppColors.wine
                    : const Color(0xFFEC4899),
                fg: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Adicione a sua perspectiva,\ncomentário ou fontes de pesquisa\npara o debate...',
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.wine),
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 45,
              width: 213,
              child: ElevatedButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send_outlined, size: 21),
                label: const Text('Publicar resposta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B001C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
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
  final bool nested;
  final bool isHighlighted;
  final int? highlightedReplyId;
  final bool autoExpandReplies;

  const _CommentCard({
    required this.comment,
    required this.onReply,
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
    _repliesExpanded = widget.autoExpandReplies;
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
    const indent = 46.0; // avatar (36) + gap (10)

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
        // Linha de cabeçalho: avatar + username • tempo
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              initials: widget.comment.authorInitials,
              size: 36,
              bg: widget.comment.avatarBg,
              fg: widget.comment.avatarFg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.comment.authorName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' • ${widget.comment.timeAgo}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Texto e acções alinhados com o username
        Padding(
          padding: const EdgeInsets.only(left: indent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comment.text,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              // Barra de acções: ♥ likes  Responder  ...
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: _liked ? const Color(0xFF7B001C) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _liked ? const Color(0xFF7B001C) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => widget.onReply(widget.comment),
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
                    child: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ],
              ),
              // Respostas colapsadas
              if (widget.comment.replies.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _repliesExpanded = !_repliesExpanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _repliesExpanded
                            ? Icons.remove_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 17,
                        color: const Color(0xFF7B001C),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${widget.comment.replies.length} outras respostas',
                        style: const TextStyle(
                          color: Color(0xFF7B001C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_repliesExpanded) ...[
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 2,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: widget.comment.replies
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                      padding: EdgeInsets.only(
                                        top: e.key == 0 ? 0 : 16,
                                      ),
                                      child: _CommentCard(
                                        comment: e.value,
                                        onReply: widget.onReply,
                                        nested: true,
                                        isHighlighted: e.value.numericId == widget.highlightedReplyId,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
      ), // Column
    ); // AnimatedContainer
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
