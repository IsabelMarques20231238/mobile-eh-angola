import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'carlos@isptec.co.ao');
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService(ApiClient.instance).login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.feed);
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AppLogo(),
                const SizedBox(height: 54),
                AppTextField(
                  label: 'Email Institucional',
                  hint: 'carlos@isptec.co.ao',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o email' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Palavra-Passe',
                  hint: '********',
                  controller: _password,
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Informe a palavra-passe' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextLink(text: 'Esqueci a senha', onTap: () => Navigator.pushNamed(context, AppRoutes.resetPassword), fontSize: 10),
                ),
                const SizedBox(height: 22),
                PrimaryButton(text: 'Iniciar Sessao', onPressed: _login, isLoading: _loading),
                const SizedBox(height: 18),
                const DividerWithText(text: 'ou'),
                const SizedBox(height: 18),
                GoogleButton(onPressed: () {}),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ainda nao tens conta? ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    TextLink(text: 'Criar conta', onTap: () => Navigator.pushNamed(context, AppRoutes.signup)),
                  ],
                ),
                const SizedBox(height: 6),
                TextLink(
                  text: 'Entrar como convidado',
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.feed),
                  fontSize: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
