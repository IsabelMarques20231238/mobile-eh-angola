import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_detail_screen.dart';
import 'quiz_models.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  QuizDifficulty? _selectedDifficulty;
  List<Quiz> get _filteredQuizzes {
    if (_selectedDifficulty == null) return QuizData.quizzes;
    return QuizData.quizzes
        .where((quiz) => quiz.difficulty == _selectedDifficulty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quiz',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _buildDifficultyFilters(),
          Expanded(
            child: _filteredQuizzes.isEmpty
                ? const _StateMessage(title: 'Ainda nao ha quizzes publicados')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filteredQuizzes.length,
                    itemBuilder: (context, i) =>
                        _buildQuizCard(_filteredQuizzes[i]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 2),
    );
  }

  Widget _buildDifficultyFilters() {
    final filters = [null, ...QuizDifficulty.values];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final label = filter == null ? 'Todos' : filter.label;
          final isSelected = _selectedDifficulty == filter;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDifficulty = filter;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return GestureDetector(
      onTap: () => _openQuiz(quiz),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DifficultyBadge(difficulty: quiz.difficulty),
                const SizedBox(width: 6),
                _CategoryBadge(category: quiz.category),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${quiz.questionCount} perguntas - Criado por ${quiz.author}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Iniciar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: quiz)),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final QuizDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get color {
    switch (difficulty) {
      case QuizDifficulty.facil:
        return AppColors.success;
      case QuizDifficulty.medio:
        return const Color(0xFFF59E0B);
      case QuizDifficulty.dificil:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final QuizCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String title;

  const _StateMessage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.quiz_outlined,
              color: AppColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
