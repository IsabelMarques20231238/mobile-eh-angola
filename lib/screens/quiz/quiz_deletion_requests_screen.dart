import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_models.dart';

class QuizDeletionRequestsScreen extends StatefulWidget {
  const QuizDeletionRequestsScreen({super.key});

  @override
  State<QuizDeletionRequestsScreen> createState() =>
      _QuizDeletionRequestsScreenState();
}

class _QuizDeletionRequestsScreenState
    extends State<QuizDeletionRequestsScreen> {
  final _service = QuizService(ApiClient.instance);

  List<DeletionRequestModel> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.getDeletionRequests();
      if (mounted) setState(() { _requests = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Não foi possível carregar os pedidos.'; _loading = false; });
    }
  }

  Future<void> _approve(DeletionRequestModel req) async {
    final ok = await showAppDialog(
      context,
      title: 'Aprovar eliminação?',
      message: 'O quiz "${req.quizTitle}" será eliminado permanentemente. Esta acção é irreversível.',
      confirmLabel: 'Aprovar e eliminar',
      cancelLabel: 'Cancelar',
      type: AppDialogType.danger,
    );
    if (!ok || !mounted) return;
    try {
      await _service.approveDeletionRequest(req.id);
      if (!mounted) return;
      showAppToast(context, 'Pedido aprovado. Quiz eliminado.', type: AppToastType.success);
      _load();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  void _showRejectSheet(DeletionRequestModel req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(
        onConfirm: (reason) => _reject(req, reason),
      ),
    );
  }

  Future<void> _reject(DeletionRequestModel req, String reason) async {
    Navigator.pop(context); // fecha sheet
    try {
      await _service.rejectDeletionRequest(req.id, reason);
      if (!mounted) return;
      showAppToast(context, 'Pedido rejeitado. O autor foi notificado.', type: AppToastType.info);
      _load();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Pedidos de Eliminação',
          style: TextStyle(color: c.wine, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.wine))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildBody(c),
    );
  }

  Widget _buildBody(AppAdaptiveColors c) {
    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: c.muted, size: 44),
              const SizedBox(height: 14),
              Text(
                'Sem pedidos pendentes.',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: c.textMain),
              ),
              const SizedBox(height: 6),
              Text(
                'Não há pedidos de eliminação de quiz a aguardar revisão.',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _requests.length,
        itemBuilder: (_, i) => _RequestCard(
          request: _requests[i],
          onApprove: () => _approve(_requests[i]),
          onReject: () => _showRejectSheet(_requests[i]),
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final DeletionRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  String? _timeAgo(DateTime? dt) {
    if (dt == null) return null;
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 1)    return 'há ${d.inDays} dia${d.inDays > 1 ? 's' : ''}';
    if (d.inHours >= 1)   return 'há ${d.inHours} hora${d.inHours > 1 ? 's' : ''}';
    if (d.inMinutes >= 1) return 'há ${d.inMinutes} min';
    return 'agora mesmo';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ago = _timeAgo(request.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: status badge + time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AGUARDA REVISÃO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (ago != null)
                      Text(ago, style: TextStyle(fontSize: 11, color: c.muted)),
                  ],
                ),
                const SizedBox(height: 10),

                // Quiz title
                Text(
                  request.quizTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textMain,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Creator
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: c.muted),
                    const SizedBox(width: 4),
                    Text(
                      'Por ${request.creatorName}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Requester + reason
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 13, color: AppColors.error),
                          const SizedBox(width: 5),
                          Text(
                            '${request.requesterName} pediu a eliminação:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.reason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Action buttons
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Rejeitar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Aprovar e eliminar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de rejeição ──────────────────────────────────────────────────

class _RejectSheet extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;
  const _RejectSheet({required this.onConfirm});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isValid = _ctrl.text.trim().length >= 5;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF92400E), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rejeitar pedido',
                        style: TextStyle(
                            color: c.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    Text('O motivo será enviado ao autor.',
                        style: TextStyle(color: c.muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 4,
              minLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Motivo da rejeição do pedido...',
                hintStyle: TextStyle(color: c.muted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.wine),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValid && !_submitting
                        ? () async {
                            setState(() => _submitting = true);
                            await widget.onConfirm(_ctrl.text.trim());
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.border,
                      disabledForegroundColor: c.muted,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmar rejeição',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: c.muted, size: 40),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
