import 'dart:convert';

import '../models/forum_models.dart';

/// Hierarquia tipada de eventos recebidos via WebSocket.
/// Cada variante representa um tipo de mensagem emitida pelo servidor.
sealed class RealtimeEvent {
  const RealtimeEvent();

  /// Parseia o payload JSON bruto recebido do WebSocket num evento tipado.
  /// Devolve `null` se o evento for desconhecido ou o payload estiver mal formado.
  static RealtimeEvent? fromJson(Map<String, dynamic> json) {
    final event = json['event']?.toString() ?? '';

    // O campo 'data' pode ser um Map direto (custom server) ou
    // uma string JSON serializada (protocolo Pusher).
    final rawData = json['data'];
    final Map<String, dynamic>? data;
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        data = decoded is Map<String, dynamic> ? decoded : null;
      } catch (_) {
        return null;
      }
    } else {
      data = null;
    }

    if (data == null) return null;

    try {
      return switch (event) {
        'CommentCreated' || 'CommentReplyCreated' => CommentCreatedEvent._fromData(data),
        'TopicLikeUpdated' => TopicLikeUpdatedEvent._fromData(data),
        'CommentLikeUpdated' => CommentLikeUpdatedEvent._fromData(data),
        'TopicUpdated' => TopicUpdatedEvent._fromData(data),
        'NotificationCreated' || 'NewNotification' => NotificationReceivedEvent._fromData(data),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

// ── Novo comentário ou resposta ───────────────────────────────────────────────

final class CommentCreatedEvent extends RealtimeEvent {
  final int topicId;
  final ForumComment comment;

  const CommentCreatedEvent({required this.topicId, required this.comment});

  factory CommentCreatedEvent._fromData(Map<String, dynamic> data) {
    final commentData = data['comment'];
    if (commentData is! Map<String, dynamic>) {
      throw const FormatException('CommentCreated: campo "comment" ausente ou inválido');
    }
    return CommentCreatedEvent(
      topicId: _parseInt(data['topic_id']),
      comment: ForumComment.fromApiJson(commentData),
    );
  }
}

// ── Like num tópico ───────────────────────────────────────────────────────────

final class TopicLikeUpdatedEvent extends RealtimeEvent {
  final int topicId;
  final int likesCount;
  final bool isLiked;

  const TopicLikeUpdatedEvent({
    required this.topicId,
    required this.likesCount,
    required this.isLiked,
  });

  factory TopicLikeUpdatedEvent._fromData(Map<String, dynamic> data) =>
      TopicLikeUpdatedEvent(
        topicId: _parseInt(data['topic_id']),
        likesCount: _parseInt(data['likes_count']),
        isLiked: data['is_liked'] == true,
      );
}

// ── Like num comentário ───────────────────────────────────────────────────────

final class CommentLikeUpdatedEvent extends RealtimeEvent {
  final int commentId;
  final int likesCount;

  const CommentLikeUpdatedEvent({
    required this.commentId,
    required this.likesCount,
  });

  factory CommentLikeUpdatedEvent._fromData(Map<String, dynamic> data) =>
      CommentLikeUpdatedEvent(
        commentId: _parseInt(data['comment_id']),
        likesCount: _parseInt(data['likes_count']),
      );
}

// ── Tópico actualizado (título, read-only, etc.) ──────────────────────────────

final class TopicUpdatedEvent extends RealtimeEvent {
  final int topicId;
  final bool? isReadOnly;
  final String? title;
  final int? commentsCount;

  const TopicUpdatedEvent({
    required this.topicId,
    this.isReadOnly,
    this.title,
    this.commentsCount,
  });

  factory TopicUpdatedEvent._fromData(Map<String, dynamic> data) => TopicUpdatedEvent(
        topicId: _parseInt(data['topic_id']),
        isReadOnly: data['is_read_only'] as bool?,
        title: data['title']?.toString(),
        commentsCount: data['comments_count'] != null
            ? _parseInt(data['comments_count'])
            : null,
      );
}

// ── Nova notificação para o utilizador ───────────────────────────────────────

final class NotificationReceivedEvent extends RealtimeEvent {
  final int? notificationId;
  final String? type;

  const NotificationReceivedEvent({this.notificationId, this.type});

  factory NotificationReceivedEvent._fromData(Map<String, dynamic> data) =>
      NotificationReceivedEvent(
        notificationId: data['id'] != null ? _parseInt(data['id']) : null,
        type: data['type']?.toString(),
      );
}

// ── Helper ────────────────────────────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
