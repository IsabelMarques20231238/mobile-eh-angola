import 'package:flutter/material.dart';
import '../admin/admin_panel_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_items_screen.dart';
import 'settings_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 55,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.wine, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
        ],
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 22, 12, 28),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 20),
          const _StatsRow(),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'ACTIVIDADE RECENTE'),
          const SizedBox(height: 10),
          const _ActivityCard(
            title: 'Inflação em Angola',
            meta: '7/10 · Eco.',
            date: '12 Abr',
          ),
          const _ActivityCard(
            title: 'Ciclo do Petróleo',
            meta: '9/10 · História',
            date: '08 Abr',
          ),
          const _ActivityCard(
            title: 'Bancos Centrais',
            meta: '6/10 · Política',
            date: '05 Abr',
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'CONTEÚDO GUARDADO',
            action: 'Ver todos',
            onActionTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedItemsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SavedContentRow(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedItemsScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const _ActionButtons(),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 4),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final user = AuthState.instance.user;
    final initials = AuthState.instance.initials;
    final role = AuthState.instance.displayRole.toUpperCase();
    final name = user?.name ?? 'Utilizador';
    final profession = user?.profession ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.winePill,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.wine,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.wine,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ),
        if (profession.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            _professionLabel(profession),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (user?.bio != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              user!.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _professionLabel(String p) {
    switch (p) {
      case 'ESTUDANTE': return 'Estudante';
      case 'PROFESSOR': return 'Professor';
      default: return p;
    }
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(value: '14', label: 'Quizzes'),
          _Stat(value: '89%', label: 'Acerto médio'),
          _Stat(value: '32', label: 'Contribuições'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.wine,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.wine,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String meta;
  final String date;

  const _ActivityCard({
    required this.title,
    required this.meta,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 9, 14, 8),
      color: const Color(0xFFE8E8EC),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SavedContentRow extends StatelessWidget {
  final VoidCallback? onTap;

  const _SavedContentRow({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SavedCard(
            title: 'O Kwanza Colonial',
            meta: '4 min leitura',
            color: const Color(0xFF0A0A0A),
            icon: Icons.account_balance,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SavedCard(
            title: 'Urbanismo e Economia',
            meta: '6 min leitura',
            color: const Color(0xFF1B2D2A),
            icon: Icons.person,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _SavedCard extends StatelessWidget {
  final String title;
  final String meta;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SavedCard({
    required this.title,
    required this.meta,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
      height: 112,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            color: color,
            child: Center(
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: .18),
                size: 34,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Text(
              meta,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileButton(
            label: 'Editar Perfil',
            background: AppColors.wine,
            foreground: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileButton(
            label: 'Definições',
            background: AppColors.card,
            foreground: AppColors.wine,
            border: AppColors.wine,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileButton(
            label: 'Painel De Admin',
            background: const Color(0xFFD67811),
            foreground: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ProfileButton(
            label: 'Terminar Sessão',
            background: const Color(0xFFD43B27),
            foreground: Colors.white,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Terminar Sessão'),
                content: const Text('Tem a certeza que deseja sair da sua conta?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await AuthService(ApiClient.instance).logout();
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Sair',
                      style: TextStyle(color: Color(0xFFD43B27)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onPressed;

  const _ProfileButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: border == null ? BorderSide.none : BorderSide(color: border!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          padding: EdgeInsets.zero,
        ),
        child: Text(label),
      ),
    );
  }
}
