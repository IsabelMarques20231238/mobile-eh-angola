import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/articles/article_detail_screen.dart';
import '../../screens/jindungo/jindungo_feed_screen.dart';
import '../../screens/podcast/podcast_detail_screen.dart';
import '../../screens/quiz/quiz_detail_screen.dart';
import '../../screens/quiz/quiz_guest_preview_screen.dart';
import '../../screens/quiz/quiz_models.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/video/video_detail_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FeedScreen extends StatefulWidget {
  final bool isGuest;
  const FeedScreen({super.key, this.isGuest = true});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _featuredPage = 0;
  final _pageController = PageController();
  late final List<Quiz> _quizzes;

  static const _featuredItems = [
    _FeaturedItem(
      imageUrl:
          'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=900&q=80',
      title:
          'A Industrialização Tardia em Angola: Desafios e Heranças do Século XX',
      date: 'Março 15, 2024',
      readTime: '12 min leitura',
      author: 'Dr. Armindo Santos',
    ),
    _FeaturedItem(
      imageUrl:
          'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=900&q=80',
      title: 'Petróleo e Poder: Angola no Contexto da Guerra Fria',
      date: 'Fev 20, 2024',
      readTime: '9 min leitura',
      author: 'Prof. Ana Silva',
    ),
    _FeaturedItem(
      imageUrl:
          'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=900&q=80',
      title: 'Kwanza: 40 Anos de Moeda Soberana e Crises Monetárias',
      date: 'Jan 30, 2024',
      readTime: '7 min leitura',
      author: 'Dr. Manuel Bento',
    ),
  ];

  static const _contentItems = [
    _ContentItem(
      imageUrl:
          'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=900&q=80',
      badge: 'VÍDEO',
      title: 'A Reforma Monetária de 1976: Do Kwanza ao Escudo Explicador',
      excerpt:
          'Uma análise profunda sobre a transição soberana da moeda e os seus impactos económicos e...',
      author: 'Maria Luísa',
      isMedia: true,
      isSaved: false,
    ),
    _ContentItem(
      imageUrl:
          'https://images.unsplash.com/photo-1555664424-778a1e5e1b48?auto=format&fit=crop&w=900&q=80',
      badge: 'PODCAST',
      title: 'A Reforma Monetária de 1976: Do Kwanza ao Escudo Interchange',
      excerpt:
          'Uma análise profunda sobre a transição soberana da moeda e os seus impactos económicos e...',
      author: 'Maria Luísa',
      isMedia: true,
      isSaved: false,
    ),
    _ContentItem(
      imageUrl:
          'https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?auto=format&fit=crop&w=900&q=80',
      badge: 'ARTIGO',
      title: 'A Reforma Monetária de 1976: Do Kwanza ao Escudo',
      excerpt:
          'Uma análise profunda sobre a transição soberana da moeda e os seus impactos económicos e...',
      author: 'Maria Luísa',
      isMedia: false,
      isSaved: true,
    ),
    _ContentItem(
      imageUrl:
          'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=900&q=80',
      badge: 'ARTIGO',
      title: 'A Evolução do Sistema Bancário em Angola: Do Colonial ao Digital',
      excerpt:
          'Como o sistema bancário angolano se transformou ao longo de décadas e quais os desafios actuais...',
      author: 'Dr. Armindo Santos',
      isMedia: false,
      isSaved: false,
    ),
  ];

  static const _temas = [
    '#Kwanza',
    '#Petróleo',
    '#RecuperaçãoAtivos',
    '#Agronegócio',
    '#HistóriaMonetária',
    '#Diversificação',
    '#BNA',
  ];

  @override
  void initState() {
    super.initState();
    _quizzes = QuizData.quizzes;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: SafeArea(
          bottom: false,
          child: EhAngolaHeader(
            onSearchTap: _openSearch,
            onNotificationsTap: _openNotifications,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          children: [
            // ── Featured carousel ────────────────────────────────
            SizedBox(
              height: 270,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _featuredItems.length,
                onPageChanged: (i) => setState(() => _featuredPage = i),
                itemBuilder: (_, i) => _FeaturedCard(
                  item: _featuredItems[i],
                  onTap: () => _openArticle(i),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _featuredItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _featuredPage ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _featuredPage
                        ? AppColors.wine
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Jindungo banner ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _JindungoBanner(onTap: _openJindungo),
            ),
            const SizedBox(height: 24),

            // ── Vídeo + Podcast + more content ──────────────────
            ..._contentItems.take(2).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ContentCard(
                  item: item,
                  onTap: item.badge == 'VÍDEO'
                      ? _openVideo
                      : item.badge == 'PODCAST'
                      ? _openPodcast
                      : () => _openArticle(0),
                ),
              ),
            ),

            // ── Temas em Alta ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _TemasEmAlta(temas: _temas),
            ),

            // ── Recentes ─────────────────────────────────────────
            _SectionHeader(
              title: 'Recentes',
              onSeeAll: () {},
            ),
            const SizedBox(height: 12),
            ..._contentItems.skip(2).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ContentCard(
                  item: item,
                  onTap: () => _openArticle(0),
                ),
              ),
            ),

            // ── Quizzes Populares ────────────────────────────────
            _SectionHeader(
              title: 'Quizzes Populares',
              onSeeAll: () => Navigator.pushNamed(context, AppRoutes.quizList),
            ),
            const SizedBox(height: 12),
            ..._quizzes.map(
              (quiz) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _QuizListCard(
                  quiz: quiz,
                  onTap: () => _openQuiz(quiz),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavMock(index: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.wine,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _openQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isGuest
            ? QuizGuestPreviewScreen(quiz: quiz)
            : QuizDetailScreen(quiz: quiz),
      ),
    );
  }

  void _openArticle(int index) {
    final article =
        featuredArticleDetails[index % featuredArticleDetails.length];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }

  void _openPodcast() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PodcastDetailScreen(episode: featuredPodcast),
      ),
    );
  }

  void _openVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VideoDetailScreen(video: featuredVideo),
      ),
    );
  }

  void _openJindungo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JindungoFeedScreen()),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _openNotifications() => showNotificationsPanel(context);
}

// ── Data models ─────────────────────────────────────────────────────────────

class _FeaturedItem {
  final String imageUrl;
  final String title;
  final String date;
  final String readTime;
  final String author;

  const _FeaturedItem({
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.readTime,
    required this.author,
  });
}

class _ContentItem {
  final String imageUrl;
  final String badge;
  final String title;
  final String excerpt;
  final String author;
  final bool isMedia;
  final bool isSaved;

  const _ContentItem({
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.isMedia,
    required this.isSaved,
  });
}

// ── Featured card ────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final _FeaturedItem item;
  final VoidCallback onTap;

  const _FeaturedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primaryDark,
              ),
            ),
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xDD000000)],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'EM DESTAQUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Meta row
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.date,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.readTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.author,
                    style: const TextStyle(
                      color: AppColors.winePill,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
}

// ── Jindungo banner ──────────────────────────────────────────────────────────

class _JindungoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _JindungoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF681333), Color(0xFF4C0D25)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🔥', style: TextStyle(fontSize: 17)),
                SizedBox(width: 6),
                Text(
                  'TEXTOS COM JINDUNGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Opinião crua e directa sobre as falhas sistémicas da economia nacional.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
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

// ── Content card (Artigo / Vídeo / Podcast) ──────────────────────────────────

class _ContentCard extends StatefulWidget {
  final _ContentItem item;
  final VoidCallback onTap;

  const _ContentCard({required this.item, required this.onTap});

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.item.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (widget.item.isMedia)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  if (widget.item.isMedia)
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Text area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BadgePill(label: widget.item.badge),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.item.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Por ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        widget.item.author,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.wine,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _saved = !_saved),
                        child: Icon(
                          _saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 22,
                          color: _saved ? AppColors.wine : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  const _BadgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.winePill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.wine,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Temas em Alta ────────────────────────────────────────────────────────────

class _TemasEmAlta extends StatelessWidget {
  final List<String> temas;
  const _TemasEmAlta({required this.temas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEMAS EM ALTA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: temas.map((tag) => _TemaChip(tag: tag)).toList(),
          ),
        ],
      ),
    );
  }
}

class _TemaChip extends StatelessWidget {
  final String tag;
  const _TemaChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.wine,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Text(
              'Ver todos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.wine,
              ),
            ),
            label: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.wine,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quiz list card ───────────────────────────────────────────────────────────

class _QuizListCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const _QuizListCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textMain,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                quiz.isNew ? 'NOVO' : quiz.difficulty.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: '${quiz.questionCount} perguntas • Criado por ',
                children: [
                  TextSpan(
                    text: quiz.author,
                    style: const TextStyle(
                      color: AppColors.wine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
