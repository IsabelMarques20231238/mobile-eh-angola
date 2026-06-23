enum ReportType { article, comment, quiz }

enum ReportFilter { all, articles, comments, quiz }

extension ReportFilterLabel on ReportFilter {
  String get label => switch (this) {
    ReportFilter.all => 'Todos',
    ReportFilter.articles => 'Artigos',
    ReportFilter.comments => 'Comentários',
    ReportFilter.quiz => 'Quiz',
  };
}

enum ReportPriorityLabel {
  highPriority,
  urgentModeration,
  technicalReview,
}

extension ReportPriorityLabelText on ReportPriorityLabel {
  String get text => switch (this) {
    ReportPriorityLabel.highPriority => 'PRIORIDADE ALTA',
    ReportPriorityLabel.urgentModeration => 'MODERAÇÃO URGENTE',
    ReportPriorityLabel.technicalReview => 'REVISÃO TÉCNICA',
  };
}

class Report {
  final String id;
  final ReportType type;
  final ReportPriorityLabel priority;
  final String timeAgo;
  final String title;
  final String? author;
  final String? quote;
  final String? contextLine;
  final String? contextHighlight;
  final int reportCount;
  final String reasonTag;

  const Report({
    required this.id,
    required this.type,
    required this.priority,
    required this.timeAgo,
    required this.title,
    this.author,
    this.quote,
    this.contextLine,
    this.contextHighlight,
    required this.reportCount,
    required this.reasonTag,
  });
}

class ReportData {
  static const List<Report> initialReports = [
    const Report(
      id: '1',
      type: ReportType.article,
      priority: ReportPriorityLabel.highPriority,
      timeAgo: 'Há 2 horas',
      title: 'A exploração diamantífera na Lunda Norte: Impactos de 1980',
      author: 'Carlos Mendes',
      reportCount: 3,
      reasonTag: 'Informação incorrecta',
    ),
    const Report(
      id: '2',
      type: ReportType.comment,
      priority: ReportPriorityLabel.urgentModeration,
      timeAgo: 'Há 5 horas',
      title: '',
      quote:
          'Este comentário contém linguagem inapropriada em relação às políticas monetárias...',
      contextLine: 'Autor: João Figueira no artigo ',
      contextHighlight: 'Kwanza e a Desvalorização',
      reportCount: 1,
      reasonTag: 'Linguagem imprópria',
    ),
    const Report(
      id: '3',
      type: ReportType.quiz,
      priority: ReportPriorityLabel.technicalReview,
      timeAgo: 'Ontem',
      title: 'Quiz: A Era do Café em Angola',
      author: 'Equipa editorial',
      reportCount: 2,
      reasonTag: 'Erro factual',
    ),
    const Report(
      id: '4',
      type: ReportType.article,
      priority: ReportPriorityLabel.highPriority,
      timeAgo: 'Há 1 dia',
      title: 'Política cambial pós-independência: um olhar crítico',
      author: 'Maria Kassoma',
      reportCount: 2,
      reasonTag: 'Conteúdo ofensivo',
    ),
  ];
}

bool reportMatchesFilter(Report report, ReportFilter filter) {
  return switch (filter) {
    ReportFilter.all => true,
    ReportFilter.articles => report.type == ReportType.article,
    ReportFilter.comments => report.type == ReportType.comment,
    ReportFilter.quiz => report.type == ReportType.quiz,
  };
}
