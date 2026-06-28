import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';

class QuizAdminApprovalScreen extends StatefulWidget {
  final int quizId;
  final QuizModel? initialQuiz;

  const QuizAdminApprovalScreen({
    super.key,
    required this.quizId,
    this.initialQuiz,
  });

  @override
  State<QuizAdminApprovalScreen> createState() =>
      _QuizAdminApprovalScreenState();
}

class _QuizAdminApprovalScreenState extends State<QuizAdminApprovalScreen> {
  final _service = QuizService(ApiClient.instance);
  QuizModel? _quiz;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuiz != null) {
      _quiz = widget.initialQuiz;
      _loading = false;
    } else {
      _loadQuiz();
    }
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await _service.adminGetReview(widget.quizId);
      if (mounted) setState(() { _quiz = q; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _approve() async {
    setState(() => _submitting = true);
    try {
      await _service.adminApprove(_quiz!.id);
      if (!mounted) return;
      showAppToast(context, 'Quiz aprovado e publicado com sucesso!',
          type: AppToastType.success);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  void _showRejectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(onConfirm: _reject),
    );
  }

  Future<void> _reject(String reason) async {
    Navigator.pop(context); // fecha o sheet
    setState(() => _submitting = true);
    try {
      await _service.adminReject(_quiz!.id, reason);
      if (!mounted) return;
      showAppToast(context, 'Quiz rejeitado. O autor foi notificado.',
          type: AppToastType.error);
      Navigator.pop(context, false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Revisão de Quiz',
          style: TextStyle(
              color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.wine))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadQuiz)
              : _buildBody(c),
      bottomNavigationBar: (_quiz == null || _loading || _error != null)
          ? null
          : _buildBottomBar(c),
    );
  }

  Widget _buildBody(AppAdaptiveColors c) {
    final quiz = _quiz!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        _InfoCard(quiz: quiz),
        const SizedBox(height: 20),
        Text(
          'PERGUNTAS',
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...quiz.questions.asMap().entries.map(
              (e) => _QuestionCard(index: e.key, question: e.value),
            ),
        if (quiz.questions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Sem perguntas para mostrar.',
                  style: TextStyle(color: c.muted, fontSize: 14)),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(AppAdaptiveColors c) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting ? null : _showRejectSheet,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Rejeitar Quiz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _approve,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                label: const Text('Aprovar e Publicar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final QuizModel quiz;
  const _InfoCard({required this.quiz});

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
          // badges: origem + estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: quiz.isAiGenerated
                      ? AppColors.wineBg
                      : c.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      quiz.isAiGenerated
                          ? Icons.auto_awesome_rounded
                          : Icons.edit_note_rounded,
                      color: quiz.isAiGenerated
                          ? AppColors.wine
                          : c.textSecondary,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      quiz.isAiGenerated
                          ? 'QUIZ GERADO POR IA'
                          : 'QUIZ CRIADO MANUALMENTE',
                      style: TextStyle(
                        color: quiz.isAiGenerated
                            ? AppColors.wine
                            : c.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PENDENTE',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // título
          Text(
            quiz.title,
            style: TextStyle(
              color: c.textMain,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          // descrição
          if (quiz.description != null && quiz.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quiz.description!,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 13, height: 1.45),
            ),
          ],
          const SizedBox(height: 12),
          // meta chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(color: diffColor, label: _diffLabel()),
              _Chip(
                color: c.muted,
                icon: Icons.quiz_outlined,
                label: '${quiz.questionCount} perguntas',
              ),
              _Chip(
                color: c.muted,
                icon: Icons.person_outline_rounded,
                label: 'Por ${quiz.authorName}',
              ),
              if (quiz.categoryName.isNotEmpty &&
                  quiz.categoryName != 'Geral')
                _Chip(
                  color: c.muted,
                  icon: Icons.label_outline_rounded,
                  label: quiz.categoryName,
                ),
              if (quiz.article?['title'] != null)
                _Chip(
                  color: c.muted,
                  icon: Icons.article_outlined,
                  label: quiz.article!['title'].toString(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;
  const _Chip({required this.color, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question card (leitura apenas, sem indicação de resposta correcta) ────────

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  const _QuestionCard({required this.index, required this.question});

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sorted = [...question.options]
      ..sort((a, b) => a.quizPosition.compareTo(b.quizPosition));

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
          Text(
            '${index + 1}. ${question.text}',
            style: TextStyle(
              color: c.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: c.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...sorted.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final letter = i < _letters.length ? _letters[i] : '${i + 1}';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Text(
                    '$letter.',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      opt.text,
                      style: TextStyle(
                          color: c.textMain,
                          fontSize: 13,
                          height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: c.muted, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet de rejeição ──────────────────────────────────────────────────

class _RejectSheet extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;
  const _RejectSheet({required this.onConfirm});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isValid = _ctrl.text.trim().length >= 10;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejeitar Quiz',
                      style: TextStyle(
                          color: c.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'O motivo será enviado ao autor.',
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 4,
              minLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Descreva o motivo da rejeição...',
                hintStyle: TextStyle(color: c.muted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValid && !_submitting
                        ? () async {
                            setState(() => _submitting = true);
                            await widget.onConfirm(_ctrl.text.trim());
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.border,
                      disabledForegroundColor: c.muted,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Confirmar Rejeição',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
