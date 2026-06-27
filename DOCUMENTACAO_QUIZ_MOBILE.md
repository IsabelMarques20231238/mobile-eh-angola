# Documentacao Quiz Mobile

Guia de integracao Flutter para o modulo Quiz da API Eh Angola.

## 1. Base URL e Headers

Base URL:

```text
https://api-ehangola-production.up.railway.app/api
```

Headers para endpoints autenticados:

```http
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

Nota: como a Base URL ja termina em `/api`, no client Flutter use paths como `/quizzes`, `/quizzes/{id}` e `/quiz-ranking/global`. Nesta documentacao tambem aparecem exemplos completos no formato `/api/...` para facilitar a leitura.

## 2. Fluxo Completo do Utilizador

### 2.1 Lista de Quizzes

Endpoints:

```http
GET /api/quizzes
GET /api/quizzes?difficulty=Médio
GET /api/quizzes?category=economia
GET /api/quizzes?filter=new
GET /api/quizzes?filter=most_played
GET /api/quizzes?search=reforma
GET /api/quizzes/featured
GET /api/quizzes/difficulties
```

`GET /api/quizzes` devolve uma resposta paginada do Laravel. Cada item de `data[]` tem o payload base do quiz:

```json
{
  "id": 12,
  "title": "Reforma economica em Angola",
  "description": "Quiz sobre economia angolana",
  "difficulty": "Médio",
  "category": {"id": 1, "name": "Economia"},
  "theme": "ECONOMIA",
  "question_count": 10,
  "duration_minutes": 12,
  "avg_time": 12,
  "attempts_count": 35,
  "avg_score": 74.5,
  "reward_points": 50,
  "is_ai_generated": false,
  "cover_image_url": null,
  "status": "APPROVED",
  "is_new": true,
  "article": {"id": 5, "title": "Artigo vinculado", "cover_image_url": null},
  "author": {
    "id": 2,
    "name": "Isabel",
    "avatar_url": null,
    "display_role": "Moderador"
  },
  "user_best_score": 80.0,
  "has_attempted": true,
  "user_attempts_count": 2,
  "created_at": "2026-06-27T10:00:00.000000Z"
}
```

Tipos principais:

| Campo | Tipo Dart | Observacao |
| --- | --- | --- |
| `id` | `int` | ID do quiz |
| `title` | `String` | Titulo |
| `description` | `String?` | Pode vir null |
| `difficulty` | `String` | Label: `Iniciante`, `Médio`, `Avançado` |
| `category` | `Map<String,dynamic>?` | `{id, name}` |
| `theme` | `String?` | Nome da categoria em uppercase |
| `question_count` | `int` | Total de perguntas |
| `duration_minutes` | `int?` | Duracao estimada |
| `avg_time` | `int?` | Alias de `duration_minutes` |
| `attempts_count` | `int` | Total de tentativas |
| `avg_score` | `double` | Percentagem media |
| `reward_points` | `int` | Pontos maximos configurados |
| `is_ai_generated` | `bool` | Origem IA |
| `status` | `String` | `APPROVED`, `PENDING`, `DRAFT`, `REJECTED` |
| `article` | `Map<String,dynamic>?` | Artigo vinculado |
| `author` | `Map<String,dynamic>?` | Usar `author['name']` e `display_role` |
| `has_attempted` | `bool` | Se o utilizador ja jogou |
| `user_attempts_count` | `int` | Numero de tentativas do utilizador |

Dart model sugerido:

```dart
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

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.theme,
    required this.questionCount,
    required this.durationMinutes,
    required this.avgTime,
    required this.attemptsCount,
    required this.avgScore,
    required this.rewardPoints,
    required this.isAiGenerated,
    required this.coverImageUrl,
    required this.status,
    required this.isNew,
    required this.article,
    required this.author,
    required this.userBestScore,
    required this.hasAttempted,
    required this.userAttemptsCount,
    required this.createdAt,
    required this.questions,
    required this.relatedArticles,
    required this.reviewInfo,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String,
      category: json['category'] as Map<String, dynamic>?,
      theme: json['theme'] as String?,
      questionCount: json['question_count'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      avgTime: json['avg_time'] as int?,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
      rewardPoints: json['reward_points'] as int? ?? 0,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status'] as String,
      isNew: json['is_new'] as bool? ?? false,
      article: json['article'] as Map<String, dynamic>?,
      author: json['author'] as Map<String, dynamic>?,
      userBestScore: (json['user_best_score'] as num?)?.toDouble(),
      hasAttempted: json['has_attempted'] as bool? ?? false,
      userAttemptsCount: json['user_attempts_count'] as int? ?? 0,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at']),
      questions: ((json['questions'] as List?) ?? [])
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedArticles: ((json['related_articles'] as List?) ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      reviewInfo: json['review_info'] == null
          ? null
          : ReviewInfoModel.fromJson(json['review_info'] as Map<String, dynamic>),
    );
  }
}
```

### 2.2 Detalhes do Quiz

Endpoints:

```http
GET /api/quizzes/{id}
GET /api/quizzes/{id}/my-attempts
GET /api/quizzes/{id}/ranking
GET /api/quizzes/{id}/ranking?performance=excellent
```

`GET /api/quizzes/{id}` devolve o payload base mais:

```json
{
  "questions": [
    {
      "id": 100,
      "text": "Pergunta do quiz?",
      "order_index": 1,
      "options": [
        {"id": 401, "text": "Opcao A", "quiz_position": 0},
        {"id": 402, "text": "Opcao B", "quiz_position": 1}
      ]
    }
  ],
  "related_articles": [
    {"id": 6, "title": "Artigo relacionado", "cover_image_url": null, "type": "ARTICLE"}
  ]
}
```

Para utilizadores comuns, `questions[].options[]` nao inclui `is_correct` nem `explanation`.

`GET /api/quizzes/{id}/my-attempts`:

```json
{
  "has_attempted": true,
  "attempt_count": 2,
  "first_attempt": {
    "id": 20,
    "score": 7,
    "total_questions": 10,
    "percentage": 70,
    "time_spent_seconds": 165,
    "completed_at": "2026-06-27T10:00:00.000000Z",
    "completed_at_human": "há 2 minutos",
    "performance": "Bom Trabalho!"
  },
  "attempts": [
    {
      "id": 20,
      "attempt_number": 1,
      "score": 7,
      "total_questions": 10,
      "percentage": 70,
      "time_spent_seconds": 165,
      "completed_at": "2026-06-27T10:00:00.000000Z",
      "completed_at_human": "há 2 minutos",
      "is_first_attempt": true,
      "performance": "Bom Trabalho!",
      "success": true
    }
  ]
}
```

Se nunca jogou:

```json
{
  "has_attempted": false,
  "attempt_count": 0,
  "first_attempt": null,
  "attempts": []
}
```

### 2.3 Jogar Quiz

Fluxo:

1. Carregar quiz com `GET /api/quizzes/{id}`.
2. Renderizar `questions[]` e `questions[].options[]`.
3. Nao avaliar localmente. A API nao envia `is_correct` durante o jogo.
4. Guardar localmente os IDs escolhidos.
5. Enviar tudo no fim com `POST /api/quizzes/{id}/submit`.

Estado local em Dart:

```dart
final List<Map<String, int>> answers = [];

answers.add({
  'question_id': question.id,
  'answer_option_id': selectedOption.id,
});
```

Submit:

```http
POST /api/quizzes/{id}/submit
```

Body:

```json
{
  "answers": [
    {"question_id": 1, "answer_option_id": 4}
  ],
  "time_spent_seconds": 165
}
```

Resposta:

```json
{
  "attempt_id": 30,
  "attempt_number": 1,
  "is_first_attempt": true,
  "score": 7,
  "total_questions": 10,
  "correct_answers": 7,
  "percentage": 70,
  "time_spent_seconds": 165,
  "points_earned": 70,
  "completed_at": "2026-06-27T10:00:00.000000Z",
  "performance": "Bom Trabalho!",
  "performance_message": "Bom Trabalho!",
  "success": true,
  "answers": [
    {
      "question_id": 1,
      "question_text": "Pergunta do quiz?",
      "selected_option_id": 4,
      "selected_option_text": "Resposta escolhida",
      "correct_option_id": 2,
      "correct_option_text": "Resposta correcta",
      "correct_option_index": 1,
      "correctOptionIndex": 1,
      "is_correct": false,
      "explanation": "Explicacao da resposta correcta."
    }
  ]
}
```

Campos importantes:

| Campo | Tipo Dart | Uso |
| --- | --- | --- |
| `score` | `int` | Acertos |
| `total_questions` | `int` | Total |
| `correct_answers` | `int` | Mesmo valor de `score` |
| `percentage` | `double` | Barra/progresso |
| `time_spent_seconds` | `int?` | Tempo total |
| `points_earned` | `int` | Pontos Jindungo ganhos nesta tentativa |
| `is_first_attempt` | `bool` | So primeira tentativa pontua |
| `attempt_number` | `int` | Numero da tentativa |
| `performance_message` | `String` | Badge textual |
| `success` | `bool` | `true` se `percentage >= 70` |
| `answers[]` | `List<AttemptAnswerModel>` | Feedback por pergunta |

### 2.4 Resultado

Campos a mostrar:

- `score/total_questions`: exemplo `7/10`.
- `time_spent_seconds`: formatar para `02:45`.
- Erros: `total_questions - correct_answers`.
- `percentage`: barra de progresso.
- `performance_message`: badge.
- `success`: aprovado se `true`.
- `is_first_attempt`: informar se ganhou pontos.
- `points_earned`: mostrar pontos Jindungo ganhos.
- `answers[]`: feedback por pergunta.
- `article`: artigo vinculado ao quiz.
- `related_articles`: artigos relacionados do detalhe do quiz.

Helper de tempo:

```dart
String formatSeconds(int? seconds) {
  final value = seconds ?? 0;
  final minutes = (value ~/ 60).toString().padLeft(2, '0');
  final secs = (value % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}
```

### 2.5 Ranking do Quiz

Endpoint:

```http
GET /api/quizzes/{id}/ranking
GET /api/quizzes/{id}/ranking?performance=all
GET /api/quizzes/{id}/ranking?performance=excellent
GET /api/quizzes/{id}/ranking?performance=good
GET /api/quizzes/{id}/ranking?performance=sufficient
```

Resposta:

```json
{
  "ranking": [
    {
      "position": 1,
      "user": {
        "id": 4,
        "name": "Membro Normal Um",
        "avatar_url": null,
        "institution": "ISPTEC"
      },
      "score": 9,
      "total_questions": 10,
      "percentage": 90,
      "time_spent_seconds": 130,
      "completed_at": "2026-06-27T10:00:00.000000Z",
      "is_first_attempt": true
    }
  ],
  "my_position": {
    "position": 3,
    "score": 7,
    "total_questions": 10,
    "percentage": 70,
    "time_spent_seconds": 165,
    "is_first_attempt": true
  },
  "updated_at": "2026-06-27T10:00:00.000000Z",
  "updated_at_human": "há 2 minutos"
}
```

Notas:

- `my_position` vem `null` se o utilizador autenticado nunca jogou o quiz.
- O criador do quiz nao aparece no ranking desse quiz.
- O ranking usa apenas a primeira tentativa de cada utilizador.
- Ordenacao: maior score, menor tempo, nome.
- `performance=excellent`: percentagem >= 90.
- `performance=good`: percentagem >= 70.
- `performance=sufficient`: percentagem >= 50.

### 2.6 Ranking Global

Endpoint:

```http
GET /api/quiz-ranking/global
```

Regra: so aparece quem jogou pelo menos 1 quiz `HARD`.

Resposta:

```json
{
  "ranking": [
    {
      "position": 1,
      "user": {
        "id": 4,
        "name": "Membro Normal Um",
        "avatar_url": null,
        "institution": "ISPTEC"
      },
      "total_points": 240,
      "quizzes_completed": 6,
      "avg_accuracy": 78.33
    }
  ],
  "my_position": {
    "position": 2,
    "total_points": 180,
    "quizzes_completed": 5,
    "avg_accuracy": 72
  },
  "updated_at": "2026-06-27T10:00:00.000000Z",
  "updated_at_human": "há 2 minutos"
}
```

`my_position` vem `null` se o utilizador nunca jogou quiz `HARD`.

## 3. Fluxo de Criacao

Disponivel apenas para `AUTHOR`, `ADMIN` e `SUPER_ADMIN`.

Antes de mostrar o botao "Criar Quiz":

```http
GET /api/me
```

Regra Flutter:

```dart
final canCreateQuiz = roles.contains('AUTHOR') ||
    roles.contains('ADMIN') ||
    roles.contains('SUPER_ADMIN');
```

Se for apenas `USER`, nao mostrar o botao.

### 3.1 Gerar com IA

```http
POST /api/quizzes/generate-ai
```

Body:

```json
{
  "title": "Quiz sobre economia",
  "topic": "tema principal",
  "difficulty": "EASY",
  "num_questions": 10,
  "category_id": 2,
  "article_id": 5,
  "context": "opcional"
}
```

Observacao importante: a API valida `difficulty` pelos labels usados no backend de criacao: `Iniciante`, `Médio`, `Avançado`. Se o Flutter trabalhar internamente com `EASY|MEDIUM|HARD`, converter antes de enviar.

Exemplo de conversao:

```dart
String difficultyToApiLabel(QuizDifficulty difficulty) {
  switch (difficulty) {
    case QuizDifficulty.easy:
      return 'Iniciante';
    case QuizDifficulty.medium:
      return 'Médio';
    case QuizDifficulty.hard:
      return 'Avançado';
  }
}
```

Retorno:

- Quiz completo com perguntas geradas.
- `AUTHOR`: status `PENDING`.
- `ADMIN` ou `SUPER_ADMIN`: status `APPROVED`.

### 3.2 Criar Manualmente

```http
POST /api/quizzes
```

Body completo:

```json
{
  "title": "Quiz manual",
  "description": "Descricao opcional",
  "difficulty": "Médio",
  "article_id": 5,
  "category_id": 2,
  "duration_minutes": 10,
  "time_limit_seconds": 600,
  "reward_points": 50,
  "questions": [
    {
      "text": "Pergunta 1?",
      "explanation": "Explicacao educativa da pergunta.",
      "options": [
        {"text": "Opcao A", "is_correct": true, "explanation": "Porque esta correcta."},
        {"text": "Opcao B", "is_correct": false},
        {"text": "Opcao C", "is_correct": false},
        {"text": "Opcao D", "is_correct": false}
      ]
    }
  ]
}
```

Regras:

- Maximo 20 perguntas.
- Exactamente 4 opcoes por pergunta.
- Exactamente 1 `is_correct=true` por pergunta.
- `explanation` por pergunta deve ser preenchida no Flutter.
- `article_id` e obrigatorio.
- A API tambem aceita `answer_options`, mas o formato recomendado no Flutter e `options`.

### 3.3 Guardar Rascunho

```http
POST /api/quizzes
```

Com:

```json
{
  "status": "DRAFT"
}
```

Editar depois:

```http
PUT /api/quizzes/{id}
```

Regra: quiz `APPROVED` nao pode ser editado. A API devolve `403`.

### 3.4 Meus Quizzes

```http
GET /api/my-quizzes
```

Retorna os quizzes criados pelo utilizador autenticado, com todos os status. Para criador/admin inclui `review_info`, incluindo `rejection_reason` quando aplicavel.

## 4. Notificacoes do Quiz

Tipos a tratar no Flutter:

### QUIZ_PENDING_REVIEW

Quem recebe: admin.

Acao:

- Navegar para tela de revisao do quiz.
- `reference_id = quiz_id`.

### QUIZ_APPROVED

Quem recebe: criador.

Acao:

- Navegar para `GET /api/quizzes/{reference_id}`.
- Mostrar mensagem de sucesso.

### QUIZ_REJECTED

Quem recebe: criador.

Acao:

- Navegar para `GET /api/my-quizzes`.
- Mostrar `rejection_reason`.

Ao clicar numa notificacao:

```http
PUT /api/notifications/{id}/read
```

## 5. Tela de Revisao Admin

Endpoints:

```http
GET /api/admin/quizzes/{id}/review
PUT /api/admin/quizzes/{id}/approve
PUT /api/admin/quizzes/{id}/reject
```

Tela de revisao:

- Renderizar perguntas e opcoes.
- Nao pintar a opcao correcta em verde na revisao inicial.
- Mostrar dados do criador, artigo vinculado, categoria e status.

Aprovar:

```http
PUT /api/admin/quizzes/{id}/approve
```

Rejeitar:

```http
PUT /api/admin/quizzes/{id}/reject
```

Body:

```json
{
  "reason": "motivo"
}
```

`reason` e obrigatorio.

## 6. Regras de Negocio Importantes

- Dificuldade exibida: `EASY -> Iniciante`, `MEDIUM -> Médio`, `HARD -> Avançado`.
- Usar `GET /api/quizzes/difficulties` para popular filtros.
- So a primeira tentativa conta para ranking.
- Pontos Jindungo so sao ganhos na primeira tentativa.
- Criador do quiz nao aparece no ranking desse quiz.
- Ranking global: so quem jogou pelo menos 1 quiz `HARD`.
- Quiz `APPROVED` nao pode ser editado.
- Todo quiz deve ter `article_id` obrigatorio na criacao.
- `display_role` do author deve ser sempre usado: `USER -> Membro`, `AUTHOR -> Escritor`, `ADMIN/SUPER_ADMIN -> Moderador`.
- `review_info` guarda historico de aprovacao: `reviewed_by.name`, `reviewed_at_human`, `rejection_reason`.
- `success` e `true` se `percentage >= 70`.
- `performance_message` e baseado na percentagem.
- O app nao deve avaliar respostas localmente antes do submit.

## 7. Modelos Dart Sugeridos

### QuestionModel

```dart
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
    required this.explanation,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      text: json['text'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      options: ((json['options'] as List?) ?? [])
          .map((e) => AnswerOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

### AnswerOptionModel

```dart
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
    required this.isCorrect,
    required this.explanation,
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
```

### QuizAttemptModel

```dart
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
    required this.id,
    required this.attemptId,
    required this.attemptNumber,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.timeSpentSeconds,
    required this.pointsEarned,
    required this.isFirstAttempt,
    required this.completedAt,
    required this.completedAtHuman,
    required this.performance,
    required this.performanceMessage,
    required this.success,
    required this.answers,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as int?,
      attemptId: json['attempt_id'] as int?,
      attemptNumber: json['attempt_number'] as int?,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? json['score'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] as int?,
      pointsEarned: json['points_earned'] as int? ?? 0,
      isFirstAttempt: json['is_first_attempt'] as bool?,
      completedAt: json['completed_at'] as String?,
      completedAtHuman: json['completed_at_human'] as String?,
      performance: json['performance'] as String?,
      performanceMessage: json['performance_message'] as String?,
      success: json['success'] as bool? ?? false,
      answers: ((json['answers'] as List?) ?? [])
          .map((e) => AttemptAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

### AttemptAnswerModel

```dart
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
    required this.questionId,
    required this.questionText,
    required this.selectedOptionId,
    required this.selectedOptionText,
    required this.correctOptionId,
    required this.correctOptionText,
    required this.correctOptionIndex,
    required this.isCorrect,
    required this.explanation,
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
```

### RankingItemModel

```dart
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
    required this.user,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.timeSpentSeconds,
    required this.completedAt,
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
}
```

### GlobalRankingItemModel

```dart
class GlobalRankingItemModel {
  final int position;
  final Map<String, dynamic>? user;
  final int totalPoints;
  final int quizzesCompleted;
  final double avgAccuracy;

  GlobalRankingItemModel({
    required this.position,
    required this.user,
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
}
```

### ReviewInfoModel

```dart
class ReviewInfoModel {
  final String status;
  final Map<String, dynamic>? reviewedBy;
  final String? reviewedAt;
  final String? reviewedAtHuman;
  final String? rejectionReason;

  ReviewInfoModel({
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.reviewedAtHuman,
    required this.rejectionReason,
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
```

## 8. Incompatibilidades Conhecidas a Corrigir

No ficheiro Flutter `quiz_models.dart` actual:

### A. `_difficultyFromApi()`

Corrigir mapeamento:

```dart
QuizDifficulty _difficultyFromApi(String value) {
  switch (value) {
    case 'Iniciante':
      return QuizDifficulty.easy;
    case 'Médio':
      return QuizDifficulty.medium;
    case 'Avançado':
      return QuizDifficulty.hard;
    default:
      throw ArgumentError('Dificuldade desconhecida: $value');
  }
}
```

Nao usar `BEGINNER`, `INTERMEDIATE`, `ADVANCED`.

### B. `options[]`

Nao e `List<String>`.

E:

```dart
List<AnswerOptionModel>
```

Cada opcao tem `id`, `text` e `quiz_position`. Guardar o `id` para o submit:

```dart
{
  'question_id': question.id,
  'answer_option_id': selectedOption.id,
}
```

### C. `correctOptionIndex`

Nao existe no payload do detalhe do quiz.

So vem na resposta do submit dentro de `answers[]`, como `correct_option_index` e tambem `correctOptionIndex`. Nao avaliar localmente.

### D. `author`

Nao e `String`.

E objecto:

```json
{
  "id": 2,
  "name": "Isabel",
  "avatar_url": null,
  "display_role": "Moderador"
}
```

Usar:

```dart
quiz.author?['name']
quiz.author?['display_role']
```

### E. `avg_time`

`avg_time` e alias de `duration_minutes`.

Ambos podem vir no payload. Para UI, usar `duration_minutes ?? avg_time`.
