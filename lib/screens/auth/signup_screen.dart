import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _profession = 'ESTUDANTE';
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService(ApiClient.instance).register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        profession: _profession,
      );
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.feed);
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    showAppToast(context, message, type: AppToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Criar conta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                const Text('Junta-te a comunidade academica', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 22),
                AppTextField(
                  label: 'Nome Completo',
                  hint: 'Carlos Mendes',
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email Institucional',
                  hint: 'carlos@isptec.co.ao',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o email' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Criar Palavra-Passe',
                  hint: '******',
                  controller: _password,
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6 ? 'Minimo de 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirmar Palavra-Passe',
                  hint: '******',
                  controller: _confirm,
                  obscureText: true,
                  validator: (value) => value != _password.text ? 'As palavras-passe nao coincidem' : null,
                ),
                const SizedBox(height: 12),
                const Text('Profissão', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _profession,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'ESTUDANTE', child: Text('Estudante', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'PROFESSOR', child: Text('Professor', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'OUTRO', child: Text('Outro', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) => setState(() => _profession = v ?? _profession),
                ),
                const SizedBox(height: 16),
                const DividerWithText(text: 'ou'),
                const SizedBox(height: 14),
                GoogleButton(onPressed: null),
                const SizedBox(height: 18),
                PrimaryButton(text: 'Criar Conta', onPressed: _submit, isLoading: _loading),
                const SizedBox(height: 8),
                const Center(child: Text('Ao criar conta aceitas os Termos de Uso', style: TextStyle(fontSize: 9, color: AppColors.textMuted))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
