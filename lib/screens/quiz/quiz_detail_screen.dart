import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';
import 'quiz_question_screen.dart';
import 'quiz_ranking_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final _service = QuizService(ApiClient.instance);

  MyAttemptsResponse? _myAttempts;
  List<RankingItemModel> _top3 = [];
  bool _loadingAttempts = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isAuth = AuthState.instance.isAuthenticated;
    await Future.wait([
      if (isAuth) _fetchAttempts(),
      _fetchTop3(),
    ]);
  }

  Future<void> _fetchAttempts() async {
    try {
      final resp = await _service.getMyAttempts(widget.quiz.id);
      if (mounted) setState(() { _myAttempts = resp; _loadingAttempts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAttempts = false);
    }
  }

  Future<void> _fetchTop3() async {
    try {
      final result = await _service.getQuizRanking(widget.quiz.id);
      if (mounted) setState(() => _top3 = result.ranking.take(3).toList());
    } catch (_) {}
  }

  Future<void> _startQuiz() async {
    if (!AuthState.requireAuth(context)) return;
    setState(() => _starting = true);
    try {
      final full = widget.quiz.questions.isNotEmpty
          ? widget.quiz
          : await _service.getQuiz(widget.quiz.id);
      if (!mounted) return;
      if (full.questions.isEmpty) {
        showAppToast(context, 'Este quiz ainda não tem perguntas.', type: AppToastType.warning);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizQuestionScreen(quiz: full)),
      ).then((_) {
        if (mounted) _loadData();
      });
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final c = context.c;
    final diff = quiz.difficultyEnum;

    Color diffColor = switch (diff) {
      QuizDifficulty.easy   => const Color(0xFF22C55E),
      QuizDifficulty.medium => const Color(0xFFF59E0B),
      QuizDifficulty.hard   => const Color(0xFFEF4444),
    };

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalhes do Quiz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                _badge(quiz.difficulty.toUpperCase(), diffColor, diffColor.withValues(alpha: 0.1)),
                const SizedBox(width: 8),
                _badge(quiz.categoryName.toUpperCase(), AppColors.wine, AppColors.wineBg),
                if (quiz.isAiGenerated) ...[
                  const SizedBox(width: 8),
                  _badge('IA', AppColors.wine, AppColors.wineBg),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              quiz.title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.textMain,
                  height: 1.3),
            ),
            const SizedBox(height: 12),
            // Author
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.wine,
                  child: Text(
                    quiz.authorName.isNotEmpty ? quiz.authorName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.authorName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textMain)),
                    Text(quiz.authorDisplayRole,
                        style: TextStyle(fontSize: 11, color: c.muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats
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
                  _statItem(quiz.questionCount.toString(), 'PERGUNTAS', c),
                  Container(width: 1, height: 32, color: c.border),
                  _statItem(quiz.difficulty, 'NÍVEL', c),
                  Container(width: 1, height: 32, color: c.border),
                  _statItem(
                    quiz.estimatedMinutes > 0
                        ? '${quiz.estimatedMinutes} min'
                        : '--',
                    'DURAÇÃO',
                    c,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // About
            Text('Sobre este Quiz',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textMain)),
            const SizedBox(height: 8),
            Text(
              quiz.description ?? 'Sem descrição.',
              style: TextStyle(
                  fontSize: 14, color: c.textSecondary, height: 1.6),
            ),
            // My attempts
            if (AuthState.instance.isAuthenticated) ...[
              const SizedBox(height: 20),
              if (_loadingAttempts)
                const Center(child: CircularProgressIndicator())
              else if (_myAttempts != null && _myAttempts!.hasAttempted) ...[
                Text('As tuas tentativas',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textMain)),
                const SizedBox(height: 10),
                ..._myAttempts!.attempts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  final passed = a.success;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Text('Tentativa ${i + 1}',
                            style: TextStyle(
                                fontSize: 13, color: c.textSecondary)),
                        Text(' · ',
                            style: TextStyle(color: c.muted)),
                        Text('${a.score}/${a.totalQuestions}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textMain)),
                        Text(' · ',
                            style: TextStyle(color: c.muted)),
                        Text(formatSeconds(a.timeSpentSeconds),
                            style: TextStyle(
                                fontSize: 13, color: c.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: passed
                                ? AppColors.successLight
                                : AppColors.errorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            passed ? 'SUCESSO' : 'FALHOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: passed
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_myAttempts!.firstAttempt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Melhor pontuação: ${_myAttempts!.firstAttempt!.percentage.round()}%',
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ),
              ],
            ],
            // Top 3 ranking preview
            if (_top3.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('TOP 3',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.muted,
                      letterSpacing: 1)),
              const SizedBox(height: 10),
              ..._top3.map((r) => _rankingRow(r, c)),
            ],
            const SizedBox(height: 28),
            // Start button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _starting ? null : _startQuiz,
                child: _starting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_myAttempts?.hasAttempted == true
                        ? 'Jogar de novo'
                        : 'Iniciar Quiz'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QuizRankingScreen(quiz: quiz)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.wine),
                  foregroundColor: c.wine,
                ),
                child: const Text('Ver Ranking',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5)),
    );
  }

  Widget _statItem(String value, String label, AppAdaptiveColors c) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textMain)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: c.muted, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _rankingRow(RankingItemModel r, AppAdaptiveColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Text('#${r.position}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.muted)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.wine,
            child: Text(r.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.userName,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textMain)),
          ),
          if (r.timeSpentSeconds != null) ...[
            Icon(Icons.timer_outlined, size: 12, color: c.muted),
            const SizedBox(width: 3),
            Text(
              formatSeconds(r.timeSpentSeconds),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(width: 8),
          ],
          Text('${r.score}/${r.totalQuestions}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.wine)),
        ],
      ),
    );
  }
}
