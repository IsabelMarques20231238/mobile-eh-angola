import '../screens/quiz/quiz_models.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.roles = const [],
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Utilizador',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      roles: _asList(json['roles']).map((role) {
        if (role is Map) return role['role']?.toString() ?? '';
        return role.toString();
      }).where((role) => role.isNotEmpty).toList(),
    );
  }
}

class FeedContent {
  final String id;
  final String title;
  final String type;
  final String category;
  final String author;
  final String? coverImageUrl;
  final int views;
  final DateTime? createdAt;

  const FeedContent({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.author,
    this.coverImageUrl,
    this.views = 0,
    this.createdAt,
  });

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final author = json['author'];
    return FeedContent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conteudo sem titulo',
      type: _contentTypeLabel(json['type']?.toString()),
      category: category is Map ? category['name']?.toString() ?? 'Geral' : 'Geral',
      author: author is Map ? author['name']?.toString() ?? 'Autor' : 'Autor',
      coverImageUrl: json['cover_image_url']?.toString(),
      views: _asInt(json['views']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class ForumTopic {
  final String id;
  final String title;
  final String excerpt;
  final String category;
  final String author;
  final int comments;
  final int views;
  final DateTime? createdAt;

  const ForumTopic({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.author,
    this.comments = 0,
    this.views = 0,
    this.createdAt,
  });

  factory ForumTopic.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final author = json['author'] ?? json['user'];
    return ForumTopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Topico sem titulo',
      excerpt: json['body']?.toString() ?? json['excerpt']?.toString() ?? '',
      category: category is Map ? category['name']?.toString() ?? 'Geral' : 'Geral',
      author: author is Map ? author['name']?.toString() ?? 'Comunidade' : 'Comunidade',
      comments: _asInt(json['comments_count'] ?? json['comments']),
      views: _asInt(json['views']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class RankingItem {
  final int position;
  final String name;
  final int totalScore;
  final int quizzesCompleted;

  const RankingItem({
    required this.position,
    required this.name,
    required this.totalScore,
    required this.quizzesCompleted,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json, int position) {
    final user = json['user'];
    return RankingItem(
      position: position,
      name: user is Map ? user['name']?.toString() ?? 'Utilizador' : 'Utilizador',
      totalScore: _asInt(json['total_score']),
      quizzesCompleted: _asInt(json['quizzes_completed']),
    );
  }
}

Quiz quizFromJson(Map<String, dynamic> json) {
  final questions = _asList(json['questions']).whereType<Map>().map((question) {
    final options = _asList(question['answer_options'] ?? question['options']).whereType<Map>().map((option) {
      return QuizOption(
        id: option['id']?.toString() ?? '',
        text: option['text']?.toString() ?? '',
        isCorrect: option['is_correct'] == true || option['is_correct'] == 1,
      );
    }).toList();
    return QuizQuestion(
      id: question['id']?.toString() ?? '',
      question: question['text']?.toString() ?? question['question']?.toString() ?? '',
      imageUrl: question['image_url']?.toString(),
      options: options,
      explanation: question['explanation']?.toString() ?? '',
    );
  }).toList();

  final category = json['category'];
  final author = json['author'];
  return Quiz(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Quiz sem titulo',
    description: json['description']?.toString() ?? '',
    author: author is Map ? author['name']?.toString() ?? 'EH Angola' : 'EH Angola',
    authorRole: author is Map ? 'Autor' : 'Equipa',
    difficulty: _difficultyFromApi(json['difficulty']?.toString()),
    category: _categoryFromApi(category is Map ? category['name']?.toString() : null),
    questionCount: questions.isNotEmpty ? questions.length : _asInt(json['question_count'] ?? json['questions_count']),
    avgTime: json['avg_time']?.toString() ?? '--:--',
    questions: questions,
    isNew: json['is_new'] == true,
  );
}

List<dynamic> payloadList(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map && payload['data'] is List) return payload['data'] as List;
  return const [];
}

String timeAgo(DateTime? date) {
  if (date == null) return 'Recente';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inHours < 1) return 'Ha ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'Ha ${diff.inHours} horas';
  return 'Ha ${diff.inDays} dias';
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _contentTypeLabel(String? type) {
  switch (type) {
    case 'VIDEO':
      return 'Video';
    case 'PODCAST':
      return 'Podcast';
    case 'ARTICLE':
      return 'Artigo';
    default:
      return 'Conteudo';
  }
}

QuizDifficulty _difficultyFromApi(String? difficulty) {
  switch (difficulty) {
    case 'BEGINNER':
      return QuizDifficulty.facil;
    case 'ADVANCED':
      return QuizDifficulty.dificil;
    case 'INTERMEDIATE':
    default:
      return QuizDifficulty.medio;
  }
}

QuizCategory _categoryFromApi(String? category) {
  final value = category?.toLowerCase() ?? '';
  if (value.contains('hist')) return QuizCategory.historia;
  if (value.contains('polit')) return QuizCategory.politica;
  if (value.contains('cult')) return QuizCategory.cultura;
  return QuizCategory.economia;
}
