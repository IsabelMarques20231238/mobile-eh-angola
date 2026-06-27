import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class QuizSubmittedScreen extends StatelessWidget {
  final String title;
  final String difficulty;
  final int questionCount;
  final bool isAiGenerated;

  const QuizSubmittedScreen({
    super.key,
    required this.title,
    this.difficulty = 'Fácil',
    this.questionCount = 10,
    this.isAiGenerated = true,
  });

  static const _stepsAi = [
    'A equipa administrativa irá rever o conteúdo gerado pela IA para garantir a precisão histórica e económica.',
    'Receberás uma notificação na tua conta assim que o estado do quiz for atualizado.',
    'Após a aprovação, o quiz ficará disponível publicamente para toda a comunidade angolana.',
  ];

  static const _stepsManual = [
    'A equipa administrativa irá rever as perguntas para validar a sua precisão histórica e económica.',
    'Receberás uma notificação na tua conta assim que o estado do quiz for atualizado.',
    'Após a aprovação, o quiz ficará disponível publicamente para toda a comunidade angolana.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final steps = isAiGenerated ? _stepsAi : _stepsManual;

    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textSecondary, size: 24),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        centerTitle: true,
        title: Text(
          'Novo Questionário',
          style: TextStyle(color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Quiz submetido!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              isAiGenerated
                  ? 'O teu quiz gerado por IA foi enviado para revisão pela equipa editorial.'
                  : 'O teu quiz foi enviado para revisão pela equipa editorial.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            // Quiz preview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isAiGenerated ? AppColors.wineBg : c.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isAiGenerated ? Icons.auto_awesome : Icons.edit_note_rounded,
                      color: isAiGenerated ? AppColors.wine : c.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isAiGenerated) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.wineBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.wine,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.textMain,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$questionCount perguntas · $difficulty',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AGUARDA\nAPROVAÇÃO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // O que acontece agora
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'O QUE ACONTECE AGORA?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(steps.length, (i) => _StepItem(index: i + 1, text: steps[i])),
            const SizedBox(height: 32),
            // Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Criar outro quiz'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.wine),
                  foregroundColor: AppColors.wine,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Ver os meus quizzes'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Text(
                'Voltar ao feed',
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final String text;
  const _StepItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.wineBg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
