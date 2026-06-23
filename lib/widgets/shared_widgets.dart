import 'package:flutter/material.dart';
import '../models/forum_models.dart';
import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color bg;
  final Color fg;

  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.bg = AppColors.winePill,
    this.fg = AppColors.wine,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: size * 0.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CategoryTag extends StatelessWidget {
  final TopicCategory category;
  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final label = switch (category) {
      TopicCategory.historia => 'História',
      TopicCategory.petroleo => 'Petróleo',
      TopicCategory.politica => 'Política',
      TopicCategory.tudo => 'Economia',
      TopicCategory.economia => 'Economia',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.winePill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.wine,
        ),
      ),
    );
  }
}

class VisibilityBadge extends StatelessWidget {
  final TopicVisibility visibility;
  const VisibilityBadge({super.key, required this.visibility});

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == TopicVisibility.privado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF3CD) : AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPrivate ? 'Privado' : 'Público',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPrivate ? const Color(0xFF8A6D1D) : AppColors.muted,
        ),
      ),
    );
  }
}

class PinnedLabel extends StatelessWidget {
  const PinnedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.push_pin_outlined, size: 15, color: AppColors.wine),
        SizedBox(width: 6),
        Text(
          'FIXADO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.wine,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class ForumInteractionBar extends StatelessWidget {
  final int likes;
  final bool liked;
  final int comments;
  final int savedCount;
  final bool saved;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final bool compact;

  const ForumInteractionBar({
    super.key,
    required this.likes,
    required this.liked,
    required this.comments,
    this.savedCount = 0,
    this.saved = false,
    this.onLike,
    this.onComment,
    this.onSave,
    this.compact = false,
  });

  static const _statsColor = Color(0xFF65676B);

  String _commentLabel(int count) =>
      count == 1 ? '1 comentário' : '$count comentários';

  String _savedLabel(int count) =>
      count == 1 ? '1 guardado' : '$count guardados';

  String _likeLabel(int count) =>
      count == 1 ? '1 gosto' : '$count gostos';

  @override
  Widget build(BuildContext context) {
    final statsSize = compact ? 12.0 : 13.0;
    final actionSize = compact ? 14.0 : 15.0;
    final iconSize = compact ? 18.0 : 20.0;
    final showStats = likes > 0 || comments > 0 || savedCount > 0;

    return Column(
      children: [
        if (showStats) ...[
          Row(
            children: [
              if (likes > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: compact ? 14 : 15,
                      color: AppColors.wine,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _likeLabel(likes),
                      style: TextStyle(
                        color: _statsColor,
                        fontSize: statsSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              if (comments > 0)
                Text(
                  _commentLabel(comments),
                  style: TextStyle(
                    color: _statsColor,
                    fontSize: statsSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (comments > 0 && savedCount > 0) const SizedBox(width: 12),
              if (savedCount > 0)
                Text(
                  _savedLabel(savedCount),
                  style: TextStyle(
                    color: _statsColor,
                    fontSize: statsSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLight.withValues(alpha: .85),
          ),
          SizedBox(height: compact ? 2 : 4),
        ],
        Row(
          children: [
            Expanded(
              child: _ForumActionButton(
                icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: 'Gosto',
                active: liked,
                activeColor: AppColors.wine,
                iconSize: iconSize,
                fontSize: actionSize,
                onTap: onLike,
              ),
            ),
            Expanded(
              child: _ForumActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comentar',
                iconSize: iconSize,
                fontSize: actionSize,
                onTap: onComment,
              ),
            ),
            Expanded(
              child: _ForumActionButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_border_rounded,
                label: 'Guardar',
                active: saved,
                activeColor: AppColors.wine,
                iconSize: iconSize,
                fontSize: actionSize,
                onTap: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ForumActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color activeColor;
  final double iconSize;
  final double fontSize;

  const _ForumActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.activeColor = AppColors.wine,
    this.iconSize = 20,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : const Color(0xFF65676B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int comments;
  final int likes;
  final bool showSave;

  const StatsRow({
    super.key,
    required this.comments,
    required this.likes,
    this.showSave = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.muted),
        const SizedBox(width: 3),
        Text(
          '$comments',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.muted),
        const SizedBox(width: 3),
        Text(
          '$likes',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        if (showSave) ...[
          const SizedBox(width: 10),
          const Icon(Icons.bookmark_border, size: 16, color: AppColors.muted),
          const SizedBox(width: 3),
          const Text(
            'Guardar',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class ChipFilterBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const ChipFilterBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final active = i == selected;
          return InkWell(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.wine : AppColors.wineBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.wine : AppColors.border,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.wine,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemCount: labels.length,
      ),
    );
  }
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeThumbColor: AppColors.wine,
      onChanged: onChanged,
    );
  }
}

void showAppToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
