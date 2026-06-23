import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'quiz_models.dart';
import 'quiz_ranking_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final int correctCount;
  final int totalQuestions;
  final int timeSeconds;
  final int errorsCount;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeSeconds,
    required this.errorsCount,
  });

  String get _formattedTime {
    final m = timeSeconds ~/ 60;
    final s = timeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _percentage => correctCount / totalQuestions;

  String get _performanceLabel {
    if (_percentage >= 0.9) return 'Excelente!';
    if (_percentage >= 0.7) return 'Bom Trabalho!';
    if (_percentage >= 0.5) return 'Continua a tentar!';
    return 'Não desistas!';
  }

  Color get _performanceColor {
    if (_percentage >= 0.7) return AppColors.success;
    if (_percentage >= 0.5) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst || r.settings.name != null),
        ),
        title: const Text('Resultado do Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Performance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _performanceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _performanceLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _performanceColor),
              ),
            ),
            const SizedBox(height: 20),
            // Score grande
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$correctCount',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: _performanceColor,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' /$totalQuestions',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Perguntas correctas', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            // Barra de progresso
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _percentage,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation(_performanceColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Resultado ${(_percentage * 100).round()}%',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(_formattedTime, 'TEMPO'),
                  _divider(),
                  _statItem('$errorsCount', 'ERROS'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Conteúdo recomendado
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Conteúdo Recomendado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),
            ...QuizData.recommended.map((c) => _RecommendedCard(content: c)),
            const SizedBox(height: 24),
            // Botões
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => QuizRankingScreen(quiz: quiz)),
                ),
                child: const Text('Ver Ranking'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Refazer Quiz', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Partilhar resultado', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);
}

class _RecommendedCard extends StatelessWidget {
  final RecommendedContent content;
  const _RecommendedCard({required this.content});

  IconData get _icon {
    switch (content.type) {
      case 'capitulo': return Icons.menu_book_outlined;
      case 'leitura_rapida': return Icons.flash_on_outlined;
      case 'video': return Icons.play_circle_outline;
      default: return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.subtitle.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  content.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
