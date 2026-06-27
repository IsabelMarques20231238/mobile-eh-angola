import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import 'member_actions_sheet.dart';
import 'member_models.dart';

class MembersManagementScreen extends StatefulWidget {
  const MembersManagementScreen({super.key});

  @override
  State<MembersManagementScreen> createState() =>
      _MembersManagementScreenState();
}

class _MembersManagementScreenState extends State<MembersManagementScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  MemberFilter _filter = MemberFilter.all;
  List<Member> _members = List.of(MemberData.members);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Member> get _visibleMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _members.where((member) {
      if (!memberMatchesFilter(member, _filter)) return false;
      if (query.isEmpty) return true;
      return member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.organization.toLowerCase().contains(query);
    }).toList();
  }

  void _applyFilter(MemberFilter filter) => setState(() => _filter = filter);

  void _focusSearch() {
    _searchFocus.requestFocus();
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _SortTile(
                label: 'Nome (A–Z)',
                onTap: () {
                  setState(() {
                    _members.sort((a, b) => a.name.compareTo(b.name));
                  });
                  Navigator.pop(context);
                },
              ),
              _SortTile(
                label: 'Actividade recente',
                onTap: () {
                  Navigator.pop(context);
                  showAppToast(context, 'Ordenado por actividade', type: AppToastType.info);
                },
              ),
              _SortTile(
                label: 'Data de registo',
                onTap: () {
                  Navigator.pop(context);
                  showAppToast(context, 'Ordenado por registo', type: AppToastType.info);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMember(Member member) async {
    final updated = await showMemberActionsSheet(context, member);
    if (updated == null || !mounted) return;
    setState(() {
      final index = _members.indexWhere((m) => m.id == updated.id);
      if (index != -1) _members[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleMembers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Membros',
          style: TextStyle(
            color: AppColors.wine,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.wine, size: 22),
            onPressed: _showSortSheet,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.wine, size: 22),
            onPressed: _focusSearch,
          ),
          const SizedBox(width: 4),
        ],
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'TOTAL',
                    value: '${MemberData.totalCount}',
                    valueColor: AppColors.textMain,
                    borderColor: AppColors.wine,
                    selected: _filter == MemberFilter.all,
                    onTap: () => _applyFilter(MemberFilter.all),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'SUSPENSOS',
                    value: '${MemberData.suspendedCount}',
                    valueColor: const Color(0xFFD43B27),
                    borderColor: const Color(0xFFD43B27),
                    selected: _filter == MemberFilter.suspended,
                    onTap: () => _applyFilter(MemberFilter.suspended),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'ADMINS',
                    value: '${MemberData.adminCount}',
                    valueColor: AppColors.green,
                    borderColor: AppColors.green,
                    selected: _filter == MemberFilter.admins,
                    onTap: () => _applyFilter(MemberFilter.admins),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final filter in MemberFilter.values) ...[
                  _FilterChip(
                    label: filter.label,
                    selected: _filter == filter,
                    onTap: () => _applyFilter(filter),
                  ),
                  if (filter != MemberFilter.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou email...',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.muted,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFEEEDF2),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.wine, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visible.isEmpty
                ? const _EmptyMembersState()
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 76,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) => _MemberTile(
                      member: visible[index],
                      onTap: () => _openMember(visible[index]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? borderColor : AppColors.borderLight,
              width: selected ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Container(
                height: 3,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.wine : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.wine : AppColors.borderLight,
            ),
            boxShadow: selected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = member.isSuspended;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _MemberAvatar(member: member),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted
                                ? AppColors.muted
                                : AppColors.textMain,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(role: member.role),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${member.email} · ${member.organization}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted ? AppColors.muted : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.winePill,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final Member member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: member.isSuspended
            ? Border.all(color: AppColors.red, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          member.isSuspended ? 10 : 12,
        ),
        child: Image.network(
          member.avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: AppColors.wineBg,
            child: Icon(
              Icons.person,
              color: AppColors.wine.withValues(alpha: .6),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final MemberRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      MemberRole.admin => (const Color(0xFFE8F7EF), AppColors.green),
      MemberRole.writer => (const Color(0xFFF3E8F7), AppColors.wine),
      MemberRole.suspended => (AppColors.errorLight, AppColors.red),
      MemberRole.member => (AppColors.winePill, AppColors.wine),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Nenhum membro encontrado',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SortTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: onTap,
    );
  }
}
