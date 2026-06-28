import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_state.dart';
import '../services/notification_state.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final bool showSubtitle;
  const AppLogo({super.key, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Economia com História',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 3),
          const Text(
            'Angola',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * .22),
      ),
      child: Icon(Icons.school_outlined, color: Colors.white, size: size * .58),
    );
  }
}

class EhAngolaHeader extends StatelessWidget {
  final TextEditingController? searchController;
  final bool showSearch;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;

  const EhAngolaHeader({
    super.key,
    this.searchController,
    this.showSearch = false,
    this.onSearchChanged,
    this.onSearchTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const _EhHeaderMark(size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'EH.',
                          style: TextStyle(
                            color: c.wine,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(text: 'Angola'),
                      ],
                    ),
                    style: TextStyle(
                      color: c.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.search_rounded,
                  onTap: onSearchTap,
                  active: showSearch,
                ),
                ListenableBuilder(
                  listenable: AuthState.instance,
                  builder: (context, _) {
                    if (!AuthState.instance.isAuthenticated) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 10),
                        _HeaderNotificationButton(onTap: onNotificationsTap),
                      ],
                    );
                  },
                ),
              ],
            ),
            if (showSearch && searchController != null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onSearchChanged,
                style: TextStyle(fontSize: 14, color: c.textMain),
                decoration: InputDecoration(
                  hintText: 'Pesquisar no forum...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: c.muted,
                    size: 22,
                  ),
                  suffixIcon: searchController!.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            searchController!.clear();
                            onSearchChanged?.call('');
                          },
                        ),
                  filled: true,
                  fillColor: c.bg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.wine),
                  ),
                  hintStyle: TextStyle(color: c.muted, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EhAngolaScaffold extends StatelessWidget {
  final Widget body;
  final int bottomNavIndex;
  final TextEditingController? searchController;
  final bool showSearch;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final Color? backgroundColor;

  const EhAngolaScaffold({
    super.key,
    required this.body,
    this.bottomNavIndex = 0,
    this.searchController,
    this.showSearch = false,
    this.onSearchChanged,
    this.onSearchTap,
    this.onNotificationsTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.c.bg,
      body: SafeArea(
        child: Column(
          children: [
            EhAngolaHeader(
              searchController: searchController,
              showSearch: showSearch,
              onSearchChanged: onSearchChanged,
              onSearchTap: onSearchTap,
              onNotificationsTap: onNotificationsTap,
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavMock(index: bottomNavIndex),
    );
  }
}

class _EhHeaderMark extends StatelessWidget {
  final double size;

  const _EhHeaderMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: size * .5,
      ),
    );
  }
}

class _HeaderNotificationButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _HeaderNotificationButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationState.instance,
      builder: (context, _) {
        final c = context.c;
        final count = NotificationState.instance.unreadCount;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: c.wine,
                    size: 23,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE60046),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: active ? c.winePill : c.bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active ? c.winePill : c.border,
          ),
        ),
        child: Icon(
          icon,
          color: active ? c.wine : c.textSecondary,
          size: 23,
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        BrandMark(size: 26),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ECONOMIA COM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              'HISTÓRIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const FaIcon(
          FontAwesomeIcons.google,
          size: 16,
          color: Color(0xFF4285F4),
        ),
        label: const Text('Continuar com Google'),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight)),
      ],
    );
  }
}

class CenteredIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool check;
  const CenteredIconBox({
    super.key,
    required this.icon,
    this.size = 58,
    this.check = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: size * .45),
        ),
        if (check)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}

class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;

  const TextLink({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.fontSize = 11,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? AppColors.primary,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '© 2026 Economia com História — Angola',
      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final Color color;
  const Pill(
    this.text, {
    super.key,
    this.selected = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : c.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? color : c.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : c.textSecondary,
        ),
      ),
    );
  }
}

class BottomNavMock extends StatelessWidget {
  final int index;
  const BottomNavMock({super.key, this.index = 0});

  static const _routes = ['/feed', '/forum', '/quiz', '/subscriptions', '/profile'];
  static const _labels = ['Feed', 'Fórum', 'Quiz', 'Subscrições', 'Perfil'];

  static const _icons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.comments,
    FontAwesomeIcons.circleQuestion,
    FontAwesomeIcons.heart,
    FontAwesomeIcons.user,
  ];

  static const _activeIcons = [
    FontAwesomeIcons.solidHouse,
    FontAwesomeIcons.solidComments,
    FontAwesomeIcons.solidCircleQuestion,
    FontAwesomeIcons.solidHeart,
    FontAwesomeIcons.solidUser,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BottomNavigationBar(
      currentIndex: index,
      backgroundColor: c.card,
      onTap: (i) {
        final route = _routes[i];
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushReplacementNamed(context, route);
      },
      selectedItemColor: c.wine,
      unselectedItemColor: c.muted,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
      type: BottomNavigationBarType.fixed,
      items: [
        for (var i = 0; i < _icons.length; i++)
          BottomNavigationBarItem(
            icon: FaIcon(_icons[i], size: 20),
            activeIcon: FaIcon(_activeIcons[i], size: 26),
            label: _labels[i],
          ),
      ],
    );
  }
}
