import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'quiz_models.dart';
import 'quiz_ranking_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final QuizAttemptModel attempt;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  Color get _performanceColor {
    if (attempt.percentage >= 70) return AppColors.success;
    if (attempt.percentage >= 50) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  String get _performanceLabel =>
      attempt.performanceMessage ?? attempt.performance ?? _defaultLabel;

  String get _defaultLabel {
    if (attempt.percentage >= 90) return 'Excelente!';
    if (attempt.percentage >= 70) return 'Bom Trabalho!';
    if (attempt.percentage >= 50) return 'Continua a tentar!';
    return 'Não desistas!';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final errors = attempt.totalQuestions - attempt.correctAnswers;
    final relatedArticles = [
      if (quiz.article != null) quiz.article!,
      ...quiz.relatedArticles,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: c.textMain),
          onPressed: () =>
              Navigator.popUntil(context, (r) => r.isFirst || r.settings.name != null),
        ),
        title: Text(
          'Resultado do Quiz',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textMain),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: c.textMain),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            // Performance badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _performanceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _performanceLabel,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _performanceColor),
              ),
            ),
            const SizedBox(height: 18),
            // Score
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${attempt.correctAnswers}',
                    style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: c.textMain,
                        height: 1),
                  ),
                  TextSpan(
                    text: ' /${attempt.totalQuestions}',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Perguntas correctas',
                style: TextStyle(fontSize: 14, color: c.muted)),
            const SizedBox(height: 20),
            // Stats row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                      value: formatSeconds(attempt.timeSpentSeconds),
                      label: 'TEMPO'),
                  Container(width: 1, height: 32, color: c.border),
                  _StatItem(value: '$errors', label: 'ERROS'),
                  if (attempt.pointsEarned > 0) ...[
                    Container(width: 1, height: 32, color: c.border),
                    _StatItem(
                        value: '+${attempt.pointsEarned}', label: 'JINDUNGO'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Text('Resultado',
                    style:
                        TextStyle(fontSize: 13, color: c.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: attempt.percentage / 100,
                      backgroundColor: c.border,
                      valueColor:
                          AlwaysStoppedAnimation(_performanceColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${attempt.percentage.round()}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _performanceColor),
                ),
              ],
            ),
            // First attempt bonus
            if (attempt.isFirstAttempt == true) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Primeira tentativa! Ganhaste ${attempt.pointsEarned} pontos Jindungo.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Recommended content
            if (relatedArticles.isNotEmpty) ...[
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CONTEÚDO RECOMENDADO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c.muted,
                      letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              ...relatedArticles.map((a) => _ArticleCard(article: a)),
            ],
            const SizedBox(height: 28),
            // Ver Ranking
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QuizRankingScreen(quiz: quiz)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Ver Ranking'),
              ),
            ),
            const SizedBox(height: 10),
            // Refazer Quiz
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.wine),
                  foregroundColor: AppColors.wine,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Refazer Quiz'),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Text(
                'Partilhar resultado',
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textMain)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: c.muted, letterSpacing: 0.5)),
      ],
    );
  }
}

// ── Article card ──────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = article['title'] as String? ?? 'Artigo';
    final badge = article['content_type'] as String? ??
        article['category'] as String? ??
        article['badge'] as String?;
    final imageUrl = article['image_url'] as String? ??
        article['thumbnail'] as String? ??
        article['cover_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _iconPlaceholder(),
                    )
                  : _iconPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Text(
                      badge.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: c.wine,
                          letterSpacing: 0.5),
                    ),
                  if (badge != null) const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textMain,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios, size: 14, color: c.muted),
          ),
        ],
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      color: AppColors.wineBg,
      alignment: Alignment.center,
      child: const Icon(Icons.article_outlined, color: AppColors.wine, size: 28),
    );
  }
}
