// ─── API Models for Quiz module ──────────────────────────────────────────────

enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyX on QuizDifficulty {
  // Labels that match the API exactly
  String get label {
    switch (this) {
      case QuizDifficulty.easy:   return 'Iniciante';
      case QuizDifficulty.medium: return 'Médio';
      case QuizDifficulty.hard:   return 'Avançado';
    }
  }
}

QuizDifficulty difficultyFromApi(String? value) {
  switch (value) {
    case 'Iniciante': return QuizDifficulty.easy;
    case 'Avançado':  return QuizDifficulty.hard;
    case 'Médio':
    default:          return QuizDifficulty.medium;
  }
}

// ─── AnswerOptionModel ────────────────────────────────────────────────────────

class AnswerOptionModel {
  final int id;
  final String text;
  final int quizPosition;
  final bool? isCorrect;
  final String? explanation;

  AnswerOptionModel({
    required this.id,
    required this.text,
    required this.quizPosition,
    this.isCorrect,
    this.explanation,
  });

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: json['id'] as int,
      text: json['text'] as String,
      quizPosition: json['quiz_position'] as int? ?? 0,
      isCorrect: json['is_correct'] as bool?,
      explanation: json['explanation'] as String?,
    );
  }
}

// ─── QuestionModel ────────────────────────────────────────────────────────────

class QuestionModel {
  final int id;
  final String text;
  final int orderIndex;
  final String? explanation;
  final List<AnswerOptionModel> options;

  QuestionModel({
    required this.id,
    required this.text,
    required this.orderIndex,
    this.explanation,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? json['answer_options'] as List? ?? [];
    final options = rawOptions
        .map((e) => AnswerOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    // The AI generator only stores the pedagogical explanation on the correct
    // option, not on the question itself — fall back to it when the root
    // 'explanation' is absent.
    String? correctOptionExplanation;
    for (final o in options) {
      if (o.isCorrect == true && (o.explanation?.isNotEmpty ?? false)) {
        correctOptionExplanation = o.explanation;
        break;
      }
    }
    final rootExplanation = json['explanation'] as String?;
    return QuestionModel(
      id: json['id'] as int,
      text: json['text'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      explanation: (rootExplanation?.isNotEmpty ?? false)
          ? rootExplanation
          : correctOptionExplanation,
      options: options,
    );
  }
}

// ─── ReviewInfoModel ──────────────────────────────────────────────────────────

class ReviewInfoModel {
  final String status;
  final Map<String, dynamic>? reviewedBy;
  final String? reviewedAt;
  final String? reviewedAtHuman;
  final String? rejectionReason;

  ReviewInfoModel({
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewedAtHuman,
    this.rejectionReason,
  });

  factory ReviewInfoModel.fromJson(Map<String, dynamic> json) {
    return ReviewInfoModel(
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] as Map<String, dynamic>?,
      reviewedAt: json['reviewed_at'] as String?,
      reviewedAtHuman: json['reviewed_at_human'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

// ─── QuizModel ────────────────────────────────────────────────────────────────

class QuizModel {
  final int id;
  final String title;
  final String? description;
  final String difficulty;
  final Map<String, dynamic>? category;
  final String? theme;
  final int questionCount;
  final int? durationMinutes;
  final int? avgTime;
  final int attemptsCount;
  final double avgScore;
  final int rewardPoints;
  final bool isAiGenerated;
  final String? coverImageUrl;
  final String status;
  final bool isNew;
  final Map<String, dynamic>? article;
  final Map<String, dynamic>? author;
  final double? userBestScore;
  final bool hasAttempted;
  final int userAttemptsCount;
  final DateTime? createdAt;
  final List<QuestionModel> questions;
  final List<Map<String, dynamic>> relatedArticles;
  final ReviewInfoModel? reviewInfo;
  final Map<String, dynamic>? deletionRequest;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    this.category,
    this.theme,
    required this.questionCount,
    this.durationMinutes,
    this.avgTime,
    required this.attemptsCount,
    required this.avgScore,
    required this.rewardPoints,
    required this.isAiGenerated,
    this.coverImageUrl,
    required this.status,
    required this.isNew,
    this.article,
    this.author,
    this.userBestScore,
    required this.hasAttempted,
    required this.userAttemptsCount,
    this.createdAt,
    this.questions = const [],
    this.relatedArticles = const [],
    this.reviewInfo,
    this.deletionRequest,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    final rawRelated = json['related_articles'] as List? ?? [];
    return QuizModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Iniciante',
      category: json['category'] as Map<String, dynamic>?,
      theme: json['theme'] as String?,
      questionCount: json['question_count'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      avgTime: json['avg_time'] as int?,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
      rewardPoints: json['reward_points'] as int? ?? 0,
      isAiGenerated: (json['is_ai_generated'] ?? json['generated_by_ai']) as bool? ?? false,
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status'] as String? ?? 'APPROVED',
      isNew: json['is_new'] as bool? ?? false,
      article: json['article'] as Map<String, dynamic>?,
      author: json['author'] as Map<String, dynamic>?,
      userBestScore: (json['user_best_score'] as num?)?.toDouble(),
      hasAttempted: json['has_attempted'] as bool? ?? false,
      userAttemptsCount: json['user_attempts_count'] as int? ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      questions: rawQuestions
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedArticles: rawRelated
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      reviewInfo: json['review_info'] == null
          ? null
          : ReviewInfoModel.fromJson(json['review_info'] as Map<String, dynamic>),
      deletionRequest: json['deletion_request'] as Map<String, dynamic>?,
    );
  }

  bool get hasPendingDeletionRequest => deletionRequest?['status'] == 'PENDING';

  QuizDifficulty get difficultyEnum => difficultyFromApi(difficulty);
  String get categoryName => category?['name'] as String? ?? theme ?? 'Geral';
  String get authorName => author?['name'] as String? ?? 'EH Angola';
  String get authorDisplayRole => author?['display_role'] as String? ?? 'Equipa';
  int get estimatedMinutes => durationMinutes ?? avgTime ?? 0;
}

// ─── AttemptAnswerModel ───────────────────────────────────────────────────────

class AttemptAnswerModel {
  final int? questionId;
  final String? questionText;
  final int? selectedOptionId;
  final String? selectedOptionText;
  final int? correctOptionId;
  final String? correctOptionText;
  final int? correctOptionIndex;
  final bool isCorrect;
  final String? explanation;

  AttemptAnswerModel({
    this.questionId,
    this.questionText,
    this.selectedOptionId,
    this.selectedOptionText,
    this.correctOptionId,
    this.correctOptionText,
    this.correctOptionIndex,
    required this.isCorrect,
    this.explanation,
  });

  factory AttemptAnswerModel.fromJson(Map<String, dynamic> json) {
    return AttemptAnswerModel(
      questionId: json['question_id'] as int?,
      questionText: json['question_text'] as String?,
      selectedOptionId: json['selected_option_id'] as int?,
      selectedOptionText: json['selected_option_text'] as String?,
      correctOptionId: json['correct_option_id'] as int?,
      correctOptionText: json['correct_option_text'] as String?,
      correctOptionIndex: json['correct_option_index'] as int? ??
          json['correctOptionIndex'] as int?,
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation'] as String?,
    );
  }
}

// ─── QuizAttemptModel ─────────────────────────────────────────────────────────

class QuizAttemptModel {
  final int? id;
  final int? attemptId;
  final int? attemptNumber;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final int? timeSpentSeconds;
  final int pointsEarned;
  final bool? isFirstAttempt;
  final String? completedAt;
  final String? completedAtHuman;
  final String? performance;
  final String? performanceMessage;
  final bool success;
  final List<AttemptAnswerModel> answers;

  QuizAttemptModel({
    this.id,
    this.attemptId,
    this.attemptNumber,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    this.timeSpentSeconds,
    required this.pointsEarned,
    this.isFirstAttempt,
    this.completedAt,
    this.completedAtHuman,
    this.performance,
    this.performanceMessage,
    required this.success,
    this.answers = const [],
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as List? ?? [];
    return QuizAttemptModel(
      id: json['id'] as int?,
      attemptId: json['attempt_id'] as int?,
      attemptNumber: json['attempt_number'] as int?,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers:
          json['correct_answers'] as int? ?? json['score'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] as int?,
      pointsEarned: json['points_earned'] as int? ?? 0,
      isFirstAttempt: json['is_first_attempt'] as bool?,
      completedAt: json['completed_at'] as String?,
      completedAtHuman: json['completed_at_human'] as String?,
      performance: json['performance'] as String?,
      performanceMessage: json['performance_message'] as String?,
      success: json['success'] as bool? ?? false,
      answers: rawAnswers
          .map((e) => AttemptAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── MyAttemptsResponse ───────────────────────────────────────────────────────

class MyAttemptsResponse {
  final bool hasAttempted;
  final int attemptCount;
  final QuizAttemptModel? firstAttempt;
  final List<QuizAttemptModel> attempts;

  MyAttemptsResponse({
    required this.hasAttempted,
    required this.attemptCount,
    this.firstAttempt,
    required this.attempts,
  });

  factory MyAttemptsResponse.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'] as List? ?? [];
    return MyAttemptsResponse(
      hasAttempted: json['has_attempted'] as bool? ?? false,
      attemptCount: json['attempt_count'] as int? ?? 0,
      firstAttempt: json['first_attempt'] == null
          ? null
          : QuizAttemptModel.fromJson(
              json['first_attempt'] as Map<String, dynamic>),
      attempts: rawAttempts
          .map((e) => QuizAttemptModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── RankingItemModel (quiz-specific) ────────────────────────────────────────

class RankingItemModel {
  final int position;
  final Map<String, dynamic>? user;
  final int score;
  final int totalQuestions;
  final double percentage;
  final int? timeSpentSeconds;
  final String? completedAt;
  final bool isFirstAttempt;

  RankingItemModel({
    required this.position,
    this.user,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    this.timeSpentSeconds,
    this.completedAt,
    required this.isFirstAttempt,
  });

  factory RankingItemModel.fromJson(Map<String, dynamic> json) {
    return RankingItemModel(
      position: json['position'] as int,
      user: json['user'] as Map<String, dynamic>?,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] as int?,
      completedAt: json['completed_at'] as String?,
      isFirstAttempt: json['is_first_attempt'] as bool? ?? true,
    );
  }

  String get userName => user?['name'] as String? ?? 'Utilizador';
  String get institution => user?['institution'] as String? ?? '';
  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }
}

// ─── GlobalRankingItemModel ───────────────────────────────────────────────────

class GlobalRankingItemModel {
  final int position;
  final Map<String, dynamic>? user;
  final int totalPoints;
  final int quizzesCompleted;
  final double avgAccuracy;

  GlobalRankingItemModel({
    required this.position,
    this.user,
    required this.totalPoints,
    required this.quizzesCompleted,
    required this.avgAccuracy,
  });

  factory GlobalRankingItemModel.fromJson(Map<String, dynamic> json) {
    return GlobalRankingItemModel(
      position: json['position'] as int,
      user: json['user'] as Map<String, dynamic>?,
      totalPoints: json['total_points'] as int? ?? 0,
      quizzesCompleted: json['quizzes_completed'] as int? ?? 0,
      avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble() ?? 0,
    );
  }

  String get userName => user?['name'] as String? ?? 'Utilizador';
  String get institution => user?['institution'] as String? ?? '';
  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }
}

// ─── DeletionRequestModel ─────────────────────────────────────────────────────

class DeletionRequestModel {
  final int id;
  final String status;
  final String reason;
  final DateTime? createdAt;
  final Map<String, dynamic> quiz;
  final Map<String, dynamic> requestedBy;

  DeletionRequestModel({
    required this.id,
    required this.status,
    required this.reason,
    this.createdAt,
    required this.quiz,
    required this.requestedBy,
  });

  factory DeletionRequestModel.fromJson(Map<String, dynamic> json) {
    return DeletionRequestModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      quiz: Map<String, dynamic>.from(json['quiz'] as Map? ?? {}),
      requestedBy: Map<String, dynamic>.from(json['requested_by'] as Map? ?? {}),
    );
  }

  int?   get quizId       => quiz['id'] as int?;
  String get quizTitle    => quiz['title'] as String? ?? 'Quiz';
  String get quizStatus   => quiz['status'] as String? ?? '';
  String get creatorName  => (quiz['creator'] as Map?)?['name'] as String? ?? 'Utilizador';
  String get requesterName => requestedBy['name'] as String? ?? 'Utilizador';
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String formatSeconds(int? seconds) {
  final value = seconds ?? 0;
  final minutes = (value ~/ 60).toString().padLeft(2, '0');
  final secs = (value % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}
