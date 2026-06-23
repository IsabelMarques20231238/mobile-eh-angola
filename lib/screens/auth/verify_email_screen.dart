import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final emailArg = ModalRoute.of(context)?.settings.arguments;
    final email = emailArg is String && emailArg.isNotEmpty ? emailArg : 'carlos@isptec.co.ao';

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            children: [
              const CenteredIconBox(icon: Icons.mail_outline, check: true),
              const SizedBox(height: 28),
              const Text('Verifica o teu email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text('Enviamos um link de confirmacao para', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const Text('Abre o email e clica no link para activar a tua conta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 38),
              _confirmed ? _confirmedBox(context) : _pendingBox(),
              const SizedBox(height: 16),
              if (!_confirmed) PrimaryButton(text: 'Reenviar email', onPressed: () => setState(() => _confirmed = true), height: 38),
              const SizedBox(height: 10),
              TextLink(text: 'Usar outro email', onTap: () => Navigator.pop(context), fontSize: 10),
              const Spacer(),
              const Text('Problemas? Contacta o suporte', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              const SizedBox(height: 14),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.successLight, border: Border.all(color: AppColors.success), borderRadius: BorderRadius.circular(2)),
      child: const Center(child: Text('A aguardar confirmacao...', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w800))),
    );
  }

  Widget _confirmedBox(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.successLight, border: Border.all(color: AppColors.success), borderRadius: BorderRadius.circular(2)),
          child: const Center(child: Text('Email confirmado!', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Voltar a Iniciar Sessao', onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login)),
      ],
    );
  }
}
