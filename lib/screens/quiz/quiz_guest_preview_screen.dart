import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'quiz_models.dart';

class QuizGuestPreviewScreen extends StatelessWidget {
  final QuizModel quiz;
  const QuizGuestPreviewScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Entrar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Criar conta', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.iconBg,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          quiz.categoryName.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    quiz.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                        top: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('${quiz.questionCount} PERGUNTAS',
                            Icons.quiz_outlined),
                        _divider(),
                        _statItem('NÍVEL ${quiz.difficulty.toUpperCase()}',
                            Icons.bar_chart_outlined),
                        _divider(),
                        _statItem(
                          quiz.estimatedMinutes > 0
                              ? '${quiz.estimatedMinutes} MIN'
                              : '--:--',
                          Icons.timer_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // About
                  const Text('Sobre este Quiz',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(quiz.description ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6)),
                  const SizedBox(height: 24),
                  // Preview (first question, blurred)
                  const Text('Pré-visualização',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1/1',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.iconBg,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('EXEMPLO',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          quiz.questions.isNotEmpty
                              ? quiz.questions.first.text
                              : 'Qual foi o impacto da reforma de 1999?',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        // Blurred options
                        ...List.generate(
                          4,
                          (i) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.white
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: i == 0 &&
                                          quiz.questions.isNotEmpty &&
                                          quiz.questions.first.options
                                              .isNotEmpty
                                      ? Text(
                                          quiz.questions.first.options[0].text,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textPrimary),
                                        )
                                      : Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.border,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Lock CTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentMid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppColors.primary, size: 32),
                        const SizedBox(height: 10),
                        const Text(
                          'Inicia sessão para jogar',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cria uma conta gratuita para aceder a todos os quizzes e ver o teu ranking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.signup),
                            child: const Text('Criar conta grátis'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 24, color: AppColors.border);
}
