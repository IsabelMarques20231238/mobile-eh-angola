import 'package:flutter/material.dart';
import '../../services/theme_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool twoFactor = false;
  bool newContent = true;
  bool replies = true;
  bool quizApproved = true;
  bool weeklySummary = false;
  bool publicProfile = true;
  bool ranking = true;
  bool activity = true;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _themeModeLabel => switch (ThemeState.instance.mode) {
    ThemeMode.dark => 'Escuro',
    ThemeMode.system => 'Sistema',
    _ => 'Claro',
  };

  void _cycleTheme() {
    final next = switch (ThemeState.instance.mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      _ => ThemeMode.light,
    };
    ThemeState.instance.setMode(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: ThemeState.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: c.bg,
          appBar: AppBar(
            backgroundColor: c.card,
            toolbarHeight: 55,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: c.wine, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Definições',
              style: TextStyle(
                color: c.wine,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            shape: Border(bottom: BorderSide(color: c.border)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 26),
            children: [
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    title: 'Palavra-passe',
                    value: 'Alterar',
                    chevron: true,
                    onTap: () => _toast('Alteração de palavra-passe'),
                  ),
                  _SettingsRow(
                    title: 'Email',
                    value: 'carlos@isptec.co.ao',
                    chevron: true,
                    onTap: () => _toast('Gestão de email'),
                  ),
                  _SettingsRow(
                    title: 'Verificação em 2 passos',
                    toggleValue: twoFactor,
                    onToggle: (v) => setState(() => twoFactor = v),
                  ),
                  _SettingsRow(
                    title: 'Sessões activas',
                    value: '1 dispositivo',
                    chevron: true,
                    onTap: () => _toast('Sessões activas'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('NOTIFICAÇÕES'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    title: 'Novo conteúdo',
                    toggleValue: newContent,
                    onToggle: (v) => setState(() => newContent = v),
                  ),
                  _SettingsRow(
                    title: 'Respostas',
                    toggleValue: replies,
                    onToggle: (v) => setState(() => replies = v),
                  ),
                  _SettingsRow(
                    title: 'Quiz aprovado',
                    toggleValue: quizApproved,
                    onToggle: (v) => setState(() => quizApproved = v),
                  ),
                  _SettingsRow(
                    title: 'Resumo semanal',
                    toggleValue: weeklySummary,
                    onToggle: (v) => setState(() => weeklySummary = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('PRIVACIDADE'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    title: 'Perfil público',
                    toggleValue: publicProfile,
                    onToggle: (v) => setState(() => publicProfile = v),
                  ),
                  _SettingsRow(
                    title: 'Aparecer no ranking',
                    toggleValue: ranking,
                    onToggle: (v) => setState(() => ranking = v),
                  ),
                  _SettingsRow(
                    title: 'Mostrar actividade',
                    toggleValue: activity,
                    onToggle: (v) => setState(() => activity = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('APARÊNCIA'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    title: 'Tema',
                    value: _themeModeLabel,
                    chevron: true,
                    onTap: _cycleTheme,
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavMock(index: 4),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: context.c.muted,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsRow> rows;
  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    color: context.c.card,
    child: Column(children: rows),
  );
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? value;
  final bool chevron;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.title,
    this.value,
    this.chevron = false,
    this.toggleValue,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: c.textMain,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (chevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: c.muted, size: 18),
            ],
            if (toggleValue != null)
              Switch(
                value: toggleValue!,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: c.wine,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: c.border,
              ),
          ],
        ),
      ),
    );
  }
}
