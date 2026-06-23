import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final title = TextEditingController();
  final topic = TextEditingController(text: 'Ex: Reforma Monetária 1999');
  final contextInfo = TextEditingController();
  bool aiMode = true;
  int difficulty = 1;
  int questionCount = 10;
  String category = 'Economia';
  final categories = const ['Economia', 'História', 'Política', 'Cultura'];

  @override
  void dispose() {
    title.dispose();
    topic.dispose();
    contextInfo.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          aiMode ? 'Quiz enviado para geração com IA' : 'Quiz guardado',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textSecondary,
            size: 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Novo Questionário',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.wine,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: AppColors.wine,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeCard(
                    selected: aiMode,
                    icon: Icons.radio_button_checked,
                    title: 'Gerar com IA',
                    subtitle: 'Rápido e automático',
                    onTap: () => setState(() => aiMode = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    selected: !aiMode,
                    icon: Icons.playlist_add_check,
                    title: 'Criar manualmente',
                    subtitle: 'Controlo total',
                    onTap: () => setState(() => aiMode = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('INFORMAÇÕES GERAIS'),
          const SizedBox(height: 14),
          _LabeledInput(
            label: 'Título do quiz',
            controller: title,
            hint: 'Introduza o nome do quiz',
          ),
          const SizedBox(height: 14),
          _LabeledInput(label: 'Tema principal', controller: topic),
          const SizedBox(height: 16),
          const Text(
            'Dificuldade',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _DifficultySelector(
            value: difficulty,
            onChanged: (v) => setState(() => difficulty = v),
          ),
          const SizedBox(height: 18),
          const Text(
            'Categoria',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _CategoryDropdown(
            value: category,
            values: categories,
            onChanged: (value) => setState(() => category = value),
          ),
          const SizedBox(height: 30),
          const _SectionTitle('CONFIGURAÇÃO DA IA'),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Número de perguntas',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$questionCount',
                style: const TextStyle(
                  color: AppColors.wine,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: questionCount.toDouble(),
            min: 5,
            max: 20,
            divisions: 15,
            activeColor: AppColors.wine,
            inactiveColor: AppColors.borderLight,
            onChanged: (value) => setState(() => questionCount = value.round()),
          ),
          const SizedBox(height: 16),
          _LabeledInput(
            label: 'Contexto adicional (opcional)',
            controller: contextInfo,
            hint:
                'Ex: focar no período 1990–2000 e nos impactos da inflação no consumo familiar.',
            minLines: 3,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: .96),
            border: const Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(
                    aiMode ? 'Gerar quiz com IA' : 'Guardar questionário',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'O quiz será criado e enviado para aprovação da equipa editorial antes de ser publicado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : AppColors.card,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.wine : AppColors.muted,
                  size: 22,
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.wine : AppColors.border,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
    style: const TextStyle(
      color: AppColors.textSecondary,
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

  const _LabeledInput({
    required this.label,
    required this.controller,
    this.hint,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 5,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.wine),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
    const labels = ['Fácil', 'Médio', 'Difícil'];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4EA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: value == i
                          ? AppColors.wine
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
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

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _CategoryDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: const InputDecoration(
        filled: false,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.wine),
        ),
      ),
    );
  }
}
