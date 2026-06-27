import 'dart:async';

import '../models/forum_models.dart';
import 'api_client.dart';
import 'api_models.dart' hide ForumTopic;

class LikeResult {
  final bool liked;
  final int likesCount;
  const LikeResult({required this.liked, required this.likesCount});
}

class ForumTopicDetailResult {
  final ForumTopic? topic;
  final String body;
  final int likesCount;
  final bool isLiked;
  final bool isSaved;
  final bool isReadOnly;
  final List<ForumComment> comments;
  final List<String> tags;

  const ForumTopicDetailResult({
    this.topic,
    required this.body,
    required this.likesCount,
    required this.isLiked,
    required this.isSaved,
    this.isReadOnly = false,
    required this.comments,
    this.tags = const [],
  });
}

class ForumTopicsResult {
  final List<ForumTopic> topics;
  final List<ForumCategory> categories;
  const ForumTopicsResult({required this.topics, required this.categories});
}

/// Referência mínima de um comentário — usada para resolver o topic_id a partir
/// de um comment_id que chega nas notificações (reference_type = 'comment').
class ForumCommentRef {
  final int id;
  final int topicId;
  final int? parentId;
  const ForumCommentRef({required this.id, required this.topicId, this.parentId});
}

class CreateTopicResult {
  final int id;
  final String? joinCode;
  const CreateTopicResult({required this.id, this.joinCode});
}

class UserSearchResult {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  const UserSearchResult({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        avatarUrl: json['avatar_url']?.toString(),
      );
}

class ForumService {
  ForumService._();
  static final ForumService instance = ForumService._();

  final ApiClient _api = ApiClient.instance;

  // ── GET /forum/topics ───────────────────────────────────────────────────────

  Future<ForumTopicsResult> getTopics({
    String? filter,
    String? category,
    String? search,
  }) async {
    final data = await _getOptAuth('/forum/topics', query: {
      'filter': filter,
      'category': category,
      'search': search,
    });
    final topics = payloadList(data)
        .whereType<Map<String, dynamic>>()
        .map(ForumTopic.fromApiJson)
        .toList();
    List<ForumCategory> categories = const [];
    if (data is Map<String, dynamic>) {
      final meta = data['meta'];
      if (meta is Map<String, dynamic>) {
        final cats = meta['category_counts'];
        if (cats is List) {
          categories = cats
              .whereType<Map<String, dynamic>>()
              .map(ForumCategory.fromJson)
              .toList();
        }
      }
    }
    return ForumTopicsResult(topics: topics, categories: categories);
  }

  // ── GET /forum/topics/{id} ──────────────────────────────────────────────────

  Future<ForumTopicDetailResult> getTopicDetail(int id) async {
    final data = await _getOptAuth('/forum/topics/$id');
    if (data is! Map<String, dynamic>) throw const ApiException('Resposta inválida.');

    final body = data['body']?.toString() ?? '';
    final commentsRaw = data['comments'];
    final comments = commentsRaw is List
        ? commentsRaw
            .whereType<Map<String, dynamic>>()
            .map(ForumComment.fromApiJson)
            .toList()
        : const <ForumComment>[];

    final tagsRaw = data['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
            .whereType<Map>()
            .map((t) => t['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];

    ForumTopic? parsedTopic;
    try { parsedTopic = ForumTopic.fromApiJson(data); } catch (_) {}

    return ForumTopicDetailResult(
      topic: parsedTopic,
      body: body,
      likesCount: _parseInt(data['likes_count']),
      isLiked: data['is_liked'] == true,
      isSaved: data['is_saved'] == true,
      isReadOnly: data['is_read_only'] == true,
      comments: comments,
      tags: tags,
    );
  }

  // ── DELETE /forum/topics/{id} ─────────────────────────────────────────────

  Future<void> deleteTopic(int topicId) async {
    await _api.delete('/forum/topics/$topicId', authenticated: true);
  }

  // ── POST /forum/topics/{id}/like ────────────────────────────────────────────

  Future<LikeResult> likeTopic(int id) async {
    final data = await _api.post('/forum/topics/$id/like', authenticated: true);
    return LikeResult(
      liked: data['liked'] == true,
      likesCount: _parseInt(data['likes_count']),
    );
  }

  // ── GET /forum/topics?filter=saved ─────────────────────────────────────────

  Future<List<ForumTopic>> getSavedTopics() async {
    final data = await _api.get(
      '/forum/topics',
      query: {'filter': 'saved'},
      authenticated: true,
    );
    return payloadList(data)
        .whereType<Map<String, dynamic>>()
        .map(ForumTopic.fromApiJson)
        .toList();
  }

  // ── POST /forum/topics/{id}/bookmark ───────────────────────────────────────

  Future<bool> bookmarkTopic(int id) async {
    final data = await _api.post('/forum/topics/$id/bookmark', authenticated: true);
    return data['bookmarked'] == true;
  }

  // ── POST /forum/topics/{id}/comments ───────────────────────────────────────

  Future<ForumComment> postComment(int topicId, String text, {int? parentId}) async {
    final body = <String, dynamic>{'text': text};
    if (parentId != null) body['parent_id'] = parentId;
    final data = await _api.post(
      '/forum/topics/$topicId/comments',
      body: body,
      authenticated: true,
    );
    return ForumComment.fromApiJson(data);
  }

  // ── POST /forum/invites/{id}/accept ───────────────────────────────────────

  /// Aceita um convite e devolve o tópico completo com has_access:true.
  Future<ForumTopic> acceptInvite(int inviteId) async {
    final data = await _api.post('/forum/invites/$inviteId/accept', authenticated: true);
    if (data is Map<String, dynamic>) {
      final topicJson = data['topic'] ?? data['data'] ?? data;
      if (topicJson is Map<String, dynamic> && topicJson.containsKey('id')) {
        return ForumTopic.fromApiJson(topicJson);
      }
    }
    throw const ApiException('Não foi possível obter o tópico após aceitar o convite.');
  }

  // ── POST /forum/invites/{id}/reject ───────────────────────────────────────

  Future<void> rejectInvite(int inviteId) async {
    await _api.post('/forum/invites/$inviteId/reject', authenticated: true);
  }

  // ── POST /forum/topics/{id}/join-with-code ────────────────────────────────

  /// Entra num tópico privado via código e devolve o tópico completo com has_access:true.
  Future<ForumTopic> joinWithCode(int topicId, String code) async {
    final data = await _api.post(
      '/forum/topics/$topicId/join-with-code',
      body: {'join_code': code.toUpperCase()},
      authenticated: true,
    );
    if (data is Map<String, dynamic>) {
      final topicJson = data['topic'] ?? data['data'] ?? data;
      if (topicJson is Map<String, dynamic> && topicJson.containsKey('id')) {
        return ForumTopic.fromApiJson(topicJson);
      }
    }
    throw const ApiException('Não foi possível obter o tópico após entrar.');
  }

  // ── POST /forum/topics/{id}/request-access ─────────────────────────────────

  Future<void> requestAccess(int topicId, String message) async {
    await _api.post(
      '/forum/topics/$topicId/request-access',
      body: {'message': message},
      authenticated: true,
    );
  }

  // ── GET /forum/topics/{topicId}/access-requests ──────────────────────────

  Future<List<AccessRequestDetail>> getAccessRequests(int topicId) async {
    final data = await _api.get('/forum/topics/$topicId/access-requests', authenticated: true);
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['access_requests'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AccessRequestDetail.fromJson)
        .toList();
  }

  // ── PATCH /forum/topics/{topicId}/access-requests/{requestId}/approve ────

  Future<void> approveAccessRequest(int topicId, int requestId) async {
    await _api.patch('/forum/topics/$topicId/access-requests/$requestId/approve', authenticated: true);
  }

  // ── PATCH /forum/topics/{topicId}/access-requests/{requestId}/reject ─────

  Future<void> rejectAccessRequest(int topicId, int requestId) async {
    await _api.patch('/forum/topics/$topicId/access-requests/$requestId/reject', authenticated: true);
  }

  // ── GET /forum/comments/{id} ──────────────────────────────────────────────
  // Usado para resolver o topic_id a partir de um comment_id em notificações.

  Future<ForumCommentRef> getComment(int commentId) async {
    final data = await _api.get('/forum/comments/$commentId', authenticated: true);
    if (data is! Map<String, dynamic>) throw const ApiException('Resposta inválida.');
    final topicId = _parseInt(data['forum_topic_id']);
    if (topicId <= 0) throw const ApiException('Tópico não encontrado.');
    return ForumCommentRef(
      id: _parseInt(data['id']),
      topicId: topicId,
      parentId: data['parent_id'] != null ? _parseInt(data['parent_id']) : null,
    );
  }

  // ── DELETE /forum/comments/{id} ────────────────────────────────────────────

  Future<void> deleteComment(int commentId) async {
    await _api.delete('/forum/comments/$commentId', authenticated: true);
  }

  // ── POST /forum/comments/{id}/like ─────────────────────────────────────────

  Future<LikeResult> likeComment(int id) async {
    final data = await _api.post('/forum/comments/$id/like', authenticated: true);
    return LikeResult(
      liked: data['liked'] == true,
      likesCount: _parseInt(data['likes_count']),
    );
  }

  // ── GET /tags?trending=true  or  GET /tags?search=... ──────────────────────

  Future<List<ForumTag>> getTags(String search) async {
    final trimmed = search.trim();
    final query = trimmed.isEmpty
        ? <String, String?>{'trending': 'true'}
        : <String, String?>{'search': trimmed};
    final data = await _api.get('/tags', query: query);
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(ForumTag.fromJson).toList();
  }

  // ── GET categories from /forum/topics meta ──────────────────────────────────

  Future<List<ForumCategory>> getCategories() async {
    try {
      final data = await _api.get('/forum/topics');
      if (data is Map<String, dynamic>) {
        final meta = data['meta'];
        if (meta is Map<String, dynamic>) {
          final cats = meta['category_counts'];
          if (cats is List) {
            return cats
                .whereType<Map<String, dynamic>>()
                .map(ForumCategory.fromJson)
                .toList();
          }
        }
      }
    } catch (_) {}
    return const [];
  }

  // ── POST /forum/topics ─────────────────────────────────────────────────────

  Future<CreateTopicResult> createTopic({
    required String title,
    required String body,
    required int categoryId,
    bool isPrivate = false,
    bool isReadOnly = false,
    String? coverImageUrl,
    List<ForumTag> selectedTags = const [],
    List<String> newTagNames = const [],
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'category_id': categoryId,
      'visibility': isPrivate ? 'PRIVATE' : 'PUBLIC',
      'is_read_only': isReadOnly,
    };
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      payload['cover_image_url'] = coverImageUrl;
    }
    if (selectedTags.isNotEmpty) {
      payload['tag_ids'] = selectedTags.map((t) => t.id).toList();
    }
    if (newTagNames.isNotEmpty) {
      payload['tags'] = newTagNames.map((t) => t.replaceFirst('#', '')).toList();
    }
    final data = await _api.post('/forum/topics', body: payload, authenticated: true);
    return CreateTopicResult(
      id: _parseInt(data['id']),
      joinCode: data['join_code']?.toString(),
    );
  }

  // ── GET /users/search ──────────────────────────────────────────────────────

  Future<List<UserSearchResult>> searchUsers(String query, {int? topicId}) async {
    final q = <String, String?>{'q': query};
    if (topicId != null) q['topic_id'] = topicId.toString();
    final data = await _api.get('/users/search', query: q, authenticated: true);
    final list = data is List ? data : (data is Map ? data['data'] : null);
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().map(UserSearchResult.fromJson).toList();
  }

  // ── POST /forum/topics/{id}/invite ─────────────────────────────────────────

  Future<void> inviteUsers(int topicId, List<int> userIds) async {
    await _api.post(
      '/forum/topics/$topicId/invite',
      body: {'user_ids': userIds},
      authenticated: true,
    );
  }

  // ── PUT /forum/topics/{id} ─────────────────────────────────────────────────

  Future<void> updateTopic({
    required int id,
    required String title,
    required String body,
    required int categoryId,
    bool isPrivate = false,
    bool isReadOnly = false,
    String? coverImageUrl,
    List<ForumTag> selectedTags = const [],
    List<String> newTagNames = const [],
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'category_id': categoryId,
      'visibility': isPrivate ? 'PRIVATE' : 'PUBLIC',
      'is_read_only': isReadOnly,
    };
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      payload['cover_image_url'] = coverImageUrl;
    }
    if (selectedTags.isNotEmpty) {
      payload['tag_ids'] = selectedTags.map((t) => t.id).toList();
    }
    if (newTagNames.isNotEmpty) {
      payload['tags'] = newTagNames.map((t) => t.replaceFirst('#', '')).toList();
    }
    await _api.put('/forum/topics/$id', body: payload, authenticated: true);
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Future<dynamic> _getOptAuth(String path, {Map<String, String?> query = const {}}) async {
    // Se já há token em cache, o utilizador está autenticado — envia sempre com auth
    // e deixa qualquer erro propagar (não faz fallback silencioso para guest mode).
    if (_api.cachedToken != null && _api.cachedToken!.isNotEmpty) {
      return _api.get(path, query: query, authenticated: true);
    }
    // Sem token: modo guest — retorna só tópicos PUBLIC.
    return _api.get(path, query: query);
  }
}

class ForumTag {
  final int id;
  final String name;
  final int usageCount;

  const ForumTag({required this.id, required this.name, this.usageCount = 0});

  factory ForumTag.fromJson(Map<String, dynamic> json) => ForumTag(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
        usageCount: _parseInt(json['usage_count']),
      );
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
