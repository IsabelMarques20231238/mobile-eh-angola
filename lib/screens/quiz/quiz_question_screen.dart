import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';
import 'quiz_result_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizQuestionScreen({super.key, required this.quiz});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final _service = QuizService(ApiClient.instance);

  int _currentIndex = 0;
  int? _selectedOptionId;
  // null = not yet confirmed; true/false = confirmed correct/wrong
  bool? _isCorrect;
  bool _submitting = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  final List<Map<String, int>> _answers = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  QuestionModel get _currentQuestion => widget.quiz.questions[_currentIndex];
  int get _totalQuestions => widget.quiz.questions.length;
  double get _progress => (_currentIndex + 1) / _totalQuestions;
  bool get _confirmed => _isCorrect != null;
  String get _formattedTime => formatSeconds(_secondsElapsed);

  AnswerOptionModel? get _correctOption =>
      _currentQuestion.options.where((o) => o.isCorrect == true).firstOrNull;

  String? get _feedbackText {
    if (_currentQuestion.explanation?.isNotEmpty == true) {
      return _currentQuestion.explanation;
    }
    return _correctOption?.explanation;
  }

  void _selectOption(int optionId) {
    if (_confirmed) return;
    setState(() => _selectedOptionId = optionId);
  }

  void _confirm() {
    if (_selectedOptionId == null) return;
    final selected =
        _currentQuestion.options.firstWhere((o) => o.id == _selectedOptionId);
    _answers.add({
      'question_id': _currentQuestion.id,
      'answer_option_id': _selectedOptionId!,
    });
    setState(() => _isCorrect = selected.isCorrect ?? false);
  }

  Future<void> _next() async {
    if (_currentIndex < _totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _isCorrect = null;
      });
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    _timer?.cancel();
    setState(() => _submitting = true);
    try {
      final result = await _service.submitQuiz(
        widget.quiz.id,
        _answers,
        _secondsElapsed,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(quiz: widget.quiz, attempt: result),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showAppToast(context, e.message, type: AppToastType.error);
        _startTimer();
      }
    }
  }

  Future<void> _quit() async {
    final ok = await showAppDialog(
      context,
      title: 'Sair do Quiz?',
      message: 'O teu progresso será perdido.',
      confirmLabel: 'Sair',
      cancelLabel: 'Continuar',
      type: AppDialogType.warning,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            _buildProgress(c),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryBadge(),
                    const SizedBox(height: 14),
                    Text(
                      _currentQuestion.text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.textMain,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...List.generate(
                      _currentQuestion.options.length,
                      (i) => _buildOption(_currentQuestion.options[i], i, c),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomSection(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppAdaptiveColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _quit,
            child: Icon(Icons.close, color: c.textMain, size: 22),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formattedTime,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textMain),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(AppAdaptiveColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pergunta ${_currentIndex + 1} de $_totalQuestions',
                  style: TextStyle(fontSize: 12, color: c.muted)),
              Text(
                '${(_progress * 100).round()}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.wine),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.wine),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.quiz.categoryName.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildOption(AnswerOptionModel option, int index, AppAdaptiveColors c) {
    final letter = String.fromCharCode(65 + index);
    final isSelected = _selectedOptionId == option.id;
    final isCorrectOpt = option.isCorrect == true;

    Color cardBg = c.card;
    Color cardBorder = c.border;
    Color letterBg = c.bg;
    Color letterFg = c.textSecondary;
    Color textColor = c.textMain;
    double borderWidth = 1;
    Widget? trailing;

    if (!_confirmed) {
      if (isSelected) {
        cardBg = AppColors.wineBg;
        cardBorder = AppColors.wine;
        letterBg = AppColors.wine;
        letterFg = Colors.white;
        borderWidth = 1.5;
      }
    } else {
      if (isCorrectOpt) {
        cardBg = AppColors.successLight;
        cardBorder = AppColors.success;
        letterBg = AppColors.success;
        letterFg = Colors.white;
        textColor = AppColors.success;
        borderWidth = 1.5;
        trailing =
            const Icon(Icons.check_rounded, color: AppColors.success, size: 18);
      } else if (isSelected) {
        // Selected wrong answer
        cardBg = AppColors.errorLight;
        cardBorder = AppColors.error;
        letterBg = AppColors.error;
        letterFg = Colors.white;
        textColor = AppColors.error;
        borderWidth = 1.5;
        trailing =
            const Icon(Icons.close_rounded, color: AppColors.error, size: 18);
      } else {
        cardBorder = c.border.withValues(alpha: 0.4);
        letterFg = c.muted;
        textColor = c.muted;
      }
    }

    return GestureDetector(
      onTap: () => _selectOption(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder, width: borderWidth),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration:
                  BoxDecoration(color: letterBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: letterFg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: (isSelected || isCorrectOpt) && _confirmed
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(AppAdaptiveColors c) {
    final isLast = _currentIndex == _totalQuestions - 1;
    final correct = _isCorrect == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Feedback panel — appears after confirming
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _confirmed ? _buildFeedbackPanel(c, correct) : const SizedBox.shrink(),
        ),
        // Action button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : _confirmed
                      ? _next
                      : (_selectedOptionId != null ? _confirm : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _confirmed
                    ? (correct ? AppColors.success : AppColors.error)
                    : AppColors.wine,
                disabledBackgroundColor: c.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_confirmed
                      ? (isLast ? 'Ver Resultado' : 'Próxima pergunta')
                      : 'Confirmar Resposta'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackPanel(AppAdaptiveColors c, bool correct) {
    final bg = correct ? AppColors.successLight : AppColors.errorLight;
    final borderColor = correct ? AppColors.success : AppColors.error;
    final color = correct ? AppColors.success : AppColors.error;
    final icon = correct ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = correct ? 'Resposta correcta!' : 'Resposta Incorrecta!';
    final text = _feedbackText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
            top: BorderSide(color: borderColor.withValues(alpha: 0.35))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
