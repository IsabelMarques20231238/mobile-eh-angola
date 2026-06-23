import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Carlos Mendes');
  final _email = TextEditingController(text: 'carlos@isptec.co.ao');
  final _password = TextEditingController(text: '123456');
  final _confirm = TextEditingController(text: '123456');
  String _institution = 'ISPTEC';
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
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.verifyEmail,
          arguments: _email.text.trim(),
        );
      }
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
                const Text('Selecione a Instituicao', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _institution,
                  decoration: const InputDecoration(),
                  items: const ['ISPTEC', 'UAN', 'UCAN', 'DCSA'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _institution = v ?? _institution),
                ),
                const SizedBox(height: 16),
                const DividerWithText(text: 'ou'),
                const SizedBox(height: 14),
                GoogleButton(onPressed: () {}),
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
