import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';
import 'quiz_models.dart';
import 'quiz_question_screen.dart';
import 'quiz_ranking_screen.dart';

class QuizDetailScreen extends StatelessWidget {
  final Quiz quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalhes do Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges
            Row(
              children: [
                _badge(quiz.difficulty.label.toUpperCase(), const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                const SizedBox(width: 8),
                _badge(quiz.category.label.toUpperCase(), AppColors.primary, AppColors.iconBg),
              ],
            ),
            const SizedBox(height: 12),
            // Título
            Text(
              quiz.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 12),
            // Autor
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    quiz.author.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(quiz.authorRole, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  _statItem(quiz.questionCount.toString(), 'PERGUNTAS'),
                  _divider(),
                  _statItem(quiz.difficulty.label, 'NÍVEL'),
                  _divider(),
                  _statItem(quiz.avgTime, 'TEMPO MÉDIO'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Sobre
            const Text('Sobre este Quiz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(quiz.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 20),
            // Tentativas anteriores
            if (quiz.attempted) ...[
              const Text('As tuas tentativas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ...quiz.attempts.asMap().entries.map((entry) {
                final i = entry.key;
                final attempt = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Text('Tentativa ${i + 1}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                      Text('${attempt.score}/${attempt.total}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                      Text(attempt.time, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: attempt.passed ? AppColors.successLight : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          attempt.passed ? 'SUCESSO' : 'FALHOU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: attempt.passed ? AppColors.success : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Melhor pontuação: ${quiz.bestAttempt!.score}/${quiz.bestAttempt!.total}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
            ],
            // Top 3 ranking preview
            const Text('TOP 3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1)),
            const SizedBox(height: 10),
            ...QuizData.globalRanking.take(3).map((r) => _rankingRow(r)),
            const SizedBox(height: 28),
            // Botões
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _startQuiz(context),
                child: Text(quiz.attempted ? 'Refazer' : 'Iniciar Quiz'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizRankingScreen(quiz: quiz)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Ver Ranking', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5)),
    );
  }

  Future<void> _startQuiz(BuildContext context) async {
    try {
      final fullQuiz = quiz.questions.isEmpty ? await ContentService(ApiClient.instance).getQuiz(quiz.id) : quiz;
      if (!context.mounted) return;
      if (fullQuiz.questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este quiz ainda nao tem perguntas disponiveis.')));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizQuestionScreen(quiz: fullQuiz)));
    } on ApiException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);

  Widget _rankingRow(RankingEntry r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: r.isCurrentUser ? AppColors.iconBg : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: r.isCurrentUser ? AppColors.primary.withOpacity(0.3) : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text('#${r.position}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(r.avatarInitials ?? r.name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          Text('${r.score}/${r.total}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
