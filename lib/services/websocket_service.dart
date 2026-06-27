import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'realtime_event.dart';

/// Serviço singleton que mantém a ligação WebSocket com o backend.
///
/// Fluxo:
///   1. [connect] é chamado no startup (após restore de auth).
///   2. O servidor envia um handshake com `socket_id`; guardamo-lo em [ApiClient]
///      para que todas as chamadas HTTP seguintes incluam `X-Socket-ID` e o servidor
///      não reenvie os nossos próprios eventos de volta para nós.
///   3. Qualquer ecrã pode ouvir [events] e filtrar pelo tipo de evento que lhe
///      interessa, sem acoplamento directo a este serviço.
///   4. Ao abrir um tópico, chama-se [subscribeToTopic]; ao sair, [unsubscribeFromTopic].
///      Em caso de reconexão, as subscrições activas são automaticamente restauradas.
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  static const _wsBaseUrl = 'wss://api-ehangola-production.up.railway.app/ws';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _backoffTimer;

  bool _running = false;
  int _attempts = 0;

  /// Canais actualmente subscritos — restaurados automaticamente em reconexão.
  final Set<String> _channels = {'topics'};

  final _eventController = StreamController<RealtimeEvent>.broadcast();

  /// Stream broadcast de eventos tipados. Ouvir este stream é seguro em múltiplos
  /// widgets ao mesmo tempo. Os eventos que não correspondam ao tópico activo devem
  /// ser filtrados pelo consumidor.
  Stream<RealtimeEvent> get events => _eventController.stream;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  /// Inicia a ligação. Deve ser chamado uma vez no arranque da app,
  /// após [AuthState.restore], para que o token já esteja disponível.
  Future<void> connect() async {
    if (_running) return;
    _running = true;
    await _doConnect();
  }

  /// Encerra definitivamente a ligação (usar apenas ao fechar a app).
  void disconnect() {
    _running = false;
    _backoffTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  // ── Canal de tópico ───────────────────────────────────────────────────────

  /// Subscreve o canal privado deste tópico. Chamar ao entrar no ecrã de detalhe.
  void subscribeToTopic(int topicId) {
    final ch = 'topic.$topicId';
    _channels.add(ch);
    _send({'event': 'subscribe', 'channel': ch});
  }

  /// Remove a subscrição do canal ao sair do ecrã de detalhe.
  void unsubscribeFromTopic(int topicId) {
    final ch = 'topic.$topicId';
    _channels.remove(ch);
    _send({'event': 'unsubscribe', 'channel': ch});
  }

  /// Subscreve o canal privado do utilizador para receber notificações em tempo real.
  void subscribeToUserNotifications(int userId) {
    final ch = 'user.$userId';
    _channels.add(ch);
    _send({'event': 'subscribe', 'channel': ch});
  }

  /// Remove a subscrição do canal de notificações do utilizador (ex: ao fazer logout).
  void unsubscribeFromUserNotifications(int userId) {
    final ch = 'user.$userId';
    _channels.remove(ch);
    _send({'event': 'unsubscribe', 'channel': ch});
  }

  // ── Implementação interna ─────────────────────────────────────────────────

  Future<void> _doConnect() async {
    // Inclui o token na URL para que o servidor possa autenticar a ligação.
    final token = ApiClient.instance.cachedToken;
    final uri = Uri.parse(
      token != null && token.isNotEmpty ? '$_wsBaseUrl?token=$token' : _wsBaseUrl,
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready; // lança se a ligação falhar imediatamente
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    // Ligação estabelecida — resetar contador de tentativas.
    _attempts = 0;

    _sub = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: false,
    );

    // (Re-)subscrever todos os canais activos.
    for (final ch in _channels) {
      _send({'event': 'subscribe', 'channel': ch});
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    _tryExtractSocketId(json);

    final event = RealtimeEvent.fromJson(json);
    if (event != null) _eventController.add(event);
  }

  /// Extrai o `socket_id` do handshake inicial e guarda-o no [ApiClient].
  /// Suporta tanto o protocolo Pusher (data como string JSON) como servidores
  /// personalizados que enviam `socket_id` directamente na raiz do payload.
  void _tryExtractSocketId(Map<String, dynamic> json) {
    if (ApiClient.instance.socketId != null) return;

    String? id = json['socket_id']?.toString();

    if (id == null) {
      final raw = json['data'];
      Map<String, dynamic>? data;
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          data = decoded is Map<String, dynamic> ? decoded : null;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        data = raw;
      }
      id = data?['socket_id']?.toString();
    }

    if (id != null && id.isNotEmpty) {
      ApiClient.instance.socketId = id;
    }
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _sub?.cancel();
    _channel = null;

    // Backoff exponencial: 1s, 2s, 4s, 8s, 16s, 30s (máximo).
    final delaySecs = min(30, 1 << _attempts.clamp(0, 5));
    _attempts++;

    _backoffTimer = Timer(
      Duration(seconds: delaySecs),
      () => _doConnect(),
    );
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      // Falha silenciosa — será enviado novamente na reconexão.
    }
  }
}
