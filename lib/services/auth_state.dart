import 'package:flutter/material.dart';
import 'api_client.dart';
import 'api_models.dart';

class AuthState extends ChangeNotifier {
  AuthState._();
  static final AuthState instance = AuthState._();

  AuthUser? _user;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;

  String get displayRole {
    final roles = _user?.roles ?? [];
    if (roles.any((r) => r == 'SUPER_ADMIN' || r == 'ADMIN')) return 'Moderador';
    if (roles.contains('AUTHOR')) return 'Escritor';
    return 'Membro';
  }

  bool get canCreateQuiz {
    final roles = _user?.roles ?? [];
    return roles.any((r) => r == 'SUPER_ADMIN' || r == 'ADMIN' || r == 'AUTHOR');
  }

  String get initials {
    final name = _user?.name ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  void setUser(AuthUser user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  Future<void> restore() async {
    ApiClient.onUnauthorized = clearUser;
    final token = await ApiClient.instance.token;
    if (token == null || token.isEmpty) return;
    try {
      final data = await ApiClient.instance.get('/me', authenticated: true);
      if (data is Map<String, dynamic>) {
        _user = AuthUser.fromJson(data);
        notifyListeners();
      }
    } on ApiException {
      // Token expired — ApiClient already cleared it
    }
  }

  /// Returns true if authenticated; shows an auth banner and returns false if not.
  static bool requireAuth(BuildContext context) {
    if (instance.isAuthenticated) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFDE8ED),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFF5C2CF)),
          ),
          elevation: 4,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF7B173F), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Inicia sessão para participar',
                  style: TextStyle(
                    color: Color(0xFF3D0A1E),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.pushNamed(context, '/login');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B173F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Entrar →',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    return false;
  }
}
