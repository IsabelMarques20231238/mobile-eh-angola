import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'member_activity_screen.dart';
import 'member_models.dart';

Future<Member?> showMemberActionsSheet(
  BuildContext context,
  Member member,
) {
  return showModalBottomSheet<Member>(
    context: context,
    backgroundColor: const Color(0xFFF4F3F6),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _MemberActionsSheet(member: member),
  );
}

class _MemberActionsSheet extends StatefulWidget {
  final Member member;

  const _MemberActionsSheet({required this.member});

  @override
  State<_MemberActionsSheet> createState() => _MemberActionsSheetState();
}

class _MemberActionsSheetState extends State<_MemberActionsSheet> {
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  void _close([Member? result]) => Navigator.pop(context, result ?? _member);

  void _feedback(String message) {
    showAppToast(context, message, type: AppToastType.success);
  }

  void _activate() {
    setState(() => _member = _member.activate());
    _feedback('${_member.name} foi activado');
    _close();
  }

  void _promoteToAdmin() {
    setState(() => _member = _member.copyWith(role: MemberRole.admin));
    _feedback('${_member.name} promovido a Admin');
    _close();
  }

  void _promoteToWriter() {
    setState(() => _member = _member.copyWith(role: MemberRole.writer));
    _feedback('${_member.name} promovido a Escritor');
    _close();
  }

  Future<void> _confirmSuspend() async {
    final confirmed = await showAppDialog(
      context,
      title: 'Suspender membro?',
      message: '${_member.name} deixará de aceder à plataforma até ser activado novamente.',
      confirmLabel: 'Suspender',
      cancelLabel: 'Cancelar',
      type: AppDialogType.danger,
    );
    if (!confirmed || !mounted) return;
    setState(() => _member = _member.suspend());
    _feedback('${_member.name} foi suspenso');
    _close();
  }

  Future<void> _openActivity() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberActivityScreen(member: _member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D8DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SheetHeader(member: _member),
            const SizedBox(height: 22),
            if (_member.isSuspended) ..._blockedActions() else ..._activeActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _blockedActions() {
    return [
      _SheetButton.filled(
        label: 'Activar membro',
        onPressed: _activate,
      ),
      const SizedBox(height: 10),
      _SheetButton.outlinedNeutral(
        label: 'Ver actividade',
        onPressed: _openActivity,
      ),
    ];
  }

  List<Widget> _activeActions() {
    final showAdmin = _member.role != MemberRole.admin;
    final showWriter = _member.role != MemberRole.writer;

    return [
      if (showAdmin) ...[
        _SheetButton.filled(
          label: 'Promover a Admin',
          onPressed: _promoteToAdmin,
        ),
        const SizedBox(height: 10),
      ],
      if (showWriter) ...[
        _SheetButton.outlinedWine(
          label: 'Promover a Escritor',
          onPressed: _promoteToWriter,
        ),
        const SizedBox(height: 10),
      ],
      _SheetButton.filledDanger(
        label: 'Suspender membro',
        onPressed: _confirmSuspend,
      ),
      const SizedBox(height: 10),
      _SheetButton.outlinedNeutral(
        label: 'Ver actividade',
        onPressed: _openActivity,
      ),
    ];
  }
}

class _SheetHeader extends StatelessWidget {
  final Member member;

  const _SheetHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.wineBg,
          backgroundImage: NetworkImage(member.avatarUrl),
          child: Icon(
            Icons.person,
            color: AppColors.wine.withValues(alpha: .4),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: member.isSuspended
                      ? AppColors.muted
                      : AppColors.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: member.isSuspended
                      ? AppColors.muted
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final Color? borderColor;

  const _SheetButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  factory _SheetButton.filled({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _SheetButton(
      label: label,
      onPressed: onPressed,
      background: AppColors.wine,
      foreground: Colors.white,
    );
  }

  factory _SheetButton.outlinedWine({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _SheetButton(
      label: label,
      onPressed: onPressed,
      background: AppColors.card,
      foreground: AppColors.wine,
      borderColor: AppColors.wine,
    );
  }

  factory _SheetButton.filledDanger({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _SheetButton(
      label: label,
      onPressed: onPressed,
      background: const Color(0xFFD43B27),
      foreground: Colors.white,
    );
  }

  factory _SheetButton.outlinedNeutral({
    required String label,
    required VoidCallback onPressed,
  }) {
    return _SheetButton(
      label: label,
      onPressed: onPressed,
      background: AppColors.card,
      foreground: AppColors.textSecondary,
      borderColor: AppColors.border,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.2)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
