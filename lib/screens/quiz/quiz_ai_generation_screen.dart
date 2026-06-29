import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import 'quiz_ai_review_screen.dart';

class QuizAIGenerationScreen extends StatefulWidget {
  final String topic;
  final String title;
  final String difficulty;
  final int numQuestions;
  final int? articleId;
  final int? categoryId;
  final String? description;
  final String? context;

  const QuizAIGenerationScreen({
    super.key,
    required this.topic,
    required this.title,
    this.difficulty = 'Médio',
    this.numQuestions = 10,
    this.articleId,
    this.categoryId,
    this.description,
    this.context,
  });

  @override
  State<QuizAIGenerationScreen> createState() => _QuizAIGenerationScreenState();
}

class _QuizAIGenerationScreenState extends State<QuizAIGenerationScreen> {
  final _service = QuizService(ApiClient.instance);

  double _progress = 0.0;
  int _stepIndex = 0;
  Timer? _progressTimer;
  bool _cancelled = false;
  String? _error;

  static const _steps = [
    'Analisando fontes históricas...',
    'A redigir perguntas...',
    'Verificar precisão histórica',
    'Calcular bias risk',
  ];
  static const _stepLabels = [
    'Analisou fontes',
    'Perguntas redigidas',
    'Precisão verificada',
    'Bias calculado',
  ];

  String get _currentLabel =>
      _stepIndex < _steps.length ? _steps[_stepIndex] : 'A finalizar...';

  @override
  void initState() {
    super.initState();
    _startProgressAnimation();
    _callApi();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressAnimation() {
    // Advance slowly to 90% over ~120s (0.0015 per 200ms tick ≈ 90% in ~120s)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_cancelled || !mounted) { t.cancel(); return; }
      setState(() {
        if (_progress < 0.9) {
          _progress += 0.0015;
          final targetStep = (_progress * _steps.length).floor();
          _stepIndex = targetStep.clamp(0, _steps.length - 1);
        }
      });
    });
  }

  Future<void> _callApi() async {
    try {
      final quiz = await _service.generateAiQuiz(
        title: widget.title.isEmpty ? widget.topic : widget.title,
        topic: widget.topic.isEmpty ? widget.title : widget.topic,
        difficulty: widget.difficulty,
        numQuestions: widget.numQuestions,
        articleId: widget.articleId,
        categoryId: widget.categoryId,
        description: widget.description,
        context: widget.context,
      );
      if (!mounted || _cancelled) return;
      _progressTimer?.cancel();
      setState(() {
        _progress = 1.0;
        _stepIndex = _steps.length;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _cancelled) return;

      // Always go to review — user must inspect AI content before it goes live
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizAIReviewScreen(quiz: quiz)),
      );
    } on ApiException catch (e) {
      if (!mounted || _cancelled) return;
      _progressTimer?.cancel();
      final isNetworkError = e.message.toLowerCase().contains('contactar') ||
          e.message.toLowerCase().contains('timeout');
      setState(() => _error = isNetworkError
          ? 'A geração demorou mais do esperado. A IA pode estar ocupada — tenta novamente.'
          : e.message);
    } catch (_) {
      if (!mounted || _cancelled) return;
      _progressTimer?.cancel();
      setState(() => _error = 'Ocorreu um erro inesperado. Tenta novamente.');
    }
  }

  void _cancel() {
    _cancelled = true;
    _progressTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = (_progress * 100).round();

    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textSecondary, size: 24),
          onPressed: _cancel,
        ),
        centerTitle: true,
        title: Text(
          'Novo Questionário',
          style: TextStyle(
              color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _error != null ? AppColors.error : AppColors.wine,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _error != null ? Icons.error_outline : Icons.auto_awesome,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _error != null ? 'Erro na geração' : 'A gerar o teu quiz...',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? (widget.topic.isEmpty ? widget.title : widget.topic),
              style: TextStyle(fontSize: 14, color: c.muted),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _error = null; _progress = 0; _stepIndex = 0; _cancelled = false; });
                    _startProgressAnimation();
                    _callApi();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentLabel,
                            style: TextStyle(
                                fontSize: 13, color: c.textSecondary)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: c.border,
                            valueColor: AlwaysStoppedAnimation(c.wine),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$pct%',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.wine),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ...List.generate(_steps.length, (i) => _buildStep(i, c)),
              const SizedBox(height: 32),
              Text(
                'O quiz passará por revisão antes de ser publicado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('Cancelar geração',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int i, AppAdaptiveColors c) {
    final done = _stepIndex > i;
    final active = _stepIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: done
              ? AppColors.successLight
              : active
                  ? AppColors.wineBg
                  : c.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done
                ? AppColors.success.withValues(alpha: 0.3)
                : active
                    ? AppColors.wine.withValues(alpha: 0.3)
                    : c.border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: done
                  ? const Icon(Icons.check_circle,
                      color: AppColors.success, size: 22)
                  : active
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.wine),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.border, width: 2),
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            Text(
              done ? _stepLabels[i] : _steps[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
                color: done
                    ? AppColors.success
                    : active
                        ? c.wine
                        : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
