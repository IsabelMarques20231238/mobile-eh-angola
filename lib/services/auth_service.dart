import 'api_client.dart';
import 'api_models.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthUser> login({required String email, required String password}) async {
    final payload = await _api.post('/login', body: {'email': email, 'password': password});
    return _handleAuthPayload(payload);
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final payload = await _api.post('/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return _handleAuthPayload(payload);
  }

  Future<AuthUser> googleAuth(String idToken) async {
    final payload = await _api.post('/auth/google', body: {'token': idToken});
    return _handleAuthPayload(payload);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.post('/reset-password', body: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout', authenticated: true);
    } finally {
      await _api.clearToken();
    }
  }

  Future<AuthUser> _handleAuthPayload(dynamic payload) async {
    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Resposta invalida da API.');
    }
    final token = payload['token']?.toString();
    final user = payload['user'];
    if (token == null || token.isEmpty || user is! Map<String, dynamic>) {
      throw const ApiException('Resposta de autenticacao incompleta.');
    }
    await _api.saveToken(token);
    return AuthUser.fromJson(user);
  }
}
