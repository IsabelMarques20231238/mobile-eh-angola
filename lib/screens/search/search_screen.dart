import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../theme/app_theme.dart';
import '../articles/article_detail_screen.dart';
import '../forum/forum_topic_detail_screen.dart';
import '../quiz/quiz_detail_screen.dart';
import '../quiz/quiz_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController(text: 'inflação');

  final articles = const [
    _ArticleData(
      'HISTÓRIA',
      'A Hiperinflação Angolana: Memórias do Kwanza',
      '12 min de leitura · Jul 2023',
      Color(0xFF8E6A38),
      Icons.monetization_on_outlined,
    ),
    _ArticleData(
      'MACROECONOMIA',
      'Mecanismos de Controle da Inflação em 1999',
      '8 min de leitura · Out 2023',
      Color(0xFF1C2C44),
      Icons.trending_up,
    ),
    _ArticleData(
      'ANÁLISE',
      'Impacto Social da Desvalorização Cambial',
      '15 min de leitura · Jan 2024',
      Color(0xFF8A6E4B),
      Icons.menu_book,
    ),
  ];
  final quizzes = const [
    _CompactData(
      'Mestre da Inflação',
      '10 Questões · Nível Médio',
      AppColors.wine,
    ),
    _CompactData(
      'Economia de Guerra',
      '5 Questões · Nível Difícil',
      AppColors.textSecondary,
    ),
  ];
  final forums = const [
    _ForumData(
      'JD',
      'Alguém tem dados sobre a inflação em 1996?',
      '12 · Há 2h',
    ),
    _ForumData(
      'AS',
      'Diferença entre inflação real e percebida no Lobito',
      '4 · Ontem',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _matches(String value) =>
      value.toLowerCase().contains(controller.text.toLowerCase().trim());

  @override
  Widget build(BuildContext context) {
    final visibleArticles = articles
        .where((a) => _matches(a.title) || _matches(a.category))
        .toList();
    final visibleQuizzes = quizzes.where((q) => _matches(q.title)).toList();
    final visibleForums = forums.where((f) => _matches(f.title)).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 15,
                  ),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 15),
                          onPressed: () => setState(controller.clear),
                        ),
                  hintText: 'Pesquisar...',
                  filled: true,
                  fillColor: const Color(0xFFF6F4F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.wine,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SectionTitle('ARTIGOS (${visibleArticles.length})'),
          const SizedBox(height: 10),
          ...visibleArticles.map((item) => _ArticleResult(data: item)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Ver mais artigos',
                style: TextStyle(
                  color: AppColors.wine,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('QUIZ (${visibleQuizzes.length})'),
          const SizedBox(height: 8),
          ...visibleQuizzes.map((item) => _CompactResult(data: item)),
          const SizedBox(height: 18),
          _SectionTitle('FÓRUM (${visibleForums.length})'),
          const SizedBox(height: 8),
          ...visibleForums.map((item) => _ForumResult(data: item)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .8,
    ),
  );
}

class _ArticleResult extends StatelessWidget {
  final _ArticleData data;
  const _ArticleResult({required this.data});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(
            article: featuredArticleDetails.first,
          ),
        ),
      ),
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        color: AppColors.card,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 50,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                data.icon,
                color: Colors.white.withValues(alpha: .8),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.category,
                    style: const TextStyle(
                      color: AppColors.wine,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.meta,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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

class _CompactResult extends StatelessWidget {
  final _CompactData data;
  const _CompactResult({required this.data});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizDetailScreen(quiz: QuizData.quizzes.first),
      ),
    ),
    child: Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(left: BorderSide(color: data.color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_circle_outline,
            color: AppColors.wine,
            size: 17,
          ),
        ],
      ),
    ),
  );
}

class _ForumResult extends StatelessWidget {
  final _ForumData data;
  const _ForumResult({required this.data});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForumTopicDetailScreen(
          topic: buildMockTopics().first,
        ),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.textSecondary,
            child: Text(
              data.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.meta,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArticleData {
  final String category, title, meta;
  final Color color;
  final IconData icon;
  const _ArticleData(
    this.category,
    this.title,
    this.meta,
    this.color,
    this.icon,
  );
}

class _CompactData {
  final String title, subtitle;
  final Color color;
  const _CompactData(this.title, this.subtitle, this.color);
}

class _ForumData {
  final String initials, title, meta;
  const _ForumData(this.initials, this.title, this.meta);
}
