import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final emailArg = ModalRoute.of(context)?.settings.arguments;
    if (_email.text.isEmpty && emailArg is String) _email.text = emailArg;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService(ApiClient.instance).resetPassword(
        email: _email.text.trim(),
        code: _code.text.trim(),
        password: _pass.text,
        passwordConfirmation: _confirm.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    } on ApiException catch (error) {
      if (mounted) showAppToast(context, error.message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CenteredIconBox(icon: Icons.lock_outline, size: 52),
                const SizedBox(height: 42),
                const Text('Nova palavra-passe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                const Text('A palavra-passe deve ter pelo menos 6\ncaracteres.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.45)),
                const SizedBox(height: 34),
                AppTextField(
                  label: 'Email',
                  hint: 'carlos@isptec.co.ao',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o email' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Codigo recebido',
                  hint: '123456',
                  controller: _code,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o codigo' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Criar nova Palavra-Passe',
                  hint: '123456',
                  controller: _pass,
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6 ? 'Minimo de 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirmar a Palavra-Passe',
                  hint: '123456',
                  controller: _confirm,
                  obscureText: true,
                  validator: (value) => value != _pass.text ? 'As palavras-passe nao coincidem' : null,
                ),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Guardar Palavra-Passe', onPressed: _resetPassword, isLoading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
