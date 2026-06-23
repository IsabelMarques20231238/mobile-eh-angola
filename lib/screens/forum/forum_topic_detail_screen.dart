import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../models/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final ForumTopic topic;

  const ForumTopicDetailScreen({super.key, required this.topic});

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  final _searchController = TextEditingController();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _replySectionKey = GlobalKey();
  late List<ForumComment> _comments;
  late int _likes;
  late bool _liked;
  late int _savedCount;
  late bool _saved;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _comments = buildMockComments();
    _likes = widget.topic.likes;
    _liked = widget.topic.isLiked;
    _savedCount = 25;
    _saved = false;
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
          _TopicBodyCard(
            topic: widget.topic,
            likes: _likes,
            liked: _liked,
            comments: _commentCount,
            savedCount: _savedCount,
            saved: _saved,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: _scrollToReply,
          ),
          const SizedBox(height: 32),
          _ReplyComposer(
            key: _replySectionKey,
            controller: _replyController,
            focusNode: _replyFocusNode,
            onSend: _sendComment,
          ),
          const SizedBox(height: 36),
          _RepliesHeader(count: _commentCount),
          const SizedBox(height: 20),
          ..._comments.asMap().entries.map((entry) {
            final i = entry.key;
            final comment = entry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(color: Color(0xFFE8EDF3), height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _CommentCard(
                    comment: comment,
                    onReply: () => _startReply(comment.authorName),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _toggleSave() {
    setState(() {
      _saved = !_saved;
      _savedCount += _saved ? 1 : -1;
    });
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

  void _startReply(String author) {
    _replyController.text = '@$author ';
    _replyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _replyController.text.length),
    );
    _scrollToReply();
    _replyFocusNode.requestFocus();
  }

  void _sendComment() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(
        0,
        ForumComment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorName: 'Novo Membro',
          authorInitials: 'NM',
          avatarBg: const Color(0xFFEC4899),
          avatarFg: Colors.white,
          text: text,
          timeAgo: 'Agora',
          likes: 0,
        ),
      );
    });
    _replyController.clear();
    FocusScope.of(context).unfocus();
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
  final int likes;
  final bool liked;
  final int comments;
  final int savedCount;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;

  const _TopicBodyCard({
    required this.topic,
    required this.likes,
    required this.liked,
    required this.comments,
    required this.savedCount,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onComment,
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
                    const Text(
                      'Pesquisador no ISPTEC',
                      style: TextStyle(
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
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              _PublicBadge(
                isPrivate: topic.visibility == TopicVisibility.privado,
              ),
              Text(
                topic.timeAgo,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
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
            likes: likes,
            liked: liked,
            comments: comments,
            savedCount: savedCount,
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
    if (topic.title.contains('Kwanza')) {
      return 'A reforma monetária de 1977, que substituiu o Escudo pelo Kwanza, marcou um ponto de viragem crucial na soberania económica de Angola. No entanto, a transição nas zonas rurais revelou desafios profundos de logística, liquidez e confiança pública.\n\nEste tópico visa explorar os testemunhos e registos históricos sobre como a população campesina percebeu a mudança de valor e como o novo sistema monetário influenciou as trocas comerciais directas no interior do país durante a primeira década de independência.';
    }
    return '${topic.excerpt}\n\nEste tópico procura reunir perspectivas, dados de pesquisa e exemplos concretos para apoiar uma discussão académica e profissional entre os membros da comunidade.';
  }
}

class _ReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _ReplyComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
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
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppAvatar(
                initials: 'NM',
                size: 44,
                bg: Color(0xFFEC4899),
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
  final VoidCallback onReply;
  final bool nested;

  const _CommentCard({
    required this.comment,
    required this.onReply,
    this.nested = false,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  late int _likes;
  late bool _liked;
  bool _repliesExpanded = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
    _liked = widget.comment.isLiked;
  }

  void _toggleLike() => setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });

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

    return Column(
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
                    onTap: widget.onReply,
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
