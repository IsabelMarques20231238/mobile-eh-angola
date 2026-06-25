import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

// ── Estado da validação ───────────────────────────────────────────────────────

sealed class ImageUrlValidationState {
  const ImageUrlValidationState();
}

/// Estado inicial — campo vazio ou intocado.
class ImageValidationIdle extends ImageUrlValidationState {
  const ImageValidationIdle();
}

/// A aguardar resposta da rede.
class ImageValidationChecking extends ImageUrlValidationState {
  const ImageValidationChecking();
}

/// URL confirmada como imagem acessível.
class ImageValidationValid extends ImageUrlValidationState {
  final String url;
  const ImageValidationValid(this.url);
}

/// Erro sintático ou de rede — inclui mensagem legível para o utilizador.
class ImageValidationInvalid extends ImageUrlValidationState {
  final String message;
  const ImageValidationInvalid(this.message);
}

// ── Resultado interno do serviço ──────────────────────────────────────────────

sealed class ValidationResult {
  const ValidationResult();
}

class ValidationSuccess extends ValidationResult {
  final String url;
  const ValidationSuccess(this.url);
}

class ValidationFailure extends ValidationResult {
  final String message;
  const ValidationFailure(this.message);
}

// ── Serviço ───────────────────────────────────────────────────────────────────

class ImageValidationService {
  ImageValidationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 5);

  /// Valida a [urlString] sintacticamente e via requisição HEAD.
  ///
  /// Retorna [ValidationSuccess] com a URL limpa, ou [ValidationFailure]
  /// com uma mensagem de erro em português.
  Future<ValidationResult> validateImageUrl(String urlString) async {
    final trimmed = urlString.trim();

    if (trimmed.isEmpty) {
      return const ValidationFailure('Insere um endereço de imagem.');
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return const ValidationFailure(
          'A URL deve começar com http:// ou https://');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return const ValidationFailure('URL com formato inválido.');
    }

    try {
      final response = await _client
          .head(uri)
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return const ValidationFailure('Imagem não encontrada (404).');
      }
      if (response.statusCode >= 400) {
        return ValidationFailure(
            'Erro ao aceder à imagem (${response.statusCode}).');
      }

      // Alguns servidores respondem ao HEAD sem Content-Type mas servem a
      // imagem correctamente no GET — tratamos statusCode 2xx como suficiente
      // se o host for acessível, e verificamos o content-type quando presente.
      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.isNotEmpty && !contentType.startsWith('image/')) {
        return const ValidationFailure('O link não aponta para uma imagem.');
      }

      return ValidationSuccess(trimmed);
    } on TimeoutException {
      return const ValidationFailure(
          'Tempo de espera esgotado. Verifica a ligação.');
    } on SocketException {
      return const ValidationFailure('Sem ligação à internet.');
    } on http.ClientException {
      return const ValidationFailure('Não foi possível aceder ao link.');
    } catch (_) {
      return const ValidationFailure('Erro inesperado. Tenta novamente.');
    }
  }

  void dispose() => _client.close();
}
