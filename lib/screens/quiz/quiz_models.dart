// ─── Modelos de dados do módulo Quiz ────────────────────────────────────────

enum QuizDifficulty { facil, medio, dificil }
enum QuizCategory { historia, economia, politica, cultura }

extension QuizDifficultyLabel on QuizDifficulty {
  String get label {
    switch (this) {
      case QuizDifficulty.facil: return 'Fácil';
      case QuizDifficulty.medio: return 'Médio';
      case QuizDifficulty.dificil: return 'Difícil';
    }
  }
}

extension QuizCategoryLabel on QuizCategory {
  String get label {
    switch (this) {
      case QuizCategory.historia: return 'História';
      case QuizCategory.economia: return 'Economia';
      case QuizCategory.politica: return 'Política';
      case QuizCategory.cultura: return 'Cultura';
    }
  }
}

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final String? imageUrl;
  final List<QuizOption> options;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.explanation,
  });
}

class QuizAttempt {
  final int score;
  final int total;
  final String time;
  final bool passed;

  const QuizAttempt({
    required this.score,
    required this.total,
    required this.time,
    required this.passed,
  });
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String author;
  final String authorRole;
  final QuizDifficulty difficulty;
  final QuizCategory category;
  final int questionCount;
  final String avgTime;
  final List<QuizQuestion> questions;
  final List<QuizAttempt> attempts;
  final bool isNew;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.authorRole,
    required this.difficulty,
    required this.category,
    required this.questionCount,
    required this.avgTime,
    required this.questions,
    this.attempts = const [],
    this.isNew = false,
  });

  bool get attempted => attempts.isNotEmpty;
  QuizAttempt? get bestAttempt => attempts.isEmpty
      ? null
      : attempts.reduce((a, b) => a.score > b.score ? a : b);
}

class RankingEntry {
  final int position;
  final String name;
  final String institution;
  final int score;
  final int total;
  final bool isCurrentUser;
  final String? avatarInitials;

  const RankingEntry({
    required this.position,
    required this.name,
    required this.institution,
    required this.score,
    required this.total,
    this.isCurrentUser = false,
    this.avatarInitials,
  });
}

class RecommendedContent {
  final String type; // 'capitulo', 'leitura_rapida', 'video'
  final String title;
  final String subtitle;

  const RecommendedContent({
    required this.type,
    required this.title,
    required this.subtitle,
  });
}

// ─── Dados de exemplo ────────────────────────────────────────────────────────

class QuizData {
  static final List<Quiz> quizzes = [
    Quiz(
      id: '1',
      title: 'Desafios da Economia Colonial',
      description: 'Explora os principais desafios económicos do período colonial angolano.',
      author: 'Prof. Mendes',
      authorRole: 'Professor',
      difficulty: QuizDifficulty.medio,
      category: QuizCategory.economia,
      questionCount: 10,
      avgTime: '03:24',
      isNew: true,
      questions: _questoesColonial,
    ),
    Quiz(
      id: '2',
      title: 'A Moeda Kwanza: Origens',
      description: 'Aprende sobre a história da criação do Kwanza e o seu significado.',
      author: 'Prof. Mendes',
      authorRole: 'Professor',
      difficulty: QuizDifficulty.facil,
      category: QuizCategory.historia,
      questionCount: 10,
      avgTime: '02:45',
      questions: _questoesKwanza,
    ),
    Quiz(
      id: '3',
      title: 'A Reforma Monetária de 1999 e Seu Impacto',
      description: 'Explora os detalhes da transição para o Kwanza e como esta reforma estabilizou a economia angolana no final do século XX.',
      author: 'Prof. Ana Silva',
      authorRole: 'Admin',
      difficulty: QuizDifficulty.medio,
      category: QuizCategory.economia,
      questionCount: 10,
      avgTime: '03:24',
      questions: _questoesReforma,
      attempts: [
        QuizAttempt(score: 7, total: 10, time: '02:45', passed: true),
      ],
    ),
    Quiz(
      id: '4',
      title: 'Reformas Económicas de 1987',
      description: 'Analisa o Programa de Saneamento Económico e Financeiro (SEF) de 1987.',
      author: 'Prof. Mendes',
      authorRole: 'Professor',
      difficulty: QuizDifficulty.dificil,
      category: QuizCategory.economia,
      questionCount: 15,
      avgTime: '05:00',
      questions: _questoesReforma1987,
    ),
  ];

  static const List<QuizQuestion> _questoesColonial = [
    QuizQuestion(
      id: 'q1',
      question: 'Qual foi o principal produto de exportação de Angola durante o período colonial?',
      options: [
        QuizOption(id: 'a', text: 'Café', isCorrect: true),
        QuizOption(id: 'b', text: 'Diamantes', isCorrect: false),
        QuizOption(id: 'c', text: 'Petróleo', isCorrect: false),
        QuizOption(id: 'd', text: 'Algodão', isCorrect: false),
      ],
      explanation: 'O café foi o principal produto de exportação colonial, representando mais de 50% das receitas de exportação.',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'O sistema de trabalho forçado colonial em Angola era denominado:',
      options: [
        QuizOption(id: 'a', text: 'Senzala', isCorrect: false),
        QuizOption(id: 'b', text: 'Contrato', isCorrect: true),
        QuizOption(id: 'c', text: 'Corveia', isCorrect: false),
        QuizOption(id: 'd', text: 'Palmatorada', isCorrect: false),
      ],
      explanation: 'O "contrato" era o sistema de trabalho forçado imposto pelos colonizadores portugueses.',
    ),
  ];

  static const List<QuizQuestion> _questoesKwanza = [
    QuizQuestion(
      id: 'q1',
      question: 'Em que ano foi introduzido o Kwanza como moeda oficial de Angola?',
      options: [
        QuizOption(id: 'a', text: '1975', isCorrect: true),
        QuizOption(id: 'b', text: '1977', isCorrect: false),
        QuizOption(id: 'c', text: '1980', isCorrect: false),
        QuizOption(id: 'd', text: '1985', isCorrect: false),
      ],
      explanation: 'O Kwanza foi introduzido em 1975, aquando da independência de Angola.',
    ),
  ];

  static const List<QuizQuestion> _questoesReforma = [
    QuizQuestion(
      id: 'q1',
      question: 'Qual foi o impacto da reforma monetária de 1999 na economia angolana?',
      imageUrl: 'assets/images/kwanza.jpg',
      options: [
        QuizOption(id: 'a', text: 'Redução da inflação', isCorrect: false),
        QuizOption(id: 'b', text: 'Substituição do Kwanza', isCorrect: true),
        QuizOption(id: 'c', text: 'Redução da inflação', isCorrect: false),
        QuizOption(id: 'd', text: 'Redução da inflação', isCorrect: false),
      ],
      explanation: 'A estabilização do Kwanza foi o pilar central da reconstrução pós-conflito.',
    ),
    QuizQuestion(
      id: 'q2',
      question: 'Qual era a taxa de inflação anual antes da reforma de 1999?',
      options: [
        QuizOption(id: 'a', text: 'Abaixo de 50%', isCorrect: false),
        QuizOption(id: 'b', text: 'Entre 100% e 500%', isCorrect: false),
        QuizOption(id: 'c', text: 'Acima de 1000%', isCorrect: true),
        QuizOption(id: 'd', text: 'Entre 500% e 1000%', isCorrect: false),
      ],
      explanation: 'Angola enfrentou hiperinflação superior a 1000% ao ano antes da reforma.',
    ),
  ];

  static const List<QuizQuestion> _questoesReforma1987 = [
    QuizQuestion(
      id: 'q1',
      question: 'O Programa de Saneamento Económico e Financeiro (SEF) foi lançado em:',
      options: [
        QuizOption(id: 'a', text: '1985', isCorrect: false),
        QuizOption(id: 'b', text: '1987', isCorrect: true),
        QuizOption(id: 'c', text: '1989', isCorrect: false),
        QuizOption(id: 'd', text: '1991', isCorrect: false),
      ],
      explanation: 'O SEF foi lançado em 1987 como primeira tentativa de reforma económica estrutural.',
    ),
  ];

  static final List<RankingEntry> globalRanking = [
    RankingEntry(position: 1, name: 'Isabel Jamba', institution: 'ISPTEC', score: 10, total: 10, avatarInitials: 'IJ'),
    RankingEntry(position: 2, name: 'Carlos Neto', institution: 'UAN', score: 9, total: 10, avatarInitials: 'CN'),
    RankingEntry(position: 3, name: 'Miguel Rocha', institution: 'UCCA', score: 8, total: 10, avatarInitials: 'MR'),
    RankingEntry(position: 4, name: 'Pedro Gonçalves', institution: 'Universidade Agostinho Neto', score: 8, total: 10, avatarInitials: 'PG'),
    RankingEntry(position: 5, name: 'Sara Bento', institution: 'ISPTEC', score: 8, total: 10, avatarInitials: 'SB'),
    RankingEntry(position: 6, name: 'Ricardo Diniz', institution: 'DCSA', score: 8, total: 10, avatarInitials: 'RD'),
    RankingEntry(position: 7, name: 'Inês Santos', institution: 'Católica de Angola', score: 8, total: 10, avatarInitials: 'IS'),
    RankingEntry(position: 8, name: 'Carlos Mendes', institution: 'ISPTEC', score: 7, total: 10, isCurrentUser: true, avatarInitials: 'CM'),
  ];

  static final List<RecommendedContent> recommended = [
    RecommendedContent(
      type: 'capitulo',
      title: 'A Reforma Cambial em Angola (1990)',
      subtitle: 'Capítulo 4',
    ),
    RecommendedContent(
      type: 'leitura_rapida',
      title: 'Evolução do Kwanza no Pós-Independência',
      subtitle: 'Leitura Rápida',
    ),
  ];
}
