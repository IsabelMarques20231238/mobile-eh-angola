import 'dart:async';

import 'package:flutter/material.dart';

import '../services/image_validation_service.dart';
import '../theme/app_theme.dart';

/// Campo de texto com validação de URL de imagem e pré-visualização integrada.
///
/// Uso:
/// ```dart
/// ImagePreviewField(
///   controller: _imageUrlController,
///   onValidUrl: (url) => setState(() => _confirmedUrl = url),
/// )
/// ```
class ImagePreviewField extends StatefulWidget {
  /// Controlador externo opcional — permite ler/definir o valor programaticamente.
  final TextEditingController? controller;

  /// Chamado sempre que a URL muda de estado para [ImageValidationValid].
  final ValueChanged<String>? onValidUrl;

  /// Chamado quando a URL é apagada ou se torna inválida.
  final VoidCallback? onInvalidUrl;

  /// Se `false`, o preview da imagem não é mostrado inline — útil quando o pai
  /// exibe o preview noutro local (ex: em substituição da caixa de upload).
  final bool showInlinePreview;

  const ImagePreviewField({
    super.key,
    this.controller,
    this.onValidUrl,
    this.onInvalidUrl,
    this.showInlinePreview = true,
  });

  @override
  State<ImagePreviewField> createState() => _ImagePreviewFieldState();
}

class _ImagePreviewFieldState extends State<ImagePreviewField> {
  late final TextEditingController _controller;
  late final ImageValidationService _service;
  Timer? _debounce;

  ImageUrlValidationState _state = const ImageValidationIdle();

  // Guarda a última URL validada para evitar pedidos duplicados.
  String _lastChecked = '';

  static const _debounceDelay = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _service = ImageValidationService();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _service.dispose();
    // Só elimina o controlador se foi criado internamente.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();

    _debounce?.cancel();

    if (text.isEmpty) {
      _lastChecked = '';
      setState(() => _state = const ImageValidationIdle());
      widget.onInvalidUrl?.call();
      return;
    }

    // Evita chamada de rede para o mesmo valor.
    if (text == _lastChecked) return;

    setState(() => _state = const ImageValidationChecking());

    _debounce = Timer(_debounceDelay, () => _validate(text));
  }

  Future<void> _validate(String url) async {
    _lastChecked = url;
    final result = await _service.validateImageUrl(url);

    if (!mounted) return;

    // Descarta se o campo já foi alterado entretanto.
    if (_controller.text.trim() != url) return;

    setState(() {
      switch (result) {
        case ValidationSuccess(:final url):
          _state = ImageValidationValid(url);
          widget.onValidUrl?.call(url);
        case ValidationFailure(:final message):
          _state = ImageValidationInvalid(message);
          widget.onInvalidUrl?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UrlTextField(controller: _controller, state: _state),
        _StateMessage(state: _state),
        if (widget.showInlinePreview) _ImagePreview(state: _state),
      ],
    );
  }
}

// ── Campo de texto ────────────────────────────────────────────────────────────

class _UrlTextField extends StatelessWidget {
  final TextEditingController controller;
  final ImageUrlValidationState state;

  const _UrlTextField({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    final isChecking = state is ImageValidationChecking;
    final isInvalid = state is ImageValidationInvalid;
    final hasText = controller.text.isNotEmpty;

    final borderColor = switch (state) {
      ImageValidationValid() => AppColors.success,
      ImageValidationInvalid() => AppColors.error,
      _ => AppColors.borderLight,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.link_rounded, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Ou cola o endereço (URL) de uma imagem',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                errorText: isInvalid ? '' : null,
                errorStyle: const TextStyle(height: 0),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (isChecking)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.wine,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (hasText)
            GestureDetector(
              onTap: controller.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.close_rounded,
                    color: AppColors.muted, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mensagem de estado ────────────────────────────────────────────────────────

class _StateMessage extends StatelessWidget {
  final ImageUrlValidationState state;

  const _StateMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ImageValidationInvalid() => const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Não foi possível carregar a imagem deste endereço (URL). Certifica-te de que o link está correto.',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ImageValidationValid() => const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Imagem válida',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Pré-visualização ──────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final ImageUrlValidationState state;

  const _ImagePreview({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is! ImageValidationValid) return const SizedBox.shrink();
    final url = (state as ImageValidationValid).url;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.wineBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.wine,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 100,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.broken_image_outlined,
                      color: AppColors.muted, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Não foi possível carregar a imagem',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
