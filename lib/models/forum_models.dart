import 'package:flutter/material.dart';

enum TopicCategory { tudo, economia, historia, petroleo, politica }

enum TopicVisibility { publico, privado }

class ForumTopicPermissions {
  final bool canComment;
  final bool canEdit;
  final bool canDelete;
  final bool canPin;
  final bool canInvite;
  final bool canManageAccess;
  final bool canChangeReadOnly;

  const ForumTopicPermissions({
    this.canComment = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.canInvite = false,
    this.canManageAccess = false,
    this.canChangeReadOnly = false,
  });

  factory ForumTopicPermissions.fromJson(Map<String, dynamic> json) {
    return ForumTopicPermissions(
      canComment: json['can_comment'] == true,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canPin: json['can_pin'] == true,
      canInvite: json['can_invite'] == true,
      canManageAccess: json['can_manage_access'] == true,
      canChangeReadOnly: json['can_change_read_only'] == true,
    );
  }
}

// Avatar color palette — cycled by author ID
const List<List<Color>> _avatarPalette = [
  [Color(0xFF7B173F), Color(0xFFFFFFFF)],
  [Color(0xFF2F536B), Color(0xFFFFFFFF)],
  [Color(0xFF8B4B1F), Color(0xFFFFFFFF)],
  [Color(0xFF1B4F72), Color(0xFFFFFFFF)],
  [Color(0xFF0E6655), Color(0xFFFFFFFF)],
  [Color(0xFF7D3C98), Color(0xFFFFFFFF)],
  [Color(0xFF943126), Color(0xFFFFFFFF)],
  [Color(0xFF6366F1), Color(0xFFFFFFFF)],
  [Color(0xFFD946EF), Color(0xFFFFFFFF)],
  [Color(0xFF0891B2), Color(0xFFFFFFFF)],
];

class ForumTopic {
  final int id;
  final int authorId;
  final int categoryId;
  final String title;
  final String excerpt;
  final String authorName;
  final String authorInitials;
  final String authorRole;
  final TopicCategory category;
  final TopicVisibility visibility;
  final String timeAgo;
  final int comments;
  final int members;
  final int likes;
  final bool isPinned;
  final bool isLiked;
  final bool isSaved;
  final bool hasAccess;
  final bool isReadOnly;
  final String? imageUrl;
  final Color? avatarBg;
  final Color? avatarFg;
  final ForumTopicPermissions permissions;

  const ForumTopic({
    this.id = 0,
    this.authorId = 0,
    this.categoryId = 0,
    required this.title,
    required this.excerpt,
    required this.authorName,
    required this.authorInitials,
    this.authorRole = 'Membro',
    required this.category,
    this.visibility = TopicVisibility.publico,
    required this.timeAgo,
    required this.comments,
    this.members = 0,
    required this.likes,
    this.isPinned = false,
    this.isLiked = false,
    this.isSaved = false,
    this.hasAccess = true,
    this.isReadOnly = false,
    this.imageUrl,
    this.avatarBg,
    this.avatarFg,
    this.permissions = const ForumTopicPermissions(),
  });

  ForumTopic copyWith({
    String? title,
    int? likes,
    bool? isLiked,
    bool? isReadOnly,
    int? comments,
    int? members,
  }) =>
      ForumTopic(
        id: id,
        authorId: authorId,
        categoryId: categoryId,
        title: title ?? this.title,
        excerpt: excerpt,
        authorName: authorName,
        authorInitials: authorInitials,
        authorRole: authorRole,
        category: category,
        visibility: visibility,
        timeAgo: timeAgo,
        comments: comments ?? this.comments,
        members: members ?? this.members,
        likes: likes ?? this.likes,
        isPinned: isPinned,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved,
        hasAccess: hasAccess,
        isReadOnly: isReadOnly ?? this.isReadOnly,
        imageUrl: imageUrl,
        avatarBg: avatarBg,
        avatarFg: avatarFg,
        permissions: permissions,
      );

  factory ForumTopic.fromApiJson(Map<String, dynamic> json) {
    final authorJson = json['author'] ?? json['user'];
    final author = authorJson is Map<String, dynamic> ? authorJson : const <String, dynamic>{};
    final authorId = _parseInt(author['id']);
    final authorName = author['name']?.toString() ?? 'Utilizador';

    final parts = authorName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.isNotEmpty && parts.first.isNotEmpty
            ? parts.first[0].toUpperCase()
            : 'U';

    final pal = _avatarPalette[authorId % _avatarPalette.length];

    final catJson = json['category'];
    final catName = catJson is Map ? catJson['name']?.toString() ?? '' : '';
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');

    final catId = catJson is Map ? _parseInt(catJson['id']) : 0;

    return ForumTopic(
      id: _parseInt(json['id']),
      authorId: authorId,
      categoryId: catId,
      title: json['title']?.toString() ?? '',
      excerpt: json['body']?.toString() ?? '',
      authorName: authorName,
      authorInitials: initials,
      authorRole: author['display_role']?.toString() ?? 'Membro',
      category: _categoryFromName(catName),
      visibility: json['visibility']?.toString() == 'PRIVATE'
          ? TopicVisibility.privado
          : TopicVisibility.publico,
      timeAgo: _timeAgo(createdAt),
      comments: _parseInt(json['comments_count']),
      members: _parseInt(json['members_count']),
      likes: _parseInt(json['likes_count']),
      isPinned: json['is_pinned'] == true,
      isLiked: json['is_liked'] == true,
      isSaved: json['is_saved'] == true,
      hasAccess: json['has_access'] != false,
      isReadOnly: json['is_read_only'] == true,
      imageUrl: json['cover_image_url']?.toString(),
      avatarBg: pal[0],
      avatarFg: pal[1],
      permissions: json['permissions'] is Map<String, dynamic>
          ? ForumTopicPermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : const ForumTopicPermissions(),
    );
  }
}

class AccessRequestDetail {
  final int id;
  final String requesterName;
  final String requesterInitials;
  final Color avatarBg;
  final Color avatarFg;
  final String message;
  final int topicId;
  final String topicTitle;
  final String requesterRole;
  final DateTime? requestedAt;

  const AccessRequestDetail({
    required this.id,
    required this.requesterName,
    required this.requesterInitials,
    required this.avatarBg,
    required this.avatarFg,
    required this.message,
    required this.topicId,
    required this.topicTitle,
    required this.requesterRole,
    this.requestedAt,
  });

  factory AccessRequestDetail.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json['requester'];
    final user = userJson is Map<String, dynamic> ? userJson : const <String, dynamic>{};
    final userId = _parseInt(user['id']);
    final name = user['name']?.toString() ?? 'Utilizador';
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.isNotEmpty && parts.first.isNotEmpty
            ? parts.first[0].toUpperCase()
            : 'U';
    final pal = _avatarPalette[userId % _avatarPalette.length];

    final topicJson = json['topic'] ?? json['forum_topic'];
    final topic = topicJson is Map<String, dynamic> ? topicJson : const <String, dynamic>{};

    return AccessRequestDetail(
      id: _parseInt(json['id']),
      requesterName: name,
      requesterInitials: initials,
      avatarBg: pal[0],
      avatarFg: pal[1],
      message: json['message']?.toString() ?? '',
      topicId: _parseInt(topic['id'] ?? json['forum_topic_id']),
      topicTitle: topic['title']?.toString() ?? json['topic_title']?.toString() ?? '',
      requesterRole: user['role']?.toString() ?? user['user_role']?.toString() ?? '',
      requestedAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ForumComment {
  final String id;
  final int numericId;
  final int authorId;
  final int? parentId;
  final String? mentionUserName;
  final String authorName;
  final String authorInitials;
  final Color avatarBg;
  final Color avatarFg;
  final String text;
  final String timeAgo;
  final int likes;
  final bool isLiked;
  final List<ForumComment> replies;

  const ForumComment({
    required this.id,
    this.numericId = 0,
    this.authorId = 0,
    this.parentId,
    this.mentionUserName,
    required this.authorName,
    required this.authorInitials,
    required this.avatarBg,
    required this.avatarFg,
    required this.text,
    required this.timeAgo,
    required this.likes,
    this.isLiked = false,
    this.replies = const [],
  });

  ForumComment copyWith({
    List<ForumComment>? replies,
    int? likes,
    bool? isLiked,
  }) =>
      ForumComment(
        id: id,
        numericId: numericId,
        authorId: authorId,
        parentId: parentId,
        mentionUserName: mentionUserName,
        authorName: authorName,
        authorInitials: authorInitials,
        avatarBg: avatarBg,
        avatarFg: avatarFg,
        text: text,
        timeAgo: timeAgo,
        likes: likes ?? this.likes,
        isLiked: isLiked ?? this.isLiked,
        replies: replies ?? this.replies,
      );

  factory ForumComment.fromApiJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final author = authorJson is Map<String, dynamic> ? authorJson : const <String, dynamic>{};
    final authorId = _parseInt(author['id']);
    final authorName = author['name']?.toString() ?? 'Utilizador';

    final parts = authorName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.isNotEmpty && parts.first.isNotEmpty
            ? parts.first[0].toUpperCase()
            : 'U';

    final pal = _avatarPalette[authorId % _avatarPalette.length];
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final repliesRaw = json['replies'];
    final replies = repliesRaw is List
        ? repliesRaw.whereType<Map<String, dynamic>>().map(ForumComment.fromApiJson).toList()
        : const <ForumComment>[];
    final numericId = _parseInt(json['id']);
    final mentionUserJson = json['mention_user'];
    final mentionUserName = mentionUserJson is Map ? mentionUserJson['name']?.toString() : null;

    return ForumComment(
      id: numericId.toString(),
      numericId: numericId,
      authorId: authorId,
      parentId: json['parent_id'] != null ? _parseInt(json['parent_id']) : null,
      mentionUserName: mentionUserName,
      authorName: authorName,
      authorInitials: initials,
      avatarBg: pal[0],
      avatarFg: pal[1],
      text: json['text']?.toString() ?? '',
      timeAgo: _timeAgo(createdAt),
      likes: _parseInt(json['likes_count']),
      isLiked: json['is_liked'] == true,
      replies: replies,
    );
  }
}

class ForumCategory {
  final int id;
  final String name;

  const ForumCategory({required this.id, required this.name});

  factory ForumCategory.fromJson(Map<String, dynamic> json) => ForumCategory(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
      );
}

class SubscriptionAuthor {
  final String initials;
  final String name;
  final String role;
  final Color avatarBg;
  final Color avatarFg;

  const SubscriptionAuthor({
    required this.initials,
    required this.name,
    required this.role,
    required this.avatarBg,
    required this.avatarFg,
  });
}

class RecentPublication {
  final String authorInitials;
  final Color avatarBg;
  final Color avatarFg;
  final String publishedText;
  final String title;
  final String type;
  final String duration;
  final String timeAgo;

  const RecentPublication({
    required this.authorInitials,
    required this.avatarBg,
    required this.avatarFg,
    required this.publishedText,
    required this.title,
    required this.type,
    required this.duration,
    required this.timeAgo,
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

TopicCategory _categoryFromName(String name) {
  final l = name.toLowerCase();
  if (l.contains('econ')) return TopicCategory.economia;
  if (l.contains('hist')) return TopicCategory.historia;
  if (l.contains('petr') || l.contains('energ')) return TopicCategory.petroleo;
  if (l.contains('pol')) return TopicCategory.politica;
  return TopicCategory.tudo;
}

String _timeAgo(DateTime? date) {
  if (date == null) return 'Recente';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Há ${diff.inHours}h';
  if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
  return '${date.day}/${date.month}/${date.year}';
}
