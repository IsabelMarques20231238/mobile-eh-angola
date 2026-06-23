enum MemberRole { admin, writer, member, suspended }

extension MemberRoleLabel on MemberRole {
  String get label => switch (this) {
    MemberRole.admin => 'Admin',
    MemberRole.writer => 'Escritor',
    MemberRole.member => 'Membro',
    MemberRole.suspended => 'Suspenso',
  };
}

class Member {
  final String id;
  final String name;
  final String email;
  final String organization;
  final MemberRole role;
  final MemberRole? roleBeforeSuspension;
  final String avatarUrl;
  final String joinedAt;
  final String lastActive;

  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.organization,
    required this.role,
    this.roleBeforeSuspension,
    required this.avatarUrl,
    this.joinedAt = 'Jan 2024',
    this.lastActive = 'Há 2 dias',
  });

  bool get isSuspended => role == MemberRole.suspended;
  bool get isActive => !isSuspended;

  Member copyWith({
    MemberRole? role,
    MemberRole? roleBeforeSuspension,
    bool clearRoleBeforeSuspension = false,
  }) {
    return Member(
      id: id,
      name: name,
      email: email,
      organization: organization,
      role: role ?? this.role,
      roleBeforeSuspension: clearRoleBeforeSuspension
          ? null
          : (roleBeforeSuspension ?? this.roleBeforeSuspension),
      avatarUrl: avatarUrl,
      joinedAt: joinedAt,
      lastActive: lastActive,
    );
  }

  Member suspend() {
    if (isSuspended) return this;
    return copyWith(
      role: MemberRole.suspended,
      roleBeforeSuspension: role,
    );
  }

  Member activate() {
    if (!isSuspended) return this;
    return copyWith(
      role: roleBeforeSuspension ?? MemberRole.member,
      clearRoleBeforeSuspension: true,
    );
  }
}

class MemberData {
  static const totalCount = 248;
  static const suspendedCount = 3;
  static const adminCount = 5;

  static final List<Member> members = [
    const Member(
      id: '1',
      name: 'Ana Paula Santos',
      email: 'ana.santos@minfin.gov.ao',
      organization: 'MINFIN',
      role: MemberRole.admin,
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Mar 2023',
      lastActive: 'Há 1h',
    ),
    const Member(
      id: '2',
      name: 'Elias Vunge',
      email: 'e.vunge@unisantos.ao',
      organization: 'UniSantos',
      role: MemberRole.suspended,
      roleBeforeSuspension: MemberRole.member,
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Ago 2023',
      lastActive: 'Há 3 semanas',
    ),
    const Member(
      id: '3',
      name: 'Maria Kassoma',
      email: 'm.kassoma@ucan.edu',
      organization: 'UCAN',
      role: MemberRole.member,
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Nov 2023',
      lastActive: 'Ontem',
    ),
    const Member(
      id: '4',
      name: 'Dr. Jorge Ndala',
      email: 'jorge.ndala@ua.ao',
      organization: 'Univ. Agostinho Neto',
      role: MemberRole.member,
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Fev 2024',
      lastActive: 'Há 4 dias',
    ),
    const Member(
      id: '5',
      name: 'Carlos Mendes',
      email: 'carlos@isptec.co.ao',
      organization: 'ISPTEC',
      role: MemberRole.member,
      avatarUrl:
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Dez 2023',
      lastActive: 'Há 5h',
    ),
    const Member(
      id: '6',
      name: 'Helena Mavinga',
      email: 'h.mavinga@unia.ao',
      organization: 'UNIA',
      role: MemberRole.writer,
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Jun 2024',
      lastActive: 'Há 2 dias',
    ),
    const Member(
      id: '7',
      name: 'Rui Capelo',
      email: 'rui.capelo@minfin.gov.ao',
      organization: 'MINFIN',
      role: MemberRole.admin,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Jan 2023',
      lastActive: 'Hoje',
    ),
    const Member(
      id: '8',
      name: 'Teresa Luz',
      email: 't.luz@ucan.edu',
      organization: 'UCAN',
      role: MemberRole.suspended,
      roleBeforeSuspension: MemberRole.writer,
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=128&h=128&fit=crop&crop=face',
      joinedAt: 'Out 2023',
      lastActive: 'Há 1 mês',
    ),
  ];
}

enum MemberFilter { all, members, admins, suspended }

extension MemberFilterLabel on MemberFilter {
  String get label => switch (this) {
    MemberFilter.all => 'Todos',
    MemberFilter.members => 'Membros',
    MemberFilter.admins => 'Admins',
    MemberFilter.suspended => 'Suspensos',
  };
}

bool memberMatchesFilter(Member member, MemberFilter filter) {
  return switch (filter) {
    MemberFilter.all => true,
    MemberFilter.members =>
      member.role == MemberRole.member || member.role == MemberRole.writer,
    MemberFilter.admins => member.role == MemberRole.admin,
    MemberFilter.suspended => member.role == MemberRole.suspended,
  };
}
