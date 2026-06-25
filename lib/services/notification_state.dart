import 'package:flutter/material.dart';
import 'api_client.dart';

class NotificationState extends ChangeNotifier {
  NotificationState._();
  static final NotificationState instance = NotificationState._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

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
}
