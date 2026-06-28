import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../quiz/quiz_ai_generation_screen.dart';
import '../quiz/quiz_submitted_screen.dart';

// Display labels shown to creator; API labels sent to backend
const _diffDisplay = ['Fácil', 'Médio', 'Difícil'];
const _diffApi = ['EASY', 'MEDIUM', 'HARD'];

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _service = QuizService(ApiClient.instance);
  final _titleCtrl = TextEditingController();
  final _contextCtrl = TextEditingController();

  bool _aiMode = true;
  int _difficulty = 1;
  int _questionCount = 10;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = false;

  Map<String, dynamic>? _selectedArticle;
  final List<_ManualQuestion> _questions = [_ManualQuestion()];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contextCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    _categories = await _service.getCategories();
    if (mounted) setState(() => _loadingCategories = false);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_selectedArticle == null) return false;
    if (!_aiMode) {
      if (_questions.isEmpty) return false;
      for (final q in _questions) {
        if (q.questionCtrl.text.trim().isEmpty) return false;
        if (q.correctIndex < 0) return false;
        if (q.explanationCtrl.text.trim().isEmpty) return false;
        for (final opt in q.optionCtrls) {
          if (opt.text.trim().isEmpty) return false;
        }
      }
    }
    return true;
  }

  Future<void> _pickArticle() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArticleSearchSheet(service: _service),
    );
    if (result != null && mounted) setState(() => _selectedArticle = result);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final title = _titleCtrl.text.trim();
    final articleId = _selectedArticle!['id'] as int;
    final articleTitle = _selectedArticle!['title']?.toString() ?? title;

    if (_aiMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizAIGenerationScreen(
            title: title,
            topic: articleTitle,
            difficulty: _diffApi[_difficulty],
            numQuestions: _questionCount,
            articleId: articleId,
            categoryId: _selectedCategoryId,
            context: _contextCtrl.text.trim().isEmpty
                ? null
                : _contextCtrl.text.trim(),
          ),
        ),
      );
      return;
    }

    final questions = _questions.map((q) {
      final opts = q.optionCtrls.asMap().entries
          .map((e) => {
                'text': e.value.text.trim(),
                'is_correct': e.key == q.correctIndex,
              })
          .toList();
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
        'difficulty': _diffApi[_difficulty],
        'article_id': articleId,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
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
            isAiGenerated: false,
            status: created.status,
            quiz: created.status == 'APPROVED' ? created : null,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canSubmit = _canSubmit;
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          // ── Mode toggle ────────────────────────────────────────────────
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

          // ── General info ───────────────────────────────────────────────
          _SectionTitle('INFORMAÇÕES GERAIS'),
          const SizedBox(height: 14),

          _FormLabel('Título do quiz *'),
          const SizedBox(height: 8),
          _buildTextField(
            _titleCtrl,
            _aiMode
                ? 'Ex: Reforma Monetária de Angola'
                : 'Ex: A Economia Cafeeira em Angola',
            c,
          ),
          const SizedBox(height: 16),

          _FormLabel('Dificuldade'),
          const SizedBox(height: 8),
          _DifficultySelector(
            value: _difficulty,
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 16),

          _FormLabel('Categoria'),
          const SizedBox(height: 8),
          _CategoryDropdown(
            categories: _categories,
            loading: _loadingCategories,
            selectedId: _selectedCategoryId,
            onChanged: (id) => setState(() => _selectedCategoryId = id),
          ),
          const SizedBox(height: 16),

          _FormLabel('Artigo vinculado *'),
          const SizedBox(height: 8),
          _ArticleField(article: _selectedArticle, onTap: _pickArticle),

          // ── AI config ──────────────────────────────────────────────────
          if (_aiMode) ...[
            const SizedBox(height: 28),
            _SectionTitle('CONFIGURAÇÃO DA IA'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FormLabel('Número de perguntas'),
                ),
                Text(
                  '$_questionCount',
                  style: TextStyle(
                      color: c.wine,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Slider(
              value: _questionCount.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              activeColor: AppColors.wine,
              inactiveColor: c.border,
              onChanged: (v) => setState(() => _questionCount = v.round()),
            ),
            const SizedBox(height: 12),
            _FormLabel('Contexto adicional (opcional)'),
            const SizedBox(height: 8),
            _buildTextField(
              _contextCtrl,
              'Ex: focar no período 1990–2000...',
              c,
              minLines: 3,
              maxLines: 6,
            ),
          ],

          // ── Manual questions ───────────────────────────────────────────
          if (!_aiMode) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Questões',
                  style: TextStyle(
                      color: c.wine,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${_questions.length}/20',
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
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
            if (_questions.length < 20)
              GestureDetector(
                onTap: () =>
                    setState(() => _questions.add(_ManualQuestion())),
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
                      Text(
                        'Adicionar pergunta',
                        style: TextStyle(
                            color: c.wine,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: _BottomBar(
        aiMode: _aiMode,
        canSubmit: canSubmit,
        submitting: _submitting,
        onSubmit: _submit,
      ),
    );
  }

  Widget _buildTextField(
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
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.wine)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool aiMode;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.aiMode,
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
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
                onPressed: canSubmit ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  disabledBackgroundColor: c.border,
                  disabledForegroundColor: c.muted,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(aiMode ? 'Gerar quiz com IA' : 'Criar Quiz'),
              ),
            ),
            if (aiMode) ...[
              const SizedBox(height: 8),
              Text(
                'O quiz será enviado para aprovação antes de ser publicado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Article field ─────────────────────────────────────────────────────────────

class _ArticleField extends StatelessWidget {
  final Map<String, dynamic>? article;
  final VoidCallback onTap;
  const _ArticleField({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = article?['title']?.toString();
    final selected = article != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.wine : c.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? AppColors.wineBg : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.article_rounded : Icons.search_rounded,
              size: 18,
              color: selected ? AppColors.wine : c.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title ?? 'Pesquisar e seleccionar artigo...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? c.textMain : c.muted,
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: selected ? AppColors.wine : c.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Article search bottom sheet ───────────────────────────────────────────────

class _ArticleSearchSheet extends StatefulWidget {
  final QuizService service;
  const _ArticleSearchSheet({required this.service});

  @override
  State<_ArticleSearchSheet> createState() => _ArticleSearchSheetState();
}

class _ArticleSearchSheetState extends State<_ArticleSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _initialLoad = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await widget.service.searchArticles(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _initialLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar artigo',
                  style: TextStyle(
                      color: c.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar artigo...',
                    hintStyle: TextStyle(color: c.muted, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: c.muted, size: 20),
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
                      borderSide: const BorderSide(color: AppColors.wine),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: c.bg,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.wine, strokeWidth: 2),
              ),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 40, color: c.border),
                    const SizedBox(height: 12),
                    Text(
                      _initialLoad || _ctrl.text.isEmpty
                          ? 'Escreva para pesquisar artigos'
                          : 'Nenhum artigo encontrado',
                      style: TextStyle(color: c.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _results.length,
                separatorBuilder: (_, _) =>
                    Divider(color: c.border, height: 1),
                itemBuilder: (ctx, i) {
                  final art = _results[i];
                  final artTitle = art['title']?.toString() ?? '';
                  final catName = art['category'] is Map
                      ? (art['category'] as Map)['name']?.toString()
                      : art['category_name']?.toString();
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.wineBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.article_rounded,
                          color: AppColors.wine, size: 20),
                    ),
                    title: Text(
                      artTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textMain),
                    ),
                    subtitle: catName != null && catName.isNotEmpty
                        ? Text(catName,
                            style:
                                TextStyle(fontSize: 11, color: c.muted))
                        : null,
                    onTap: () => Navigator.pop(ctx, art),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category dropdown ─────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final bool loading;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.loading,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (loading) {
      return Container(
        height: 50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: c.muted),
            ),
            const SizedBox(width: 10),
            Text('A carregar categorias...',
                style: TextStyle(color: c.muted, fontSize: 14)),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      dropdownColor: c.card,
      style: TextStyle(color: c.textMain, fontSize: 14),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.muted),
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.wine)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'Seleccionar categoria (opcional)',
            style: TextStyle(color: c.muted, fontSize: 14),
          ),
        ),
        ...categories.map((cat) => DropdownMenuItem<int?>(
              value: cat['id'] as int?,
              child: Text(
                cat['name']?.toString() ?? '',
                style: TextStyle(color: c.textMain, fontSize: 14),
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Manual question model ─────────────────────────────────────────────────────

class _ManualQuestion {
  final TextEditingController questionCtrl = TextEditingController();
  final TextEditingController explanationCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls =
      List.generate(4, (_) => TextEditingController());
  int correctIndex = -1; // -1 = none selected yet (required)

  void dispose() {
    questionCtrl.dispose();
    explanationCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
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
          // Header
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

          // Question text
          _field(question.questionCtrl, 'Escreva a pergunta... *', c,
              minLines: 2, maxLines: 4),
          const SizedBox(height: 8),

          // Explanation (required)
          _field(question.explanationCtrl,
              'Explicação da resposta correcta... *', c,
              minLines: 2, maxLines: 3),
          const SizedBox(height: 10),

          // Options with correct radio
          Text(
            'Marque a opção correcta *',
            style: TextStyle(
                fontSize: 11,
                color: c.muted,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
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
                        color: isCorrect
                            ? AppColors.wine
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isCorrect ? AppColors.wine : c.border,
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
                        hintStyle:
                            TextStyle(color: c.muted, fontSize: 13),
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
          border:
              Border.all(color: selected ? AppColors.wine : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: selected ? AppColors.wine : c.muted,
                    size: 22),
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: context.c.textMain,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _DifficultySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DifficultySelector(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: c.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _diffDisplay.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: value == i
                        ? [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    _diffDisplay[i],
                    style: TextStyle(
                      color: value == i
                          ? AppColors.wine
                          : c.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
