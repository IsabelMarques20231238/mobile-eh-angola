import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_ai_review_screen.dart';
import 'quiz_detail_screen.dart';
import 'quiz_models.dart';

class MyQuizzesScreen extends StatefulWidget {
  const MyQuizzesScreen({super.key});

  @override
  State<MyQuizzesScreen> createState() => _MyQuizzesScreenState();
}

class _MyQuizzesScreenState extends State<MyQuizzesScreen> {
  final _service = QuizService(ApiClient.instance);
  final _scrollCtrl = ScrollController();

  List<QuizModel> _quizzes = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _selectedTab = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  static final Set<int> _pendingDeletionIds = {};

  // Admin/super quizzes are published instantly — no PENDING state for them
  List<String?> get _tabStatuses {
    final base = <String?>[null, 'APPROVED', 'PENDING', 'REJECTED', 'DRAFT'];
    if (AuthState.instance.isAdmin) base.remove('PENDING');
    return base;
  }

  List<String> get _tabLabels {
    final base = ['Todos', 'Publicado', 'Em revisão', 'Rejeitado', 'Rascunho'];
    if (AuthState.instance.isAdmin) base.remove('Em revisão');
    return base;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 240 &&
        !_loadingMore &&
        !_loading &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  String? get _activeStatus => _tabStatuses[_selectedTab];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _currentPage = 1; _quizzes = []; });
    try {
      final result = await _service.getMyQuizzes(page: 1, status: _activeStatus);
      if (mounted) {
        setState(() {
          _quizzes = result.quizzes;
          _currentPage = result.currentPage;
          _lastPage = result.lastPage;
          _loading = false;
        });
        _cleanUpPendingDeletions(result.quizzes);
      }
    } on ApiException catch (e) {
      if (mounted) { setState(() { _error = e.message; _loading = false; }); }
    } catch (_) {
      if (mounted) { setState(() { _error = 'Não foi possível carregar os quizzes.'; _loading = false; }); }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.getMyQuizzes(page: _currentPage + 1, status: _activeStatus);
      if (mounted) {
        setState(() {
          _quizzes.addAll(result.quizzes);
          _currentPage = result.currentPage;
          _lastPage = result.lastPage;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loadingMore = false); }
    }
  }

  List<QuizModel> get _filtered {
    final status = _tabStatuses[_selectedTab];
    var items = status == null ? _quizzes : _quizzes.where((q) => q.status == status).toList();
    if (AuthState.instance.isAdmin) items = items.where((q) => q.status != 'PENDING').toList();
    return items;
  }

  int _countFor(int tabIndex) {
    final status = _tabStatuses[tabIndex];
    var items = status == null ? _quizzes : _quizzes.where((q) => q.status == status);
    if (AuthState.instance.isAdmin) items = items.where((q) => q.status != 'PENDING');
    return items.length;
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final ok = await showAppDialog(
      context,
      title: 'Eliminar quiz?',
      message: '"${quiz.title}" será eliminado permanentemente. Esta acção é irreversível.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      type: AppDialogType.danger,
    );
    if (!ok || !mounted) return;
    try {
      await _service.deleteQuiz(quiz.id);
      if (!mounted) return;
      showAppToast(context, 'Quiz eliminado com sucesso.', type: AppToastType.success);
      _load();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  Future<void> _requestDeletion(QuizModel quiz) async {
    final reason = await _showRequestDeletionDialog(quiz);
    if (reason == null || !mounted) return;
    // Optimistic update — disable button before the API call
    setState(() => _pendingDeletionIds.add(quiz.id));
    try {
      await _service.requestDeletion(quiz.id, reason);
      if (!mounted) return;
      showAppToast(context, 'Pedido de eliminação enviado.', type: AppToastType.success);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _pendingDeletionIds.remove(quiz.id));
        showAppToast(context, e.message, type: AppToastType.error);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pendingDeletionIds.remove(quiz.id));
        showAppToast(context, 'Não foi possível enviar o pedido. Tenta novamente.', type: AppToastType.error);
      }
    }
  }

  void _cleanUpPendingDeletions(List<QuizModel> quizzes) {
    if (_pendingDeletionIds.isEmpty) return;
    for (final id in List.of(_pendingDeletionIds)) {
      QuizModel? q;
      for (final quiz in quizzes) {
        if (quiz.id == id) { q = quiz; break; }
      }
      if (q == null) {
        // Quiz was deleted (admin approved deletion request)
        _pendingDeletionIds.remove(id);
      } else if (q.deletionRequest != null) {
        // API included deletion_request — check if it's still PENDING
        if (!q.hasPendingDeletionRequest) _pendingDeletionIds.remove(id);
      } else {
        // API list doesn't include deletion_request — fetch detail to confirm
        _fetchAndCheckDeletion(id);
      }
    }
  }

  Future<void> _fetchAndCheckDeletion(int quizId) async {
    try {
      final detail = await _service.getQuiz(quizId);
      // While PENDING the backend returns deletion_request: {status:'PENDING'} → hasPendingDeletionRequest = true → keep.
      // After REJECTED the backend returns deletion_request: null → hasPendingDeletionRequest = false → remove.
      if (!detail.hasPendingDeletionRequest && mounted) {
        setState(() => _pendingDeletionIds.remove(quizId));
      }
    } catch (_) {}
  }

  Future<String?> _showRequestDeletionDialog(QuizModel quiz) {
    final controller = TextEditingController();
    String? validationError;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final c = ctx.c;
          return AlertDialog(
            backgroundColor: c.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Pedir eliminação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textMain,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'Indica o motivo para solicitar a eliminação de "${quiz.title}".',
                  style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 14, color: c.textMain),
                  decoration: InputDecoration(
                    hintText: 'Motivo (obrigatório)',
                    hintStyle: TextStyle(fontSize: 13, color: c.muted),
                    filled: true,
                    fillColor: c.bg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: validationError != null ? AppColors.error : c.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.wine),
                    ),
                    errorText: validationError,
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
              ],
            ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setDialogState(() => validationError = 'O motivo é obrigatório.');
                    return;
                  }
                  Navigator.pop(ctx, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('Solicitar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(QuizModel quiz) {
    final isDraft = quiz.status == 'DRAFT';
    final isRejected = quiz.status == 'REJECTED';
    final isPending = quiz.status == 'PENDING';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (isDraft || isRejected) {
            return QuizAIReviewScreen(
              quiz: quiz,
              isAiGenerated: quiz.isAiGenerated,
              popOnExit: true,
            );
          }
          if (isPending) {
            return QuizAIReviewScreen(
              quiz: quiz,
              isAiGenerated: quiz.isAiGenerated,
              readOnly: true,
              popOnExit: true,
            );
          }
          return QuizDetailScreen(quiz: quiz);
        },
      ),
    ).then((_) { if (mounted) _load(); });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Os meus Quizzes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textMain),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          _buildTabBar(c),
          Divider(height: 1, color: c.border),
          Expanded(child: _buildBody(c)),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppAdaptiveColors c) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _tabLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final active = _selectedTab == i;
          final count = _loading ? 0 : _countFor(i);
          final showCount = i > 0 && !_loading && count > 0;
          return GestureDetector(
            onTap: () {
              if (_selectedTab == i) return;
              setState(() => _selectedTab = i);
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppColors.wine : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tabLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? c.wine : c.textSecondary,
                    ),
                  ),
                  if (showCount) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: active ? AppColors.wine : c.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : c.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AppAdaptiveColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: c.muted, size: 36),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, color: c.muted, size: 40),
              const SizedBox(height: 14),
              Text(
                'Nenhum quiz aqui.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textMain),
              ),
              const SizedBox(height: 6),
              Text(
                'Os quizzes que criares aparecerão aqui.',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        itemCount: items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final quiz = items[i];
          final isAdmin = AuthState.instance.isAdmin;
          return _MyQuizCard(
            quiz: quiz,
            isAdmin: isAdmin,
            hasPendingDeletion: quiz.hasPendingDeletionRequest ||
                _pendingDeletionIds.contains(quiz.id),
            onView: () => _openDetail(quiz),
            onDelete: () => _deleteQuiz(quiz),
            onRequestDeletion: () => _requestDeletion(quiz),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MyQuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isAdmin;
  final bool hasPendingDeletion;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onRequestDeletion;

  const _MyQuizCard({
    required this.quiz,
    required this.isAdmin,
    required this.hasPendingDeletion,
    required this.onView,
    required this.onDelete,
    required this.onRequestDeletion,
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  (Color, String) get _statusInfo => switch (quiz.status) {
        'APPROVED' => (const Color(0xFF22C55E), 'Publicado'),
        'PENDING'  => (const Color(0xFFF59E0B), 'Em revisão'),
        'REJECTED' => (AppColors.error, 'Rejeitado'),
        _          => (const Color(0xFF6B7280), 'Rascunho'),
      };

  Color _diffColor(QuizDifficulty d) => switch (d) {
        QuizDifficulty.easy   => const Color(0xFF22C55E),
        QuizDifficulty.medium => const Color(0xFFF59E0B),
        QuizDifficulty.hard   => const Color(0xFFEF4444),
      };

  String? _timeAgo(DateTime? dt) {
    if (dt == null) return null;
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 365) return 'há ${d.inDays ~/ 365} ano${d.inDays ~/ 365 > 1 ? 's' : ''}';
    if (d.inDays >= 30)  return 'há ${d.inDays ~/ 30} ${d.inDays ~/ 30 > 1 ? 'meses' : 'mês'}';
    if (d.inDays >= 1)   return 'há ${d.inDays} dia${d.inDays > 1 ? 's' : ''}';
    if (d.inHours >= 1)  return 'há ${d.inHours} hora${d.inHours > 1 ? 's' : ''}';
    if (d.inMinutes >= 1) return 'há ${d.inMinutes} min';
    return 'agora mesmo';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final status = quiz.status;
    final (statusColor, statusLabel) = _statusInfo;
    final diffColor = _diffColor(quiz.difficultyEnum);

    final isApproved = status == 'APPROVED';
    final isPending  = status == 'PENDING';
    final isRejected = status == 'REJECTED';
    final isDraft    = status == 'DRAFT';

    final reviewInfo = quiz.reviewInfo;
    final reviewerName = reviewInfo?.reviewedBy?['name'] as String?;
    final reviewedAt   = reviewInfo?.reviewedAtHuman;
    final createdAgo   = _timeAgo(quiz.createdAt);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Badges ──────────────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(
                      text: quiz.categoryName.toUpperCase(),
                      fg: AppColors.wine,
                      bg: AppColors.wineBg,
                    ),
                    _Badge(
                      text: quiz.difficultyEnum.label.toUpperCase(),
                      fg: diffColor,
                      bg: diffColor.withValues(alpha: 0.1),
                    ),
                    if (quiz.isAiGenerated)
                      _Badge(
                        text: '+ IA',
                        fg: AppColors.wine,
                        bg: AppColors.wineBg,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  quiz.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textMain,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Stats ─────────────────────────────────────────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _StatChip(
                      icon: Icons.help_outline_rounded,
                      label: '${quiz.questionCount} perguntas',
                      color: c.muted,
                    ),
                    if (quiz.estimatedMinutes > 0)
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${quiz.estimatedMinutes} min',
                        color: c.muted,
                      ),
                    if (createdAgo != null)
                      Text(
                        createdAgo,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Status + reviewer ─────────────────────────────────────────
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (reviewerName != null && reviewedAt != null)
                      Text(
                        '  ·  por $reviewerName · $reviewedAt',
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                  ],
                ),

                // ── Rejection reason ──────────────────────────────────────────
                if (isRejected && reviewInfo?.rejectionReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motivo da rejeição:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          reviewInfo!.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Pending message ───────────────────────────────────────────
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const _SpinningHourglass(),
                      const SizedBox(width: 6),
                      Text(
                        'A aguardar revisão editorial',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          // Admin can delete PENDING quizzes directly; authors cannot act on them.
          if (!isPending || isAdmin) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  // Primary action
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onView,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.wine,
                        side: BorderSide(color: c.wine),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: Text(
                        isApproved || isPending
                            ? 'Ver quiz'
                            : isRejected
                                ? 'Editar e resubmeter'
                                : 'Continuar a editar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete action:
                                  // ADMIN/SUPER_ADMIN → sempre "Eliminar" direto
                  // AUTHOR + DRAFT ou REJECTED → "Eliminar" direto
                  // AUTHOR + APPROVED → "Pedir eliminação" (desabilitado se já tiver pedido activo)
                  Expanded(
                    child: (isAdmin || isDraft || isRejected)
                        ? ElevatedButton(
                            onPressed: onDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Eliminar'),
                          )
                        : OutlinedButton(
                            onPressed: hasPendingDeletion ? null : onRequestDeletion,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              disabledForegroundColor: const Color(0xFF9CA3AF),
                              side: BorderSide(
                                color: hasPendingDeletion
                                    ? const Color(0xFFD1D5DB)
                                    : AppColors.error,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            child: Text(hasPendingDeletion
                                ? 'Pedido enviado'
                                : 'Pedir eliminação'),
                          ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 2),
        ],
      ),
    );

    if (isPending && !isAdmin) {
      return GestureDetector(onTap: onView, child: card);
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _SpinningHourglass extends StatefulWidget {
  const _SpinningHourglass();

  @override
  State<_SpinningHourglass> createState() => _SpinningHourglassState();
}

class _SpinningHourglassState extends State<_SpinningHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(
        Icons.hourglass_top_rounded,
        size: 14,
        color: Color(0xFF92400E),
      ),
    );
  }
}
