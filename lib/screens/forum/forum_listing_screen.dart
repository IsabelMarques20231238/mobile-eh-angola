import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/forum_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import '../profile/saved_items_screen.dart';
import 'criar_topico_screen.dart';
import 'forum_topic_detail_screen.dart';
import 'subscricoes_screen.dart';
import 'topico_privado_screen.dart';
import '../notifications/notifications_screen.dart';

class ForumListingScreen extends StatefulWidget {
  const ForumListingScreen({super.key});

  @override
  State<ForumListingScreen> createState() => _ForumListingScreenState();
}

class _ForumListingScreenState extends State<ForumListingScreen> {
  final _searchController = TextEditingController();
  List<ForumTopic> _topics = [];
  List<ForumCategory> _categories = [];
  int _selectedChip = 0;
  bool _showSearch = false;
  bool _isLoading = false;
  String? _error;
  Timer? _searchTimer;

  // Chip 0 → "Para ti" (filter=for-you), chips 1..N → categories from API
  List<String> get _chips =>
      ['Para ti', ..._categories.map((c) => c.name)];

  String? get _activeFilter => _selectedChip == 0 ? 'for-you' : null;
  String? get _activeCategory =>
      _selectedChip > 0 && _selectedChip <= _categories.length
          ? _categories[_selectedChip - 1].name
          : null;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ForumService.instance.getTopics(
        filter: _activeFilter,
        category: _activeCategory,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _topics = result.topics;
        if (result.categories.isNotEmpty) _categories = result.categories;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _isLoading = false; });
    }
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), _loadTopics);
    setState(() {});
  }

  void _onChipSelected(int index) {
    setState(() => _selectedChip = index);
    _loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveForum(context);
      },
      child: Scaffold(
        backgroundColor: context.c.bg,
        body: SafeArea(
          child: Column(
            children: [
              EhAngolaHeader(
                searchController: _searchController,
                showSearch: _showSearch,
                onSearchChanged: _onSearchChanged,
                onSearchTap: () => setState(() => _showSearch = !_showSearch),
                onNotificationsTap: () => showNotificationsPanel(context),
              ),
              Container(
                width: double.infinity,
                color: context.c.card,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                child: _ForumChipBar(
                  labels: _chips,
                  selected: _selectedChip,
                  onSelected: _onChipSelected,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.wine,
                  onRefresh: _loadTopics,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      _ForumHero(
                        onMyForums: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscricoesScreen(),
                          ),
                        ),
                        onSaved: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedItemsScreen(),
                          ),
                        ),
                        onCreate: _openCreateTopic,
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.wine),
                          ),
                        )
                      else if (_error != null)
                        _ForumErrorState(
                          message: _error!,
                          onRetry: _loadTopics,
                        )
                      else if (_topics.isEmpty)
                        const _EmptyForumState()
                      else
                        ..._topics.map((topic) {
                            final isAuthor = topic.authorId > 0 &&
                                topic.authorId == AuthState.instance.user?.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TopicCard(
                                key: ValueKey(topic.id > 0 ? topic.id : topic.title),
                                topic: topic,
                                onTap: () => _openTopic(topic),
                                onEdit: isAuthor ? () => _editTopic(topic) : null,
                                onDelete: isAuthor ? () => _deleteTopic(topic) : null,
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavMock(index: 1),
      ),
    );
  }

  void _openTopic(ForumTopic topic) {
    final needsAccess = topic.visibility == TopicVisibility.privado && !topic.hasAccess;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => needsAccess
            ? TopicoPrivadoScreen(topic: topic)
            : ForumTopicDetailScreen(topic: topic),
      ),
    );
  }

  void _openCreateTopic() {
    if (!AuthState.requireAuth(context)) return;
    Navigator.push(
      context,
      AppRoutes.bottomSlideRoute(builder: (_) => const CriarTopicoScreen()),
    );
  }

  Future<void> _editTopic(ForumTopic topic) async {
    try {
      final detail = await ForumService.instance.getTopicDetail(topic.id);
      if (!mounted) return;
      final refreshed = await Navigator.push<bool>(
        context,
        AppRoutes.bottomSlideRoute(
          builder: (_) => CriarTopicoScreen(
            editTopic: detail.topic ?? topic,
            editBody: detail.body,
            editTags: detail.tags,
          ),
        ),
      );
      if (refreshed == true && mounted) _loadTopics();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  Future<void> _deleteTopic(ForumTopic topic) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Apagar tópico',
      message: 'Tens a certeza que queres apagar este tópico? Esta acção é irreversível.',
      confirmLabel: 'Apagar',
      cancelLabel: 'Cancelar',
      type: AppDialogType.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await ForumService.instance.deleteTopic(topic.id);
      if (mounted) setState(() => _topics.removeWhere((t) => t.id == topic.id));
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  void _leaveForum(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.feed);
  }
}

class _ForumHero extends StatelessWidget {
  final VoidCallback onMyForums;
  final VoidCallback onSaved;
  final VoidCallback onCreate;

  const _ForumHero({
    required this.onMyForums,
    required this.onSaved,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeroGridPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)),
                    SizedBox(width: 8),
                    Text(
                      'COMUNIDADE EH. ANGOLA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fórum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Partilhe conhecimento, tire dúvidas e participe\nem discussões que impulsionam o crescimento\nacadémico e profissional.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ListenableBuilder(
                listenable: AuthState.instance,
                builder: (context, _) {
                  if (!AuthState.instance.isAuthenticated) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _HeroActionButton(
                            icon: Icons.person_outline_rounded,
                            label: 'Meus Fóruns',
                            onTap: onMyForums,
                          ),
                          _HeroActionButton(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Guardados',
                            onTap: onSaved,
                          ),
                          _HeroActionButton(
                            icon: Icons.add_rounded,
                            label: 'Criar Tópico',
                            light: true,
                            onTap: onCreate,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForumChipBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const _ForumChipBar({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  static IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l == 'para ti') return Icons.star_border_rounded;
    if (l.contains('econ') || l.contains('finanç') || l.contains('financ')) return Icons.trending_up_rounded;
    if (l.contains('hist') || l.contains('cultur') || l.contains('tradição')) return Icons.menu_book_outlined;
    if (l.contains('petr') || l.contains('energ') || l.contains('gás') || l.contains('gas')) return Icons.local_gas_station_outlined;
    if (l.contains('polít') || l.contains('polit') || l.contains('govern') || l.contains('estado')) return Icons.account_balance_outlined;
    if (l.contains('tecnol') || l.contains('digital') || l.contains('inovat')) return Icons.devices_rounded;
    if (l.contains('saúde') || l.contains('saude') || l.contains('médic') || l.contains('medic')) return Icons.health_and_safety_outlined;
    if (l.contains('educ') || l.contains('ensino') || l.contains('escol')) return Icons.school_outlined;
    if (l.contains('desport') || l.contains('futebol') || l.contains('sport')) return Icons.sports_soccer_rounded;
    if (l.contains('social') || l.contains('socie') || l.contains('comuni')) return Icons.people_outline_rounded;
    if (l.contains('ambient') || l.contains('natur') || l.contains('ecolog')) return Icons.eco_outlined;
    if (l.contains('arte') || l.contains('músic') || l.contains('music') || l.contains('cine')) return Icons.palette_outlined;
    if (l.contains('negóci') || l.contains('negoci') || l.contains('empresa')) return Icons.business_outlined;
    if (l.contains('agricultur') || l.contains('agro')) return Icons.grass_outlined;
    return Icons.label_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final active = selected == index;
          final icon = _iconForLabel(labels[index]);
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(23),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: active ? c.wine : c.card,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: active ? c.wine : c.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: active ? Colors.white : c.muted),
                  const SizedBox(width: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? Colors.white : c.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicCard extends StatefulWidget {
  final ForumTopic topic;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TopicCard({
    super.key,
    required this.topic,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  late int _likes;
  late bool _liked;
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _likes = widget.topic.likes;
    _liked = widget.topic.isLiked;
    _saved = widget.topic.isSaved;
  }

  Future<void> _toggleLike() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; });
    if (widget.topic.id <= 0) return;
    try {
      final r = await ForumService.instance.likeTopic(widget.topic.id);
      if (mounted) setState(() { _liked = r.liked; _likes = r.likesCount; });
    } on ApiException {
      if (mounted) setState(() { _liked = !_liked; _likes += _liked ? -1 : 1; });
    }
  }

  Future<void> _toggleSave() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() => _saved = !_saved);
    if (widget.topic.id <= 0) return;
    try {
      final bookmarked = await ForumService.instance.bookmarkTopic(widget.topic.id);
      if (mounted) setState(() => _saved = bookmarked);
    } on ApiException {
      if (mounted) setState(() => _saved = !_saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final topic = widget.topic;
    final isPrivate = topic.visibility == TopicVisibility.privado;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (topic.isPinned)
                        const _PinnedLabel()
                      else
                        _CategoryBadge(category: topic.category),
                      const SizedBox(width: 12),
                      _VisibilityBadge(visibility: topic.visibility),
                      const Spacer(),
                      Text(
                        topic.timeAgo,
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AppAvatar(
                        initials: topic.authorInitials,
                        size: 32,
                        bg: topic.avatarBg ?? AppColors.winePill,
                        fg: topic.avatarFg ?? AppColors.wine,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.textMain,
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (topic.authorRole.isNotEmpty)
                              Text(
                                topic.authorRole,
                                style: TextStyle(color: c.muted, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.title,
                    maxLines: topic.imageUrl == null ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPrivate || topic.isPinned
                          ? c.textMain
                          : _titleColor(topic.category, c),
                      fontSize: 17,
                      height: 1.28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (topic.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    _TopicImage(url: topic.imageUrl!),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: ForumInteractionBar(
              compact: true,
              locked: !AuthState.instance.isAuthenticated,
              likes: _likes,
              liked: _liked,
              comments: topic.comments,
              saved: _saved,

              onLike: _toggleLike,
              onComment: widget.onTap,
              onSave: _toggleSave,
            ),
          ),
        ],
      ),
    );
  }

  Color _titleColor(TopicCategory category, AppAdaptiveColors c) {
    if (Theme.of(context).brightness == Brightness.dark) return c.textMain;
    return switch (category) {
      TopicCategory.economia => const Color(0xFF6F2435),
      TopicCategory.petroleo => const Color(0xFF6F2435),
      TopicCategory.politica => const Color(0xFF0F172A),
      TopicCategory.historia => const Color(0xFF0F172A),
      TopicCategory.tudo => const Color(0xFF0F172A),
    };
  }
}

class _CategoryBadge extends StatelessWidget {
  final TopicCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final data = switch (category) {
      TopicCategory.economia => (
        'ECONOMIA',
        const Color(0xFFFFEEF6),
        const Color(0xFFE6007A),
      ),
      TopicCategory.historia => (
        'HISTÓRIA',
        const Color(0xFFFFF8E8),
        const Color(0xFFD97706),
      ),
      TopicCategory.petroleo => (
        'PETRÓLEO',
        const Color(0xFFE6FBFF),
        const Color(0xFF0891B2),
      ),
      TopicCategory.politica => (
        'POLÍTICO',
        const Color(0xFFF1ECFF),
        const Color(0xFF7C3AED),
      ),
      TopicCategory.tudo => (
        'GERAL',
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$3,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final TopicVisibility visibility;

  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isPrivate = visibility == TopicVisibility.privado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF1F2) : c.bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isPrivate ? const Color(0xFFFFD5DF) : c.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrivate) ...[
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: Color(0xFFE11D48),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            isPrivate ? 'Privado' : 'Público',
            style: TextStyle(
              color: isPrivate ? const Color(0xFFE11D48) : c.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicImage extends StatelessWidget {
  final String url;

  const _TopicImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFFF59E0B)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.white, size: 42),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool light;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: label,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: light ? Colors.white : Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .24)),
          ),
          child: Icon(
            icon,
            color: light ? AppColors.wine : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}


class _PinnedLabel extends StatelessWidget {
  const _PinnedLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.push_pin_outlined, size: 18, color: Color(0xFFF97316)),
        SizedBox(width: 6),
        Text(
          'FIXADO',
          style: TextStyle(
            color: Color(0xFFF97316),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ForumErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ForumErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: c.muted, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: c.wine),
            child: const Text('Tentar novamente', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _EmptyForumState extends StatelessWidget {
  const _EmptyForumState();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: c.muted, size: 44),
          const SizedBox(height: 12),
          Text(
            'Nenhum tópico encontrado.',
            style: TextStyle(
              color: c.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
