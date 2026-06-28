import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';
import 'quiz_result_screen.dart';

// Holds the API response from POST /quizzes/{id}/answer.
// isCorrect == null means the backend failed — answer was still recorded locally.
class _AnswerFeedback {
  final bool? isCorrect;
  final int? correctOptionId;
  final String? explanation;

  const _AnswerFeedback({
    this.isCorrect,
    this.correctOptionId,
    this.explanation,
  });

  factory _AnswerFeedback.fromJson(Map<String, dynamic> json) {
    // Unwrap Laravel-style { "data": { ... } } if present
    final d = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    // is_correct may arrive as bool, int (0/1), or string ("true"/"false")
    bool? parseCorrect(dynamic v) {
      if (v == true || v == 1 || v == '1' || v == 'true') return true;
      if (v == false || v == 0 || v == '0' || v == 'false') return false;
      return null;
    }

    // correct_option_id may arrive as int or string
    int? parseId(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return _AnswerFeedback(
      isCorrect: parseCorrect(d['is_correct']),
      correctOptionId: parseId(d['correct_option_id']),
      explanation: d['explanation']?.toString(),
    );
  }
}

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
  _AnswerFeedback? _feedback; // null = not yet confirmed
  bool _confirming = false;   // waiting for /answer API call
  bool _submitting = false;   // waiting for /submit API call
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
  bool get _confirmed => _feedback != null;
  String get _formattedTime => formatSeconds(_secondsElapsed);

  void _selectOption(int optionId) {
    if (_confirmed || _confirming) return;
    setState(() => _selectedOptionId = optionId);
  }

  Future<void> _confirm() async {
    if (_selectedOptionId == null || _confirming) return;

    setState(() => _confirming = true);
    // Pre-record locally so the final submit always has this answer
    _answers.add({
      'question_id': _currentQuestion.id,
      'answer_option_id': _selectedOptionId!,
    });
    try {
      final json = await _service.answerQuestion(
        widget.quiz.id,
        _currentQuestion.id,
        _selectedOptionId!,
      );
      if (!mounted) return;
      setState(() {
        _feedback = _AnswerFeedback.fromJson(json);
        _confirming = false;
      });
    } catch (_) {
      // Backend unavailable for this quiz — show neutral state so user can proceed
      if (!mounted) return;
      setState(() {
        _feedback = const _AnswerFeedback(); // isCorrect == null
        _confirming = false;
      });
    }
  }

  Future<void> _next() async {
    if (_currentIndex < _totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _feedback = null;
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
    final fb = _feedback;

    // Determine visual state
    bool isCorrectSlot = false;
    bool isWrongSlot = false;

    if (fb != null) {
      final known = fb.isCorrect; // null = no feedback from backend
      if (fb.correctOptionId != null) {
        isCorrectSlot = option.id == fb.correctOptionId;
        isWrongSlot = isSelected && known != true && option.id != fb.correctOptionId;
      } else if (known == true && isSelected) {
        isCorrectSlot = true;
      } else if (known == false && isSelected) {
        isWrongSlot = true;
      }
      // known == null: keep options neutral (no green/red)
    }

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
      if (isCorrectSlot) {
        cardBg = AppColors.successLight;
        cardBorder = AppColors.success;
        letterBg = AppColors.success;
        letterFg = Colors.white;
        textColor = AppColors.success;
        borderWidth = 1.5;
        trailing = const Icon(Icons.check_rounded, color: AppColors.success, size: 18);
      } else if (isWrongSlot) {
        cardBg = AppColors.errorLight;
        cardBorder = AppColors.error;
        letterBg = AppColors.error;
        letterFg = Colors.white;
        textColor = AppColors.error;
        borderWidth = 1.5;
        trailing = const Icon(Icons.close_rounded, color: AppColors.error, size: 18);
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
              decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: letterFg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: (isCorrectSlot || isWrongSlot)
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
    final fb = _feedback;
    // null = no feedback (backend error) → use wine; true = green; false = red
    final Color btnColor;
    if (!_confirmed) {
      btnColor = AppColors.wine;
    } else if (fb?.isCorrect == true) {
      btnColor = AppColors.success;
    } else if (fb?.isCorrect == false) {
      btnColor = AppColors.error;
    } else {
      btnColor = AppColors.wine; // neutral when unknown
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: fb != null ? _buildFeedbackPanel(fb, c) : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting || _confirming
                  ? null
                  : _confirmed
                      ? _next
                      : (_selectedOptionId != null ? _confirm : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                disabledBackgroundColor: c.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: (_confirming || _submitting)
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

  Widget _buildFeedbackPanel(_AnswerFeedback fb, AppAdaptiveColors c) {
    final known = fb.isCorrect;

    // Neutral fallback when backend didn't return feedback
    if (known == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: c.muted, size: 20),
            const SizedBox(width: 8),
            Text(
              'Resposta registada',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
          ],
        ),
      );
    }

    final bg = known ? AppColors.successLight : AppColors.errorLight;
    final borderColor = known ? AppColors.success : AppColors.error;
    final color = known ? AppColors.success : AppColors.error;
    final icon = known ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = known ? 'Resposta correcta!' : 'Resposta Incorrecta!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        color: bg,
        border:
            Border(top: BorderSide(color: borderColor.withValues(alpha: 0.35))),
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
                    fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          if (fb.explanation != null && fb.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              fb.explanation!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
