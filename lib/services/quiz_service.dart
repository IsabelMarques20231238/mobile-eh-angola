import '../screens/quiz/quiz_models.dart';
import 'api_client.dart';

typedef _JsonMap = Map<String, dynamic>;

class QuizService {
  QuizService(this._api);

  final ApiClient _api;

  // ── List & search ──────────────────────────────────────────────────────────

  Future<List<QuizModel>> listQuizzes({
    String? difficulty,
    String? search,
    String? filter,
    String? category,
    int page = 1,
  }) async {
    final payload = await _api.get('/quizzes', query: {
      'difficulty': difficulty,
      'search': search,
      'filter': filter,
      'category': category,
      'page': page.toString(),
    }, authenticated: true);
    return _payloadList(payload)
        .whereType<Map>()
        .map((e) => QuizModel.fromJson(_jsonMap(e)))
        .toList();
  }

  Future<QuizModel?> getFeatured() async {
    try {
      final payload = await _api.get('/quizzes/featured', authenticated: true);
      if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
      if (payload is List && payload.isNotEmpty) {
        return QuizModel.fromJson(_jsonMap(payload.first as Map));
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> getDifficulties() async {
    try {
      final payload = await _api.get('/quizzes/difficulties');
      if (payload is List) return payload.map((e) => e.toString()).toList();
    } catch (_) {}
    return ['Iniciante', 'Médio', 'Avançado'];
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<QuizModel> getQuiz(int id) async {
    final payload = await _api.get('/quizzes/$id', authenticated: true);
    if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
    throw const ApiException('Quiz não encontrado.');
  }

  Future<MyAttemptsResponse> getMyAttempts(int id) async {
    final payload =
        await _api.get('/quizzes/$id/my-attempts', authenticated: true);
    if (payload is Map<String, dynamic>) {
      return MyAttemptsResponse.fromJson(payload);
    }
    return MyAttemptsResponse(
        hasAttempted: false, attemptCount: 0, attempts: []);
  }

  // ── Play ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> answerQuestion(
    int quizId,
    int questionId,
    int answerOptionId,
  ) async {
    final payload = await _api.post(
      '/quizzes/$quizId/answer',
      body: {
        'question_id': questionId,
        'answer_option_id': answerOptionId,
      },
      authenticated: true,
    );
    if (payload is Map<String, dynamic>) return payload;
    throw const ApiException('Erro ao verificar resposta.');
  }

  Future<QuizAttemptModel> submitQuiz(
    int id,
    List<Map<String, int>> answers,
    int timeSpentSeconds,
  ) async {
    final payload = await _api.post(
      '/quizzes/$id/submit',
      body: {
        'answers': answers,
        'time_spent_seconds': timeSpentSeconds,
      },
      authenticated: true,
    );
    if (payload is Map<String, dynamic>) return QuizAttemptModel.fromJson(payload);
    throw const ApiException('Erro ao submeter quiz.');
  }

  // ── Rankings ───────────────────────────────────────────────────────────────

  Future<({List<RankingItemModel> ranking, Map<String, dynamic>? myPosition})>
      getQuizRanking(int id, {String? performance}) async {
    final payload = await _api.get(
      '/quizzes/$id/ranking',
      query: {'performance': performance},
      authenticated: true,
    );
    if (payload is! Map<String, dynamic>) {
      return (ranking: <RankingItemModel>[], myPosition: null);
    }
    final list = (payload['ranking'] as List? ?? [])
        .map((e) => RankingItemModel.fromJson(_jsonMap(e as Map)))
        .toList();
    final myPos = payload['my_position'] as Map<String, dynamic>?;
    return (ranking: list, myPosition: myPos);
  }

  Future<({List<GlobalRankingItemModel> ranking, Map<String, dynamic>? myPosition, String? updatedAtHuman})>
      getGlobalRanking() async {
    final payload = await _api.get('/quiz-ranking/global', authenticated: true);
    if (payload is! Map<String, dynamic>) {
      return (ranking: <GlobalRankingItemModel>[], myPosition: null, updatedAtHuman: null);
    }
    final list = (payload['ranking'] as List? ?? [])
        .map((e) => GlobalRankingItemModel.fromJson(_jsonMap(e as Map)))
        .toList();
    final myPos = payload['my_position'] as Map<String, dynamic>?;
    final updatedAt = payload['updated_at_human'] as String?;
    return (ranking: list, myPosition: myPos, updatedAtHuman: updatedAt);
  }

  // ── Creation ───────────────────────────────────────────────────────────────

  Future<QuizModel> generateAiQuiz({
    required String title,
    required String topic,
    required String difficulty,
    required int numQuestions,
    int? categoryId,
    int? articleId,
    String? context,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'topic': topic,
      'difficulty': difficulty,
      'num_questions': numQuestions,
    };
    if (categoryId != null) body['category_id'] = categoryId;
    if (articleId != null) body['article_id'] = articleId;
    if (context != null && context.isNotEmpty) body['context'] = context;

    final payload = await _api.post(
      '/quizzes/generate-ai',
      body: body,
      authenticated: true,
      timeout: const Duration(seconds: 120),
    );
    if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
    throw const ApiException('Erro ao gerar quiz com IA.');
  }

  Future<QuizModel> createQuiz(Map<String, dynamic> body) async {
    final payload =
        await _api.post('/quizzes', body: body, authenticated: true);
    if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
    throw const ApiException('Erro ao criar quiz.');
  }

  Future<List<QuizModel>> getMyQuizzes() async {
    final payload = await _api.get('/my-quizzes', authenticated: true);
    return _payloadList(payload)
        .whereType<Map>()
        .map((e) => QuizModel.fromJson(_jsonMap(e)))
        .toList();
  }

  // ── Categories & article search ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final payload = await _api.get('/categories', authenticated: true);
      return _payloadList(payload).whereType<Map>().map(_jsonMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    try {
      final payload = await _api.get('/contents', query: {
        'search': query.isEmpty ? null : query,
        'type': 'ARTICLE',
        'status': 'PUBLISHED',
      }, authenticated: true);
      return _payloadList(payload).whereType<Map>().map(_jsonMap).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Admin review ───────────────────────────────────────────────────────────

  Future<QuizModel> adminGetReview(int id) async {
    final payload =
        await _api.get('/admin/quizzes/$id/review', authenticated: true);
    if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
    throw const ApiException('Quiz não encontrado.');
  }

  Future<void> adminApprove(int id) async {
    await _api.put('/admin/quizzes/$id/approve', authenticated: true);
  }

  Future<void> adminReject(int id, String reason) async {
    await _api.put(
      '/admin/quizzes/$id/reject',
      body: {'reason': reason},
      authenticated: true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<dynamic> _payloadList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map && payload['data'] is List) return payload['data'] as List;
    return const [];
  }

  _JsonMap _jsonMap(Map m) => m.cast<String, dynamic>();
}
