import '../screens/quiz/quiz_models.dart';
import 'api_client.dart';
import 'api_models.dart';

class ContentService {
  ContentService(this._api);

  final ApiClient _api;

  Future<List<FeedContent>> listContents({String? search, String? type, int page = 1}) async {
    final payload = await _api.get('/contents', query: {
      'search': search,
      'type': type,
      'page': page.toString(),
    });
    return payloadList(payload)
        .whereType<Map>()
        .map((item) => FeedContent.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<QuizModel>> listQuizzes({String? difficulty, int page = 1}) async {
    final payload = await _api.get('/quizzes', query: {
      'difficulty': difficulty,
      'page': page.toString(),
    }, authenticated: true);
    return payloadList(payload)
        .whereType<Map>()
        .map((item) => QuizModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<QuizModel> getQuiz(int id) async {
    final payload = await _api.get('/quizzes/$id', authenticated: true);
    if (payload is Map<String, dynamic>) return QuizModel.fromJson(payload);
    throw const ApiException('Quiz não encontrado.');
  }

  Future<List<ForumTopic>> listForumTopics({String? search, int page = 1}) async {
    final payload = await _api.get('/forum', query: {
      'search': search,
      'page': page.toString(),
    });
    return payloadList(payload)
        .whereType<Map>()
        .map((item) => ForumTopic.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<RankingItem>> ranking({String period = 'ALL_TIME'}) async {
    final payload = await _api.get('/ranking', query: {'period': period});
    return payloadList(payload)
        .asMap()
        .entries
        .where((entry) => entry.value is Map)
        .map((entry) {
      return RankingItem.fromJson(
          Map<String, dynamic>.from(entry.value as Map), entry.key + 1);
    }).toList();
  }
}
