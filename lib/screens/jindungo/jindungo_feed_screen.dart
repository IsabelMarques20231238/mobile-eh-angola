import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class JindungoFeedScreen extends StatefulWidget {
  const JindungoFeedScreen({super.key});

  @override
  State<JindungoFeedScreen> createState() => _JindungoFeedScreenState();
}

class _JindungoFeedScreenState extends State<JindungoFeedScreen> {
  int _selectedFilter = 0;

  static const _filters = [
    'Todos',
    'Economia',
    'História',
    'Política',
    'Finanças',
  ];
  static const _items = [
    _JindungoItem(
      title: 'A Crise da Moeda em 1991',
      subtitle: 'Dr. Manuel Santos · 5 min',
      unlocked: true,
      hot: true,
      imageColor: Color(0xFF6E3E25),
      icon: Icons.account_balance,
    ),
    _JindungoItem(
      title: 'Ouro e Reservas: 2024',
      subtitle: 'Acesso em 45 dias',
      unlocked: false,
      hot: false,
      imageColor: Color(0xFF14100C),
      icon: Icons.lock_outline,
    ),
    _JindungoItem(
      title: 'Reformas de 1975',
      subtitle: 'Arquivo Nacional · 8 min',
      unlocked: true,
      hot: true,
      imageColor: Color(0xFF4D3B33),
      icon: Icons.history_edu,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 68,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.wine, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jindungo',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _ProgressHeader(),
          _FilterStrip(
            filters: _filters,
            selected: _selectedFilter,
            onSelected: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: 10),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _JindungoCard(item: item),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _AccessCard(),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Progresso: 45/90 dias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '45 dias restantes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: .5,
              backgroundColor: Colors.white.withValues(alpha: .28),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelected;

  const _FilterStrip({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final active = index == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(index),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.wine : AppColors.wineBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppColors.wine : AppColors.border,
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JindungoCard extends StatelessWidget {
  final _JindungoItem item;

  const _JindungoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Thumbnail(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.unlocked
                        ? AppColors.textSecondary
                        : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          item.unlocked
              ? TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ler',
                    style: TextStyle(
                      color: AppColors.wine,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(70, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: const BorderSide(color: AppColors.wine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    'Solicitar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final _JindungoItem item;

  const _Thumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.imageColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              item.icon,
              color: Colors.white.withValues(alpha: item.unlocked ? .72 : .38),
              size: 28,
            ),
          ),
          if (item.hot)
            Positioned(
              left: -5,
              top: -5,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.wine,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          if (!item.unlocked)
            const Center(
              child: Icon(Icons.lock_outline, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.wine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF7A45),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Como aceder ao Jindungo',
                style: TextStyle(
                  color: AppColors.wine,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _RequirementRow(
            icon: Icons.check_circle,
            text: 'Conta activa há 45+ dias',
            done: true,
          ),
          const SizedBox(height: 10),
          const _RequirementRow(
            icon: Icons.lock_outline,
            text: '90 dias de conta activa',
            done: false,
          ),
          const SizedBox(height: 10),
          const _RequirementRow(
            icon: Icons.check_circle,
            text: 'Perfil verificado',
            done: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                'Solicitar acesso',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool done;

  const _RequirementRow({
    required this.icon,
    required this.text,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: done ? AppColors.green : AppColors.muted, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: done ? AppColors.textMain : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _JindungoItem {
  final String title;
  final String subtitle;
  final bool unlocked;
  final bool hot;
  final Color imageColor;
  final IconData icon;

  const _JindungoItem({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.hot,
    required this.imageColor,
    required this.icon,
  });
}
