import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../models/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import '../profile/saved_items_screen.dart';
import 'criar_topico_screen.dart';
import 'forum_topic_detail_screen.dart';
import 'subscricoes_screen.dart';
import 'topico_privado_screen.dart';

class ForumListingScreen extends StatefulWidget {
  const ForumListingScreen({super.key});

  @override
  State<ForumListingScreen> createState() => _ForumListingScreenState();
}

class _ForumListingScreenState extends State<ForumListingScreen> {
  final _searchController = TextEditingController();
  final _chips = ['Para ti', 'Economia', 'História', 'Petróleo', 'Político'];
  late List<ForumTopic> _topics;
  int _selectedChip = 0;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _topics = buildMockTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ForumTopic> get _filtered {
    final cats = {
      1: TopicCategory.economia,
      2: TopicCategory.historia,
      3: TopicCategory.petroleo,
      4: TopicCategory.politica,
    };
    final query = _searchController.text.trim().toLowerCase();
    return _topics.where((topic) {
      final matchesChip =
          _selectedChip == 0 || topic.category == cats[_selectedChip];
      final matchesQuery =
          query.isEmpty ||
          topic.title.toLowerCase().contains(query) ||
          topic.excerpt.toLowerCase().contains(query) ||
          topic.authorName.toLowerCase().contains(query);
      return matchesChip && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveForum(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              EhAngolaHeader(
                searchController: _searchController,
                showSearch: _showSearch,
                onSearchChanged: (_) => setState(() {}),
                onSearchTap: () => setState(() => _showSearch = !_showSearch),
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                child: _ForumChipBar(
                  labels: _chips,
                  selected: _selectedChip,
                  onSelected: (index) => setState(() {
                    _selectedChip = index;
                  }),
                ),
              ),
              Expanded(
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
                    if (_filtered.isEmpty)
                      const _EmptyForumState()
                    else
                      ..._filtered.map(
                        (topic) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TopicCard(
                            key: ValueKey(topic.title),
                            topic: topic,
                            onTap: () => _openTopic(topic),
                          ),
                        ),
                      ),
                  ],
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
    final isPrivate = topic.visibility == TopicVisibility.privado;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isPrivate
            ? TopicoPrivadoScreen(topic: topic)
            : ForumTopicDetailScreen(topic: topic),
      ),
    );
  }

  void _openCreateTopic() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarTopicoScreen()),
    );
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A0022).withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'SIMULAR:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _HeroRolePill(text: '🎓 MEMBRO', selected: true),
                    _HeroRolePill(text: '👥 ADMINS'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.star_border_rounded,
      Icons.trending_up_rounded,
      Icons.menu_book_outlined,
      Icons.local_gas_station_outlined,
      Icons.account_balance_outlined,
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final active = selected == index;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(23),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: active ? AppColors.wine : Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: active ? AppColors.wine : const Color(0xFF64748B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[index],
                    size: 19,
                    color: active ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF334155),
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

  const _TopicCard({super.key, required this.topic, required this.onTap});

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  late int _likes;
  late bool _liked;
  late int _savedCount;
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _likes = widget.topic.likes;
    _liked = widget.topic.isLiked;
    _savedCount = (widget.topic.comments * 0.16).round().clamp(1, 40);
    _saved = false;
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final isPrivate = topic.visibility == TopicVisibility.privado;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
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
                        child: Text(
                          topic.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
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
                          ? const Color(0xFF0F172A)
                          : _titleColor(topic.category),
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
                    style: const TextStyle(
                      color: Color(0xFF64748B),
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
              likes: _likes,
              liked: _liked,
              comments: topic.comments,
              savedCount: _savedCount,
              saved: _saved,
              onLike: () => setState(() {
                _liked = !_liked;
                _likes += _liked ? 1 : -1;
              }),
              onComment: widget.onTap,
              onSave: () => setState(() {
                _saved = !_saved;
                _savedCount += _saved ? 1 : -1;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _titleColor(TopicCategory category) {
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
    final isPrivate = visibility == TopicVisibility.privado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isPrivate ? const Color(0xFFFFD5DF) : const Color(0xFFE8EDF3),
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
              color: isPrivate
                  ? const Color(0xFFE11D48)
                  : const Color(0xFF94A3B8),
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

class _HeroRolePill extends StatelessWidget {
  final String text;
  final bool selected;

  const _HeroRolePill({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? AppColors.wine : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w900,
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

class _EmptyForumState extends StatelessWidget {
  const _EmptyForumState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 44),
          SizedBox(height: 12),
          Text(
            'Nenhum tópico encontrado.',
            style: TextStyle(
              color: Color(0xFF334155),
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
