import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'quiz_models.dart';
import 'quiz_result_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizQuestionScreen({super.key, required this.quiz});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _answered = false;
  int _correctCount = 0;
  int _errorsCount = 0;
  int _secondsElapsed = 0;
  Timer? _timer;

  // Para o resultado
  final List<bool> _answerResults = [];

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
      setState(() => _secondsElapsed++);
    });
  }

  String get _formattedTime {
    final m = _secondsElapsed ~/ 60;
    final s = _secondsElapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  QuizQuestion get _currentQuestion => widget.quiz.questions[_currentIndex];
  int get _totalQuestions => widget.quiz.questions.length;
  double get _progress => (_currentIndex + 1) / _totalQuestions;

  void _selectOption(String optionId) {
    if (_answered) return;
    final option = _currentQuestion.options.firstWhere((o) => o.id == optionId);
    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
      if (option.isCorrect) {
        _correctCount++;
        _answerResults.add(true);
      } else {
        _errorsCount++;
        _answerResults.add(false);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _answered = false;
      });
    } else {
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quiz: widget.quiz,
            correctCount: _correctCount,
            totalQuestions: _totalQuestions,
            timeSeconds: _secondsElapsed,
            errorsCount: _errorsCount,
          ),
        ),
      );
    }
  }

  void _quit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sair do Quiz?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('O teu progresso será perdido.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continuar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildCategoryBadge(),
                    const SizedBox(height: 14),
                    _buildQuestionText(),
                    if (_currentQuestion.imageUrl != null) ...[
                      const SizedBox(height: 14),
                      _buildQuestionImage(),
                    ],
                    const SizedBox(height: 24),
                    ..._currentQuestion.options.map((o) => _buildOptionTile(o)),
                    const SizedBox(height: 16),
                    if (_answered) _buildExplanation(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_answered) _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _quit,
            child: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          ),
          const Spacer(),
          // Timer
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_formattedTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_currentIndex + 1} de $_totalQuestions',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.quiz.category.label.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildQuestionText() {
    return Text(
      _currentQuestion.question,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
    );
  }

  Widget _buildQuestionImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 140,
        color: AppColors.accentMid,
        child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildOptionTile(QuizOption option) {
    final isSelected = _selectedOptionId == option.id;
    final isCorrect = option.isCorrect;

    Color bgColor = AppColors.white;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.textPrimary;
    Widget? trailingIcon;

    if (_answered && isSelected && isCorrect) {
      bgColor = AppColors.successLight;
      borderColor = AppColors.success;
      textColor = AppColors.success;
      trailingIcon = const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20);
    } else if (_answered && isSelected && !isCorrect) {
      bgColor = AppColors.errorLight;
      borderColor = AppColors.error;
      textColor = AppColors.error;
      trailingIcon = const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20);
    } else if (_answered && isCorrect) {
      bgColor = AppColors.successLight;
      borderColor = AppColors.success;
      textColor = AppColors.success;
      trailingIcon = const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20);
    }

    return GestureDetector(
      onTap: () => _selectOption(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? borderColor : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(option.text, style: TextStyle(fontSize: 14, color: textColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    final isCorrect = _currentQuestion.options.firstWhere((o) => o.id == _selectedOptionId, orElse: () => _currentQuestion.options.first).isCorrect;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCorrect ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle_outline : Icons.info_outline, color: isCorrect ? AppColors.success : AppColors.error, size: 18),
              const SizedBox(width: 6),
              Text(
                isCorrect ? 'Resposta correcta!' : 'Resposta incorrecta',
                style: TextStyle(fontWeight: FontWeight.w700, color: isCorrect ? AppColors.success : AppColors.error, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_currentQuestion.explanation, style: TextStyle(fontSize: 13, color: isCorrect ? AppColors.success : AppColors.error, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex == _totalQuestions - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _nextQuestion,
          child: Text(isLast ? 'Ver Resultado' : 'Próxima pergunta'),
        ),
      ),
    );
  }
}
