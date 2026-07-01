import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';
import 'quiz_my_quizzes_screen.dart';
import 'quiz_submitted_screen.dart';

class QuizAIReviewScreen extends StatefulWidget {
  final QuizModel quiz;
  final bool isAiGenerated;
  final bool readOnly;
  final bool popOnExit;
  const QuizAIReviewScreen({
    super.key,
    required this.quiz,
    this.isAiGenerated = true,
    this.readOnly = false,
    this.popOnExit = false,
  });

  @override
  State<QuizAIReviewScreen> createState() => _QuizAIReviewScreenState();
}

class _QuizAIReviewScreenState extends State<QuizAIReviewScreen> {
  final _service = QuizService(ApiClient.instance);
  List<_ReviewQ> _questions = [];
  int? _editingIndex;
  bool _submitting = false;
  bool _savingDraft = false;
  bool _loadingQuiz = false;
  String? _loadError;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiz.questions.isNotEmpty) {
      _questions = widget.quiz.questions.map(_ReviewQ.fromModel).toList();
    } else {
      _fetchQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    setState(() { _loadingQuiz = true; _loadError = null; });
    try {
      final full = await _service.getQuiz(widget.quiz.id);
      if (!mounted) return;
      setState(() => _questions = full.questions.map(_ReviewQ.fromModel).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Ocorreu um erro ao carregar o quiz.');
    } finally {
      if (mounted) setState(() => _loadingQuiz = false);
    }
  }

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildPayload(String status) {
    final quiz = widget.quiz;
    return {
      'title': quiz.title,
      if (quiz.description != null && quiz.description!.isNotEmpty)
        'description': quiz.description,
      'difficulty': quiz.difficulty,
      if (quiz.article?['id'] != null) 'article_id': quiz.article!['id'],
      if (quiz.category?['id'] != null) 'category_id': quiz.category!['id'],
      if (quiz.durationMinutes != null) 'duration_minutes': quiz.durationMinutes,
      'reward_points': quiz.rewardPoints,
      'status': status,
      'questions': _questions.map((rq) => {
        'text': rq.questionCtrl.text.trim(),
        'explanation': rq.explanationCtrl.text.trim().isEmpty
            ? null
            : rq.explanationCtrl.text.trim(),
        'options': List.generate(rq.optionCtrls.length, (i) => {
          'text': rq.optionCtrls[i].text.trim(),
          'is_correct': i == rq.correctIndex,
          'explanation': null,
        }),
      }).toList(),
    };
  }

  Future<void> _saveDraft() async {
    if (_savingDraft) return;
    setState(() => _savingDraft = true);
    try {
      await _service.updateQuiz(widget.quiz.id, _buildPayload('DRAFT'));
      if (!mounted) return;
      showAppToast(context, 'Rascunho guardado!', type: AppToastType.success);
      setState(() => _exiting = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyQuizzesScreen()),
          (route) => route.isFirst,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingDraft = false);
      showAppToast(context, e.message, type: AppToastType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingDraft = false);
      showAppToast(context, 'Não foi possível guardar. Tenta novamente.',
          type: AppToastType.error);
    }
  }

  bool get _hasUnsavedChanges =>
      !widget.readOnly &&
      (widget.quiz.status == 'DRAFT' || widget.quiz.status == 'REJECTED');

  void _handleBack() {
    if (!_hasUnsavedChanges) {
      setState(() => _exiting = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _showExitDialog();
  }

  Future<void> _showExitDialog() async {
    FocusScope.of(context).unfocus();
    final isRejected = widget.quiz.status == 'REJECTED';
    final isAdmin = AuthState.instance.isAdmin;
    final action = isAdmin ? 'publicado' : 'enviado para revisão';
    final result = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return Dialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected ? 'Sair sem guardar?' : 'Sair sem submeter?',
                  style: TextStyle(
                    color: c.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isRejected
                      ? 'As alterações que fizeste ainda não foram guardadas. Podes guardá-las como rascunho e reenviar para revisão mais tarde.'
                      : 'O quiz ainda não foi $action. Podes guardá-lo como rascunho e continuar mais tarde.',
                  style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, _ExitAction.exit),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, _ExitAction.cancel),
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, _ExitAction.saveDraft),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    child: const Text('Guardar rascunho'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    switch (result) {
      case _ExitAction.exit:
        if (widget.popOnExit) {
          setState(() => _exiting = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.quizList, (r) => false);
        }
      case _ExitAction.saveDraft:
        await _saveDraft();
      case _ExitAction.cancel:
      case null:
        break;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      if (AuthState.instance.isAdmin) {
        final updated = await _service.updateQuiz(
          widget.quiz.id,
          _buildPayload('APPROVED'),
        );
        if (!mounted) return;
        if (updated.status == 'APPROVED') {
          showAppToast(context, 'Quiz publicado com sucesso!',
              type: AppToastType.success);
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.quizList, (r) => false);
        } else {
          setState(() => _submitting = false);
          showAppToast(
            context,
            'Não foi possível publicar. Estado retornado: ${updated.status}',
            type: AppToastType.error,
          );
        }
      } else {
        // 1 — persist any edits made in the review screen
        await _service.updateQuiz(widget.quiz.id, _buildPayload('DRAFT'));
        if (!mounted) return;
        // 2 — change DRAFT → PENDING via the dedicated submit endpoint
        final submitted = await _service.submitForReview(widget.quiz.id);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizSubmittedScreen(
              title: submitted.title,
              difficulty: submitted.difficulty,
              questionCount: submitted.questionCount,
              isAiGenerated: widget.isAiGenerated,
              status: submitted.status,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final isValidation = e.statusCode == 422 || e.errors != null;
      final msg = isValidation
          ? (AuthState.instance.isAdmin
              ? 'Não foi possível publicar o quiz. Tenta novamente.'
              : 'Não foi possível enviar para revisão. Tenta novamente.')
          : e.message;
      showAppToast(context, msg, type: AppToastType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(context, 'Ocorreu um erro inesperado. Tenta novamente.',
          type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopScope(
      canPop: _exiting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textSecondary, size: 20),
          onPressed: _handleBack,
        ),
        centerTitle: true,
        title: Text(
          widget.readOnly ? 'Quiz em revisão' : 'Revisão do Quiz',
          style: TextStyle(
              color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: _loadingQuiz
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: c.muted),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchQuestions,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    _QuizInfoCard(quiz: widget.quiz, isAiGenerated: widget.isAiGenerated),
                    const SizedBox(height: 20),
                    Text(
                      widget.isAiGenerated ? 'PERGUNTAS GERADAS' : 'PERGUNTAS',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_questions.length, (i) {
                      if (!widget.readOnly && _editingIndex == i) {
                        return _EditCard(
                          index: i,
                          question: _questions[i],
                          onSave: () => setState(() => _editingIndex = null),
                          onCancel: () => setState(() => _editingIndex = null),
                        );
                      }
                      return _QuestionViewCard(
                        index: i,
                        question: _questions[i],
                        readOnly: widget.readOnly,
                        onEdit: () => setState(() => _editingIndex = i),
                      );
                    }),
                  ],
                ),
      bottomNavigationBar: widget.readOnly ? null : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: c.card,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(AuthState.instance.isAdmin
                          ? 'Publicar'
                          : 'Enviar para revisão'),
                ),
              ),
              if (!AuthState.instance.isAdmin) ...[
                const SizedBox(height: 6),
                Text(
                  'O quiz será revisto pela equipa antes de ser publicado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

enum _ExitAction { exit, cancel, saveDraft }

// ── Editable question state ───────────────────────────────────────────────────

class _ReviewQ {
  final int id;
  final TextEditingController questionCtrl;
  final TextEditingController explanationCtrl;
  final List<TextEditingController> optionCtrls;
  final List<int> optionIds;
  int correctIndex;

  _ReviewQ({
    required this.id,
    required this.questionCtrl,
    required this.explanationCtrl,
    required this.optionCtrls,
    required this.optionIds,
    required this.correctIndex,
  });

  factory _ReviewQ.fromModel(QuestionModel q) {
    final sorted = [...q.options]
      ..sort((a, b) => a.quizPosition.compareTo(b.quizPosition));
    final correctIdx = sorted.indexWhere((o) => o.isCorrect == true);
    return _ReviewQ(
      id: q.id,
      questionCtrl: TextEditingController(text: q.text),
      explanationCtrl: TextEditingController(text: q.explanation ?? ''),
      optionCtrls: sorted
          .map((o) => TextEditingController(text: o.text))
          .toList(),
      optionIds: sorted.map((o) => o.id).toList(),
      correctIndex: correctIdx >= 0 ? correctIdx : 0,
    );
  }

  void dispose() {
    questionCtrl.dispose();
    explanationCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

// ── Quiz info card ────────────────────────────────────────────────────────────

class _QuizInfoCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isAiGenerated;
  const _QuizInfoCard({required this.quiz, this.isAiGenerated = true});

  Color _diffColor() {
    final d = quiz.difficulty.toLowerCase();
    if (d == 'easy' || d == 'iniciante') return AppColors.success;
    if (d == 'hard' || d.contains('van')) return AppColors.error;
    return Colors.orange;
  }

  String _diffLabel() {
    final d = quiz.difficulty.toLowerCase();
    if (d == 'easy' || d == 'iniciante') return 'Nível Iniciante';
    if (d == 'hard' || d.contains('van')) return 'Nível Avançado';
    return 'Nível Médio';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final diffColor = _diffColor();
    final authorName = (quiz.author?['name'] ?? quiz.author?['full_name'])?.toString();
    final articleTitle = quiz.article?['title']?.toString();

    final (statusColor, statusLabel) = switch (quiz.status) {
      'DRAFT'    => (Colors.grey as Color, 'Rascunho'),
      'PENDING'  => (const Color(0xFFF59E0B), 'Em revisão'),
      'REJECTED' => (AppColors.error, 'Rejeitado'),
      _          => (AppColors.success, 'Publicado'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge + status badge
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.wineBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAiGenerated ? Icons.auto_awesome_rounded : Icons.edit_note_rounded,
                        color: AppColors.wine,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isAiGenerated ? 'QUIZ GERADO POR IA' : 'QUIZ CRIADO MANUALMENTE',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.wine,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.textMain,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _diffLabel(),
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.description_outlined, size: 14, color: c.muted),
              const SizedBox(width: 4),
              Text(
                '${quiz.questionCount} perguntas',
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
          ),
          if (authorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: c.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Por $authorName',
                    style: TextStyle(color: c.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (articleTitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.article_outlined, size: 14, color: c.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    articleTitle,
                    style: TextStyle(color: c.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Question view card ────────────────────────────────────────────────────────

class _QuestionViewCard extends StatelessWidget {
  final int index;
  final _ReviewQ question;
  final bool readOnly;
  final VoidCallback onEdit;

  const _QuestionViewCard({
    required this.index,
    required this.question,
    this.readOnly = false,
    required this.onEdit,
  });

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${question.questionCtrl.text}',
                  style: TextStyle(
                    color: c.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (!readOnly) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.flag_outlined,
                      size: 18, color: c.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(
            question.optionCtrls.length.clamp(0, 4),
            (i) {
              final isCorrect = question.correctIndex == i;
              final letter = i < _letters.length ? _letters[i] : '${i + 1}';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.successLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isCorrect
                      ? Border.all(
                          color: AppColors.success.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      '$letter.',
                      style: TextStyle(
                        color: isCorrect
                            ? AppColors.success
                            : c.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.optionCtrls[i].text,
                        style: TextStyle(
                          color: isCorrect ? AppColors.success : c.textMain,
                          fontSize: 13,
                          fontWeight: isCorrect
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Edit card ─────────────────────────────────────────────────────────────────

class _EditCard extends StatefulWidget {
  final int index;
  final _ReviewQ question;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditCard({
    required this.index,
    required this.question,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<_EditCard> {
  late int _correctIndex;
  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _correctIndex = widget.question.correctIndex;
  }

  void _save() {
    widget.question.correctIndex = _correctIndex;
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = widget.question;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.wineBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'EDITANDO PERGUNTA ${widget.index + 1}',
              style: const TextStyle(
                color: AppColors.wine,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Question text
          _buildField(q.questionCtrl, 'Texto da pergunta...', c,
              minLines: 2, maxLines: 5),
          const SizedBox(height: 10),

          // Options
          Text(
            'Marque a opção correcta',
            style: TextStyle(
                fontSize: 11, color: c.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...List.generate(
            q.optionCtrls.length.clamp(0, 4),
            (i) {
              final isCorrect = _correctIndex == i;
              final letter = i < _letters.length ? _letters[i] : '${i + 1}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _correctIndex = i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.wine
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCorrect ? AppColors.wine : c.border,
                            width: 2,
                          ),
                        ),
                        child: isCorrect
                            ? const Icon(Icons.circle,
                                color: Colors.white, size: 10)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: q.optionCtrls[i],
                        decoration: InputDecoration(
                          hintText: '$letter. Opção...',
                          hintStyle:
                              TextStyle(color: c.muted, fontSize: 13),
                          filled: true,
                          fillColor: c.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: c.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: c.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.wine,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          suffixText: isCorrect ? 'CORRETA' : null,
                          suffixStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Explanation
          const SizedBox(height: 4),
          _buildField(
              q.explanationCtrl, 'Explicação da resposta correcta...', c,
              minLines: 2, maxLines: 4),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Guardar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    AppAdaptiveColors c, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: c.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted, fontSize: 13),
        filled: true,
        fillColor: c.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.wine),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
