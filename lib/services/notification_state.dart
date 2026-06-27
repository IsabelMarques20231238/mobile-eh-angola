import 'dart:async';

import 'package:flutter/material.dart';
import 'api_client.dart';
import 'realtime_event.dart';
import 'websocket_service.dart';

class NotificationState extends ChangeNotifier {
  NotificationState._();
  static final NotificationState instance = NotificationState._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  StreamSubscription<RealtimeEvent>? _wsSub;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 30);

  void setUnreadCount(int count) {
    final clamped = count.clamp(0, 9999);
    if (_unreadCount == clamped) return;
    _unreadCount = clamped;
    notifyListeners();
  }

  void decrement([int by = 1]) {
    final next = (_unreadCount - by).clamp(0, 9999);
    if (next == _unreadCount) return;
    _unreadCount = next;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final data = await ApiClient.instance.get('/notifications', authenticated: true);
      final list = data is Map ? data['data'] : data;
      if (list is List) {
        final count = list
            .whereType<Map<String, dynamic>>()
            .where((n) => n['is_read'] != true)
            .length;
        setUnreadCount(count);
      }
    } on ApiException {
      // Falha silenciosa — o badge mantém o valor anterior
    }
  }

  /// Liga a escuta em tempo real (WebSocket) + polling de fallback a cada 30 s.
  /// Deve ser chamado após autenticação bem-sucedida.
  void startListening() {
    // WebSocket — actualização instantânea quando o evento chega
    _wsSub?.cancel();
    _wsSub = WebSocketService.instance.events.listen((event) {
      if (event is NotificationReceivedEvent) {
        _unreadCount = (_unreadCount + 1).clamp(0, 9999);
        notifyListeners();
      }
    });

    // Polling de fallback — garante actualização mesmo que o evento WS tenha
    // um nome diferente no backend ou a ligação esteja temporariamente em baixo.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  /// Para a escuta e o polling (ex: ao fazer logout).
  void stopListening() {
    _wsSub?.cancel();
    _wsSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
