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
    final c = context.c;
    final isPrivate = visibility == TopicVisibility.privado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFFFFF3CD) : c.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPrivate ? 'Privado' : 'Público',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPrivate ? const Color(0xFF8A6D1D) : c.muted,
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
  final bool saved;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final bool compact;
  final bool locked;

  const ForumInteractionBar({
    super.key,
    required this.likes,
    required this.liked,
    required this.comments,
    this.saved = false,
    this.onLike,
    this.onComment,
    this.onSave,
    this.compact = false,
    this.locked = false,
  });

  String _commentLabel(int count) => '$count';

  String _likeLabel(int count) => '$count';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final statsSize = compact ? 12.0 : 13.0;
    final actionSize = compact ? 14.0 : 15.0;
    final iconSize = compact ? 18.0 : 20.0;
    final showStats = likes > 0 || comments > 0;

    return Column(
      children: [
        if (showStats) ...[
          Row(
            children: [
              if (likes > 0) ...[
                Icon(
                  Icons.favorite_rounded,
                  size: compact ? 14 : 15,
                  color: c.wine,
                ),
                const SizedBox(width: 5),
                Text(
                  _likeLabel(likes),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: statsSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (likes > 0 && comments > 0) const SizedBox(width: 14),
              if (comments > 0) ...[
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: compact ? 13 : 14,
                  color: c.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  _commentLabel(comments),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: statsSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (!locked) ...[
            SizedBox(height: compact ? 8 : 10),
            Divider(
              height: 1,
              thickness: 1,
              color: c.border,
            ),
            SizedBox(height: compact ? 2 : 4),
          ],
        ],
        if (!locked)
          Row(
            children: [
              Expanded(
                child: _ForumActionButton(
                  icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
    final color = active ? activeColor : context.c.textSecondary;

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
        const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.muted),
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
    final c = context.c;
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          top: BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
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
                color: active ? c.wine : c.wineBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? c.wine : c.border),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : c.wine,
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

// ── App Toast ────────────────────────────────────────────────────────────────

enum AppToastType { success, error, info, warning }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
}) {
  final cfg = _toastConfig(type);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
        content: _AppToastWidget(message: message, cfg: cfg),
      ),
    );
}

class _ToastConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  const _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.borderColor,
  });
}

_ToastConfig _toastConfig(AppToastType type) => switch (type) {
      AppToastType.success => const _ToastConfig(
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF15945B),
          iconBg: Color(0xFFDCFCE7),
          borderColor: Color(0xFFBBF7D0),
        ),
      AppToastType.error => const _ToastConfig(
          icon: Icons.error_rounded,
          iconColor: Color(0xFFB83357),
          iconBg: Color(0xFFFBE7EC),
          borderColor: Color(0xFFF5C2CF),
        ),
      AppToastType.warning => const _ToastConfig(
          icon: Icons.warning_rounded,
          iconColor: Color(0xFFB45309),
          iconBg: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
        ),
      AppToastType.info => const _ToastConfig(
          icon: Icons.info_rounded,
          iconColor: Color(0xFF7B173F),
          iconBg: Color(0xFFFDF0F5),
          borderColor: Color(0xFFF8D9E4),
        ),
    };

class _AppToastWidget extends StatelessWidget {
  final String message;
  final _ToastConfig cfg;
  const _AppToastWidget({required this.message, required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cfg.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cfg.icon, color: cfg.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF151114),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Dialog ───────────────────────────────────────────────────────────────

enum AppDialogType { danger, warning, info }

Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  AppDialogType type = AppDialogType.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _AppDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      type: type,
    ),
  );
  return result ?? false;
}

class _AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final AppDialogType type;

  const _AppDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg, confirmBg) = switch (type) {
      AppDialogType.danger => (
          Icons.delete_outline_rounded,
          const Color(0xFFB83357),
          const Color(0xFFFBE7EC),
          const Color(0xFFB83357),
        ),
      AppDialogType.warning => (
          Icons.warning_amber_rounded,
          const Color(0xFFB45309),
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
      AppDialogType.info => (
          Icons.info_outline_rounded,
          const Color(0xFF7B173F),
          const Color(0xFFFDF0F5),
          const Color(0xFF7B173F),
        ),
    };

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF151114),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF686066),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF686066),
                      side: const BorderSide(color: Color(0xFFF0E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmBg,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
