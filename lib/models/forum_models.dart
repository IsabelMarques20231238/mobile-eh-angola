import 'package:flutter/material.dart';

enum TopicCategory { tudo, economia, historia, petroleo, politica }

enum TopicVisibility { publico, privado }

class ForumTopic {
  final String title;
  final String excerpt;
  final String authorName;
  final String authorInitials;
  final TopicCategory category;
  final TopicVisibility visibility;
  final String timeAgo;
  final int comments;
  final int likes;
  final bool isPinned;
  final bool isLiked;
  final String? imageUrl;
  final Color? avatarBg;
  final Color? avatarFg;

  const ForumTopic({
    required this.title,
    required this.excerpt,
    required this.authorName,
    required this.authorInitials,
    required this.category,
    this.visibility = TopicVisibility.publico,
    required this.timeAgo,
    required this.comments,
    required this.likes,
    this.isPinned = false,
    this.isLiked = false,
    this.imageUrl,
    this.avatarBg,
    this.avatarFg,
  });
}

class ForumComment {
  final String id;
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
