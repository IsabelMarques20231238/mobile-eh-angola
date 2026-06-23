import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selected = 0;
  bool _allRead = false;
  static const _filters = [
    'Tudo',
    'Fórum',
    'Economia',
    'História',
    'Em Destaque',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 56,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificações',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.wine, size: 19),
            onPressed: () => setState(() => _allRead = true),
          ),
          const SizedBox(width: 8),
        ],
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = index == _selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selected = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.winePill : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: active
                            ? AppColors.wine
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'HOJE',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          _NotificationTile(
            unread: !_allRead,
            icon: Icons.quiz_outlined,
            color: AppColors.wine,
            title: 'Novo quiz disponível: Reforma Monetária 1999 - Médio',
            time: 'Há 10 min',
          ),
          _NotificationTile(
            unread: !_allRead,
            icon: Icons.forum_outlined,
            color: Color(0xFF2B6CB0),
            title: 'Prof. Ana Silva respondeu ao teu tópico',
            time: 'Há 45 min',
            avatar: true,
          ),
          const _NotificationTile(
            unread: false,
            icon: Icons.article_outlined,
            color: AppColors.green,
            title: 'Novo artigo: Inflação e o custo de vida em Angola',
            time: 'Há 2 horas',
            thumbnail: true,
          ),
          const _NotificationTile(
            unread: false,
            icon: Icons.workspace_premium_outlined,
            color: Color(0xFFF5A400),
            title: 'O teu quiz foi aprovado e publicado',
            time: 'Há 5 horas',
          ),
          const _NotificationTile(
            unread: false,
            icon: Icons.person_outline,
            color: AppColors.muted,
            title: 'Completa o teu perfil para melhorar as recomendações',
            time: 'Ontem',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final bool unread;
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final bool avatar;
  final bool thumbnail;

  const _NotificationTile({
    required this.unread,
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    this.avatar = false,
    this.thumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: unread ? AppColors.wineBg : AppColors.card,
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 11,
            child: unread
                ? const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.wine,
                    ),
                  )
                : null,
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (avatar || thumbnail) ...[
            const SizedBox(width: 10),
            avatar ? const _AvatarPreview() : const _ThumbPreview(),
          ],
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF2F536B),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}

class _ThumbPreview extends StatelessWidget {
  const _ThumbPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF17343A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
    );
  }
}
