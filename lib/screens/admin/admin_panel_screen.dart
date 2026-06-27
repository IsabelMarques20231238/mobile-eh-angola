import 'package:flutter/material.dart';
import 'create_content_screen.dart';
import 'create_quiz_screen.dart';
import 'members_management_screen.dart';
import 'reports_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

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
          'Painel de Admin',
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
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
        children: [
          const _MetricGrid(),
          const SizedBox(height: 14),
          const _ApprovalAlert(),
          const SizedBox(height: 18),
          const _SectionTitle('ACÇÕES RÁPIDAS'),
          const SizedBox(height: 12),
          _QuickActionsGrid(
            onCreateContent: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateContentScreen()),
            ),
            onCreateQuiz: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateQuizScreen()),
            ),
            onMembers: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MembersManagementScreen(),
              ),
            ),
            onReports: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('ACTIVIDADE RECENTE'),
          const SizedBox(height: 8),
          const _RecentActivity(
            color: AppColors.green,
            title: 'Artigo "Indústria Têxtil" publicado',
            time: 'Há 2h',
          ),
          const _RecentActivity(
            color: Color(0xFFF59E0B),
            title: 'Novo quiz sugerido por João',
            time: 'Há 5h',
          ),
          const _RecentActivity(
            color: AppColors.red,
            title: 'Comentário denunciado em Fórum',
            time: 'Há 1d',
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 4),
    );
  }

  void _showFeedback(BuildContext context, String label) {
    showAppToast(context, label, type: AppToastType.success);
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'MEMBROS', value: '248'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MetricCard(label: 'QUIZZES ACTIVOS', value: '12'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'PENDENTES', value: '3'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MetricCard(label: 'PUBLICADOS', value: '89'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E7EC),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.wine,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalAlert extends StatelessWidget {
  const _ApprovalAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: Color(0xFFD97900),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '3 quizzes aguardam\naprovação',
              style: TextStyle(
                color: Color(0xFFC76500),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(
            width: 83,
            height: 28,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC45A00),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Rever agora'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onCreateContent;
  final VoidCallback onCreateQuiz;
  final VoidCallback onMembers;
  final VoidCallback onReports;

  const _QuickActionsGrid({
    required this.onCreateContent,
    required this.onCreateQuiz,
    required this.onMembers,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.note_add_outlined,
                label: 'Criar conteúdo',
                onTap: onCreateContent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.quiz_outlined,
                label: 'Criar quiz',
                onTap: onCreateQuiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.group_outlined,
                label: 'Gerir membros',
                onTap: onMembers,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.error_outline,
                label: 'Ver denúncias',
                onTap: onReports,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.wine, size: 23),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final Color color;
  final String title;
  final String time;

  const _RecentActivity({
    required this.color,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
