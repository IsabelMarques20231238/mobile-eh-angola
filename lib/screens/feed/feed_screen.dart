import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../screens/articles/article_detail_screen.dart';
import '../../screens/jindungo/jindungo_feed_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
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
  int _selectedTopic = 0;
  late final List<Quiz> _linkedQuizzes;

  static const _topics = [
    'Para ti',
    'Economia',
    'História',
    'Petróleo',
    'Moeda',
  ];

  final _featured = const [
    _FeedArticle(
      category: 'Em Destaque',
      title:
          'A Evolução do Sistema Bancário em Angola: Do Período Colonial à Atualidade',
      meta: 'Artigo · 8 min · por Prof. Ana Silva',
      accent: AppColors.primary,
      likes: 42,
      icon: Icons.article,
    ),
    _FeedArticle(
      category: 'Em Destaque',
      title: 'A Evolução da Moeda: do Zimbo ao Kwanza Moderno',
      meta: 'Artigo · 6 min · por Dr. Manuel Bento',
      accent: AppColors.success,
      likes: 28,
      icon: Icons.account_balance,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _linkedQuizzes = [
      QuizData.quizzes.firstWhere((quiz) => quiz.id == '3'),
      QuizData.quizzes.firstWhere((quiz) => quiz.id == '2'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          bottom: false,
          child: EhAngolaHeader(
            onSearchTap: _openSearch,
            onNotificationsTap: _openNotifications,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          _TopicStrip(
            topics: _topics,
            selected: _selectedTopic,
            onSelected: (index) => setState(() => _selectedTopic = index),
          ),
          SizedBox(
            height: 336,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: _featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (context, index) => _FeaturedCard(
                article: _featured[index],
                onTap: () => _openArticle(index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: _PodcastBanner(onTap: _openPodcast),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: _VideoBanner(onTap: _openVideo),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: _JindungoBanner(onPressed: _openJindungo),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quizzes Populares',
                    style: TextStyle(
                      color: AppColors.wine,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.quizList),
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 138,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _linkedQuizzes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _QuizCard(
                quiz: _linkedQuizzes[index],
                onStart: () => _openQuiz(_linkedQuizzes[index]),
              ),
            ),
          ),
          if (widget.isGuest)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _GuestCard(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 0),
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}

class _TopicStrip extends StatelessWidget {
  final List<String> topics;
  final int selected;
  final ValueChanged<int> onSelected;

  const _TopicStrip({
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: AppColors.card,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final active = index == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: active ? AppColors.wine : AppColors.wineBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.wine : AppColors.border,
                ),
              ),
              child: Text(
                topics[index],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.wine,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: topics.length,
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final _FeedArticle article;
  final VoidCallback onTap;

  const _FeaturedCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArticleVisual(article: article),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallBadge(label: article.category, color: article.accent),
                    const SizedBox(height: 10),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: article.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${article.likes}',
                          style: TextStyle(
                            color: article.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.bookmark_border,
                          size: 22,
                          color: article.accent,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.share_outlined,
                          size: 22,
                          color: article.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleVisual extends StatelessWidget {
  final _FeedArticle article;

  const _ArticleVisual({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            article.accent.withValues(alpha: .12),
            article.accent.withValues(alpha: .28),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            bottom: -18,
            child: Icon(
              Icons.account_balance,
              size: 154,
              color: Colors.white.withValues(alpha: .48),
            ),
          ),
          Positioned(
            right: -14,
            top: -18,
            child: Icon(
              Icons.show_chart,
              size: 118,
              color: Colors.white.withValues(alpha: .32),
            ),
          ),
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: article.accent.withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(article.icon, color: article.accent, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _JindungoBanner extends StatelessWidget {
  final VoidCallback onPressed;

  const _JindungoBanner({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(22, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [Color(0xFF681333), Color(0xFF4C0D25)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: 16,
            child: Transform.rotate(
              angle: .18,
              child: Icon(
                Icons.local_fire_department_outlined,
                color: Colors.white.withValues(alpha: .18),
                size: 58,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF7A45),
                    size: 19,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Textos com Jindungo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 220,
                child: Text(
                  'Opinião crua e directa sobre as falhas sistémicas da economia nacional.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 26,
                child: OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 26),
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Saber mais'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodcastBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PodcastBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 92,
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: AppColors.green,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Podcast',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Mulheres nos negócios angolanos',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: AppColors.wine, size: 34),
          ],
        ),
      ),
    );
  }
}

class _VideoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _VideoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 96,
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 66,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF17343A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vídeo',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Inflação em Angola: causas históricas e impacto actual',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: AppColors.wine, size: 34),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onStart;

  const _QuizCard({required this.quiz, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textMain,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quiz.isNew ? 'Novo' : quiz.difficulty.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Iniciar',
                    style: TextStyle(
                      color: AppColors.wine,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.wine,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quiz.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const Spacer(),
              Text(
                '${quiz.questionCount} perguntas · Criado por ${quiz.author}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _GuestCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_add_alt_1_outlined,
            color: AppColors.wine,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cria uma conta para guardar artigos e acompanhar quizzes.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            height: 34,
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('Criar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeedArticle {
  final String category;
  final String title;
  final String meta;
  final Color accent;
  final int likes;
  final IconData icon;

  const _FeedArticle({
    required this.category,
    required this.title,
    required this.meta,
    required this.accent,
    required this.likes,
    required this.icon,
  });
}
