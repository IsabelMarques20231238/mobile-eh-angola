import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../quiz/quiz_ai_generation_screen.dart';
import '../quiz/quiz_submitted_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _service = QuizService(ApiClient.instance);
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  final _articleIdCtrl = TextEditingController();

  bool _aiMode = true;
  int _difficulty = 1; // 0=Iniciante, 1=Médio, 2=Avançado
  int _questionCount = 10;
  bool _submitting = false;

  static const _diffLabels = ['Iniciante', 'Médio', 'Avançado'];

  final List<_ManualQuestion> _questions = [_ManualQuestion()];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _contextCtrl.dispose();
    _articleIdCtrl.dispose();
    for (final q in _questions) { q.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('Introduz o título do quiz.', error: true);
      return;
    }
    final articleIdStr = _articleIdCtrl.text.trim();
    final articleId = int.tryParse(articleIdStr);
    if (articleId == null) {
      _toast('Introduz um ID de artigo válido.', error: true);
      return;
    }

    // AI mode: navigate to the generation screen which handles the API call
    if (_aiMode) {
      final topic = _topicCtrl.text.trim();
      if (topic.isEmpty) {
        _toast('Introduz o tema principal.', error: true);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizAIGenerationScreen(
            title: title,
            topic: topic,
            difficulty: _diffLabels[_difficulty],
            numQuestions: _questionCount,
            articleId: articleId,
            context: _contextCtrl.text.trim().isEmpty
                ? null
                : _contextCtrl.text.trim(),
          ),
        ),
      );
      return;
    }

    // Validate manual questions before going async
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        _toast('Pergunta ${i + 1} está vazia.', error: true);
        return;
      }
      for (int j = 0; j < q.optionCtrls.length; j++) {
        if (q.optionCtrls[j].text.trim().isEmpty) {
          _toast('Preenche a opção ${j + 1} da pergunta ${i + 1}.', error: true);
          return;
        }
      }
    }
    final questions = _questions.map((q) {
      final opts = q.optionCtrls.asMap().entries.map((e) => {
            'text': e.value.text.trim(),
            'is_correct': e.key == q.correctIndex,
          }).toList();
      return {
        'text': q.questionCtrl.text.trim(),
        'explanation': q.explanationCtrl.text.trim(),
        'options': opts,
      };
    }).toList();

    setState(() => _submitting = true);
    try {
      final created = await _service.createQuiz({
        'title': title,
        'description': _topicCtrl.text.trim().isEmpty
            ? null
            : _topicCtrl.text.trim(),
        'difficulty': _diffLabels[_difficulty],
        'article_id': articleId,
        'questions': questions,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizSubmittedScreen(
            title: created.title,
            difficulty: created.difficulty,
            questionCount: created.questionCount,
            isAiGenerated: _aiMode,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textSecondary, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Novo Questionário',
          style: TextStyle(
              color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              'Guardar',
              style: TextStyle(
                  color: _submitting ? c.muted : c.wine,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          // Mode selector
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeCard(
                    selected: _aiMode,
                    icon: Icons.auto_awesome_outlined,
                    title: 'Gerar com IA',
                    subtitle: 'Rápido e automático',
                    onTap: () => setState(() => _aiMode = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    selected: !_aiMode,
                    icon: Icons.playlist_add_check_rounded,
                    title: 'Criar manualmente',
                    subtitle: 'Controlo total',
                    onTap: () => setState(() => _aiMode = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('INFORMAÇÕES GERAIS'),
          const SizedBox(height: 14),
          _LabeledInput(
            label: 'Título do quiz',
            controller: _titleCtrl,
            hint: _aiMode
                ? 'Introduza o nome do quiz'
                : 'Ex: A Economia Cafeeira em Angola',
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            label: _aiMode ? 'Tema principal' : 'Descrição (opcional)',
            controller: _topicCtrl,
            hint: _aiMode
                ? 'Ex: Reforma Monetária 1999'
                : 'Descrição do quiz...',
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            label: 'ID do Artigo vinculado *',
            controller: _articleIdCtrl,
            hint: 'Ex: 5',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text('Dificuldade',
              style: TextStyle(
                  color: c.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _DifficultySelector(
            value: _difficulty,
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          // AI config
          if (_aiMode) ...[
            const SizedBox(height: 28),
            _SectionTitle('CONFIGURAÇÃO DA IA'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Número de perguntas',
                    style: TextStyle(
                        color: c.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$_questionCount',
                  style: TextStyle(
                      color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              activeColor: AppColors.wine,
              inactiveColor: c.border,
              onChanged: (v) => setState(() => _questionCount = v.round()),
            ),
            const SizedBox(height: 12),
            _LabeledInput(
              label: 'Contexto adicional (opcional)',
              controller: _contextCtrl,
              hint: 'Ex: focar no período 1990–2000...',
              minLines: 3,
            ),
          ],
          // Manual questions
          if (!_aiMode) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Questões',
                    style: TextStyle(
                        color: c.wine,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_questions.length}/20',
                    style: TextStyle(color: c.muted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _questions.length,
              (i) => _QuestionCard(
                index: i,
                question: _questions[i],
                canDelete: _questions.length > 1,
                onDelete: () => setState(() => _questions.removeAt(i)),
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 4),
            if (_questions.length < 20)
              GestureDetector(
                onTap: () => setState(() => _questions.add(_ManualQuestion())),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: c.wine, size: 18),
                      const SizedBox(width: 6),
                      Text('Adicionar pergunta',
                          style: TextStyle(
                              color: c.wine,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: context.c.card,
            border: Border(top: BorderSide(color: context.c.border)),
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
                      : Text(_aiMode ? 'Gerar quiz com IA' : 'Criar Quiz'),
                ),
              ),
              if (_aiMode) ...[
                const SizedBox(height: 8),
                Text(
                  'O quiz será enviado para aprovação antes de ser publicado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.c.muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Manual question model ─────────────────────────────────────────────────────

class _ManualQuestion {
  final TextEditingController questionCtrl = TextEditingController();
  final TextEditingController explanationCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls =
      List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  void dispose() {
    questionCtrl.dispose();
    explanationCtrl.dispose();
    for (final c in optionCtrls) { c.dispose(); }
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final int index;
  final _ManualQuestion question;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pergunta ${index + 1}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textMain),
              ),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _field(question.questionCtrl, 'Escreva a pergunta...', c,
              minLines: 2, maxLines: 4),
          const SizedBox(height: 8),
          _field(question.explanationCtrl, 'Explicação da resposta correcta...', c,
              minLines: 2, maxLines: 3),
          const SizedBox(height: 10),
          ...List.generate(question.optionCtrls.length, (i) {
            final isCorrect = question.correctIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      question.correctIndex = i;
                      onChanged();
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color:
                            isCorrect ? AppColors.wine : Colors.transparent,
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
                      controller: question.optionCtrls[i],
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        hintText: '${_letters[i]}. Opção...',
                        hintStyle: TextStyle(color: c.muted, fontSize: 13),
                        filled: true,
                        fillColor: c.card,
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
                          borderSide:
                              const BorderSide(color: AppColors.wine),
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
          }),
        ],
      ),
    );
  }

  Widget _field(
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted, fontSize: 13),
        filled: true,
        fillColor: c.card,
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

// ── Shared form widgets ───────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 88),
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : c.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.wine : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: selected ? AppColors.wine : c.muted, size: 22),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? AppColors.wine : c.border,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: context.c.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      );
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final TextInputType? keyboardType;

  const _LabeledInput({
    required this.label,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 5,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.muted),
            border:
                OutlineInputBorder(borderSide: BorderSide(color: c.border)),
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: c.border)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.wine)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DifficultySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const labels = ['Iniciante', 'Médio', 'Avançado'];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: c.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: value == i ? AppColors.wine : c.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
