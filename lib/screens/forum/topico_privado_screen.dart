import 'package:flutter/material.dart';
import '../../models/forum_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/forum_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import 'forum_topic_detail_screen.dart';

class TopicoPrivadoScreen extends StatefulWidget {
  final ForumTopic? topic;

  const TopicoPrivadoScreen({super.key, this.topic});

  @override
  State<TopicoPrivadoScreen> createState() => _TopicoPrivadoScreenState();
}

class _TopicoPrivadoScreenState extends State<TopicoPrivadoScreen> {
  final _reasonController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  bool _isJoining = false;
  bool _isRequesting = false;

  ForumTopic get _topic =>
      widget.topic ??
      const ForumTopic(
        title: 'Impacto das Reformas Económicas em Angola (1990-2000)',
        excerpt:
            'Este é um espaço de discussão restrito e privado sobre as reformas económicas estruturais levadas a cabo em Angola.',
        authorName: 'Prof. Ana Silva',
        authorInitials: 'AS',
        category: TopicCategory.economia,
        visibility: TopicVisibility.privado,
        timeAgo: 'Há 3 dias',
        comments: 0,
        likes: 48,
        avatarBg: Color(0xFF7B001C),
        avatarFg: Colors.white,
      );

  @override
  void dispose() {
    _reasonController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF7B001C),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Voltar ao Fórum',
                    style: TextStyle(
                      color: Color(0xFF7B001C),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 46),
            const _PrivateHero(),
            const SizedBox(height: 46),
            _TopicSummaryCard(topic: topic),
            const SizedBox(height: 22),
            _AccessRequestCard(
              controller: _reasonController,
              onSubmit: _isRequesting ? null : _submitRequest,
              isRequesting: _isRequesting,
              codeControllers: _codeControllers,
              onCodeSubmit: _isJoining ? null : _submitCode,
              isJoining: _isJoining,
            ),
            const SizedBox(height: 32),
            const _SecurityNote(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavMock(index: 1),
    );
  }

  Future<void> _submitRequest() async {
    if (!AuthState.requireAuth(context)) return;
    final message = _reasonController.text.trim();
    if (message.isEmpty) {
      showAppToast(context, 'Escreve o motivo do teu pedido.', type: AppToastType.warning);
      return;
    }
    final topicId = widget.topic?.id;
    if (topicId == null || topicId <= 0) return;
    setState(() => _isRequesting = true);
    try {
      await ForumService.instance.requestAccess(topicId, message);
      if (!mounted) return;
      _reasonController.clear();
      showAppToast(context, 'Pedido enviado ao moderador.', type: AppToastType.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _submitCode() async {
    if (!AuthState.requireAuth(context)) return;
    final code = _codeControllers.map((c) => c.text).join().trim();
    if (code.length < 6) {
      showAppToast(context, 'Introduz os 6 caracteres do código.', type: AppToastType.warning);
      return;
    }
    final topic = widget.topic;
    if (topic == null || topic.id <= 0) return;
    setState(() => _isJoining = true);
    try {
      final joinedTopic = await ForumService.instance.joinWithCode(topic.id, code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ForumTopicDetailScreen(topic: joinedTopic)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      final msg = (e.statusCode == 422 || e.statusCode == 403)
          ? 'Código inválido. Verifica e tenta novamente.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.wine, content: Text(msg, style: const TextStyle(color: Colors.white))),
      );
    }
  }
}

class _PrivateHero extends StatelessWidget {
  const _PrivateHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEF1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFD5DF)),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF7B001C),
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tópico privado',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020617),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Apenas convidados poderão ver este tópico e as\ntuas publicações.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF020617),
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TopicSummaryCard extends StatelessWidget {
  final ForumTopic topic;

  const _TopicSummaryCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFE11D48),
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Tópico Privado',
                  style: TextStyle(
                    color: Color(0xFF9F1239),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            topic.title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 24,
              height: 1.16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 26),
          const Divider(color: Color(0xFFE8EDF3)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (topic.members > 0)
                _SummaryStat(
                  icon: Icons.group_outlined,
                  label: '${topic.members} ${topic.members == 1 ? 'membro' : 'membros'}',
                ),
              _SummaryStat(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${topic.comments} ${topic.comments == 1 ? 'resposta' : 'respostas'}',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'MODERADOR',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppAvatar(
                initials: topic.authorInitials,
                size: 50,
                bg: topic.avatarBg ?? const Color(0xFF7B001C),
                fg: topic.avatarFg ?? Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  topic.authorName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 24),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AccessRequestCard extends StatelessWidget {
  final TextEditingController controller;
  final List<TextEditingController> codeControllers;
  final VoidCallback? onSubmit;
  final VoidCallback? onCodeSubmit;
  final bool isRequesting;
  final bool isJoining;

  const _AccessRequestCard({
    required this.controller,
    required this.codeControllers,
    this.onSubmit,
    this.onCodeSubmit,
    this.isRequesting = false,
    this.isJoining = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitar acesso',
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O moderador receberá o teu pedido e decidirá\nse aceita.',
            style: TextStyle(
              color: Color(0xFF8A9AB2),
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Porque queres participar?',
              counterStyle: const TextStyle(
                color: Color(0xFF8A9AB2),
                fontWeight: FontWeight.w800,
              ),
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.wine),
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B001C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: isRequesting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Enviar pedido'),
            ),
          ),
          const SizedBox(height: 40),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE8EDF3))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'OU',
                  style: TextStyle(
                    color: Color(0xFF020617),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE8EDF3))),
            ],
          ),
          const SizedBox(height: 36),
          const Center(
            child: Text(
              'TENS UM CÓDIGO?',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: List.generate(
              codeControllers.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                  child: _CodeBox(
                    controller: codeControllers[index],
                    onChanged: (value) {
                      if (value.isNotEmpty &&
                          index < codeControllers.length - 1) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onCodeSubmit,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B001C),
                side: const BorderSide(color: Color(0xFF7B001C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: isJoining
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Color(0xFF7B001C), strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Entrar com código'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CodeBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        maxLength: 1,
        onChanged: onChanged,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '-',
          hintStyle: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE5EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.wine),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Color(0xFF94A3B8), size: 17),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'A tua informação está segura. Apenas o moderador poderá ver o teu pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
