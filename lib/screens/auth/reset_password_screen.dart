import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'carlos@isptec.co.ao');
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService(ApiClient.instance).forgotPassword(_email.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.newPassword, arguments: _email.text.trim());
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Economia com Historia', style: TextStyle(color: AppColors.primary, fontSize: 12)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 92, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CenteredIconBox(icon: Icons.lock_outline, size: 52),
                const SizedBox(height: 42),
                const Text('Redefinir palavra-passe', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                const Text('Introduz o teu email e enviamos um codigo\npara redefinires a tua palavra-passe.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.45)),
                const SizedBox(height: 34),
                AppTextField(
                  label: 'Email Institucional',
                  hint: 'carlos@isptec.co.ao',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o email' : null,
                ),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Enviar Codigo', onPressed: _sendCode, isLoading: _loading),
                const Spacer(),
                TextLink(text: 'Voltar ao login', onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login), fontSize: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
