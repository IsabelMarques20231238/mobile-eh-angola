import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../main.dart' show routeObserver;
import '../../screens/notifications/notifications_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../admin/create_quiz_screen.dart';
import 'quiz_detail_screen.dart';
import 'quiz_models.dart';
import 'quiz_my_quizzes_screen.dart';
import 'quiz_ranking_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen>
    with RouteAware {
  final _service = QuizService(ApiClient.instance);
  final _searchController = TextEditingController();

  QuizDifficulty? _selectedDifficulty;
  bool _showSearch = false;

  List<QuizModel> _quizzes = [];
  QuizModel? _featured;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  // Called when a route above this one was popped (e.g. came back from quiz detail).
  @override
  void didPopNext() => _load();

  // Called when this route was pushed (e.g. switching tabs via pushReplacementNamed).
  // initState already handles the initial load; this covers re-entries after replacement.
  @override
  void didPush() => _load();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.listQuizzes(
          difficulty: _selectedDifficulty?.label,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
        _service.getFeatured(),
      ]);
      if (!mounted) return;
      final all = results[0] as List<QuizModel>;
      final featured = results[1] as QuizModel?;
      setState(() {
        _featured = featured;
        _quizzes = all.where((q) => q.id != featured?.id).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Não foi possível carregar os quizzes.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: SafeArea(
          bottom: false,
          child: EhAngolaHeader(
            searchController: _searchController,
            showSearch: _showSearch,
            onSearchChanged: (_) => _load(),
            onSearchTap: () => setState(() => _showSearch = !_showSearch),
            onNotificationsTap: () => showNotificationsPanel(context),
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _selectedDifficulty,
            onSelected: (d) {
              setState(() => _selectedDifficulty = d);
              _load();
            },
          ),
          Expanded(child: _buildBody(c)),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 2),
    );
  }

  Widget _buildBody(AppAdaptiveColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.circleExclamation, color: c.muted, size: 28),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _QuizHero(
            onRanking: _openRanking,
            onCreate: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateQuizScreen()),
            ),
            onMyQuizzes: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyQuizzesScreen()),
            ),
          ),
          if (_featured != null) ...[
            const SizedBox(height: 12),
            _FeaturedCard(quiz: _featured!, onTap: () => _open(_featured!)),
          ],
          ..._quizzes.map((q) => _QuizCard(quiz: q, onTap: () => _open(q))),
          if (_quizzes.isEmpty && _featured == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.circleQuestion, color: c.muted, size: 30),
                    const SizedBox(height: 10),
                    Text(
                      'Nenhum quiz disponível',
                      style: TextStyle(fontSize: 14, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: quiz)),
    );
  }

  void _openRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizRankingScreen()),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final QuizDifficulty? selected;
  final ValueChanged<QuizDifficulty?> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filters = <QuizDifficulty?>[null, ...QuizDifficulty.values];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final label = f == null ? 'Tudo' : f.label;
          final active = selected == f;
          return GestureDetector(
            onTap: () => onSelected(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.wine : c.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.wine : c.border),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : c.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Featured card ─────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;
  const _FeaturedCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.wine,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'NOVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              quiz.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${quiz.questionCount} perguntas · Nível ${quiz.difficulty}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'Iniciar',
                style: TextStyle(
                  color: AppColors.wine,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz card ─────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;
  const _QuizCard({required this.quiz, required this.onTap});

  Color _diffColor(QuizDifficulty d) => switch (d) {
        QuizDifficulty.easy   => const Color(0xFF22C55E),
        QuizDifficulty.medium => const Color(0xFFF59E0B),
        QuizDifficulty.hard   => const Color(0xFFEF4444),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final diff = _diffColor(quiz.difficultyEnum);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                  text: quiz.difficulty.toUpperCase(),
                  fg: diff,
                  bg: diff.withValues(alpha: 0.1),
                ),
                const Spacer(),
                _Badge(
                  text: quiz.categoryName.toUpperCase(),
                  fg: AppColors.wine,
                  bg: AppColors.wineBg,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textMain,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${quiz.questionCount} perguntas · Por ${quiz.authorName}',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (quiz.hasAttempted) ...[
                  const FaIcon(FontAwesomeIcons.circleCheck, size: 13, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(
                    'Melhor: ${quiz.userBestScore?.round() ?? 0}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ] else
                  Text('Não tentado', style: TextStyle(fontSize: 12, color: c.muted)),
                const Spacer(),
                Text(
                  'Iniciar',
                  style: TextStyle(fontSize: 13, color: c.wine, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 3),
                FaIcon(FontAwesomeIcons.arrowRight, size: 12, color: c.wine),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const _Badge({required this.text, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5),
      ),
    );
  }
}

// ── Quiz hero ─────────────────────────────────────────────────────────────────

class _QuizHero extends StatelessWidget {
  final VoidCallback onRanking;
  final VoidCallback onCreate;
  final VoidCallback onMyQuizzes;

  const _QuizHero({
    required this.onRanking,
    required this.onCreate,
    required this.onMyQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.wine],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _QuizHeroGridPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: .2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFFBBF24)),
                              SizedBox(width: 5),
                              Text(
                                'QUIZ INTERATIVO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Quiz Interativo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Teste os seus conhecimentos sobre história, economia, política e muito mais. Aprenda, desafie-se e suba no ranking!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const _QuizIllustration(),
                ],
              ),
              const SizedBox(height: 18),
              ListenableBuilder(
                listenable: AuthState.instance,
                builder: (context, _) {
                  final canCreate = AuthState.instance.canCreateQuiz;
                  return Row(
                    children: [
                      Expanded(
                        child: _QuizHeroButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'Ranking\nglobal',
                          onTap: onRanking,
                        ),
                      ),
                      if (canCreate) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuizHeroButton(
                            icon: Icons.assignment_outlined,
                            label: 'Meus\nquizzes',
                            onTap: onMyQuizzes,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuizHeroButton(
                            icon: Icons.add_rounded,
                            label: 'Criar\nquiz',
                            onTap: onCreate,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizHeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuizHeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizIllustration extends StatelessWidget {
  const _QuizIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          // Clipboard body
          Positioned(
            bottom: 0,
            left: 6,
            child: Container(
              width: 68,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CheckRow(checked: true),
                  _CheckRow(checked: true),
                  _CheckRow(checked: false),
                  _CheckRow(checked: false),
                ],
              ),
            ),
          ),
          // Clipboard clip
          Positioned(
            bottom: 72,
            left: 28,
            child: Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ),
          // Graduation cap (on top of clipboard)
          const Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.school_rounded, color: AppColors.wine, size: 46),
            ),
          ),
          // Question mark — simple yellow, touching clipboard right edge
          const Positioned(
            bottom: 8,
            left: 68,
            child: Text(
              '?',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          // Decorative stars
          Positioned(
            top: 8,
            left: 0,
            child: Text('✦',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          ),
          Positioned(
            top: 32,
            right: 2,
            child: Text('✦',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 7)),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final bool checked;
  const _CheckRow({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: checked ? AppColors.wine : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: checked ? AppColors.wine : const Color(0xFFD1D5DB),
              width: 1.5,
            ),
          ),
          child: checked
              ? const Icon(Icons.check_rounded, size: 9, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.wine.withValues(alpha: 0.18)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizHeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .04)
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
