import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'forum_models.dart';

List<ForumTopic> buildMockTopics() => const [
  ForumTopic(
    title: 'Bem-vindo ao Fórum: Regras de Conduta 👋',
    excerpt:
        'Este é um espaço de debate académico e profissional. Por favor, leia atentamente as regras antes de participar.',
    authorName: 'Admin',
    authorInitials: 'AD',
    category: TopicCategory.tudo,
    timeAgo: '15 Mai 2024',
    comments: 156,
    likes: 89,
    isPinned: true,
    avatarBg: Color(0xFFFF2D64),
    avatarFg: Colors.white,
  ),
  ForumTopic(
    title:
        'O impacto da introdução do Kwanza na economia rural pós-independência',
    excerpt:
        'A reforma monetária de 1977, que substituiu o Escudo pelo Kwanza, marcou um ponto de viragem nas trocas rurais.',
    authorName: 'Carlos Mendes',
    authorInitials: 'CM',
    category: TopicCategory.economia,
    timeAgo: '12 Abr 2026',
    comments: 8,
    likes: 12,
    isLiked: true,
    imageUrl:
        'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=900&q=80',
    avatarBg: Color(0xFFD946EF),
    avatarFg: Colors.white,
  ),
  ForumTopic(
    title: 'Transição energética e o potencial solar no deserto do Namibe',
    excerpt:
        'Estudos recentes indicam viabilidade para projectos de energia solar em larga escala no sul de Angola.',
    authorName: 'Carlos Mendes',
    authorInitials: 'CM',
    category: TopicCategory.petroleo,
    timeAgo: 'Há 2 dias',
    comments: 4,
    likes: 19,
    imageUrl:
        'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=900&q=80',
    avatarBg: Color(0xFFD946EF),
    avatarFg: Colors.white,
  ),
  ForumTopic(
    title: 'Impacto das Reformas Económicas em Angola (1990-2000)',
    excerpt:
        'Este é um espaço de discussão restrito e privado sobre as reformas económicas estruturais levadas a cabo em Angola.',
    authorName: 'Prof. Ana Silva',
    authorInitials: 'AS',
    category: TopicCategory.economia,
    visibility: TopicVisibility.privado,
    timeAgo: 'Há 3 dias',
    comments: 156,
    likes: 48,
    avatarBg: Color(0xFF7B001C),
    avatarFg: Colors.white,
  ),
  ForumTopic(
    title: 'Desafios da governação local em Angola: perspectivas e soluções',
    excerpt:
        'Discussão sobre os principais desafios enfrentados pelas administrações municipais e possíveis caminhos de reforma.',
    authorName: 'Ana Paula',
    authorInitials: 'AP',
    category: TopicCategory.politica,
    timeAgo: 'Há 4h',
    comments: 12,
    likes: 27,
    avatarBg: Color(0xFF6366F1),
    avatarFg: Colors.white,
  ),
  ForumTopic(
    title: 'A independência de Angola: lições para as novas gerações',
    excerpt:
        'Reflexões sobre o processo histórico de independência e seu impacto no desenvolvimento nacional.',
    authorName: 'João Lima',
    authorInitials: 'JL',
    category: TopicCategory.historia,
    timeAgo: 'Há 6h',
    comments: 5,
    likes: 18,
    avatarBg: Color(0xFFFF8A00),
    avatarFg: Colors.white,
  ),
];

List<ForumComment> buildMockComments() => const [
  ForumComment(
    id: '1',
    authorName: 'Ana Paula',
    authorInitials: 'AP',
    avatarBg: Color(0xFF6366F1),
    avatarFg: Colors.white,
    text:
        'Excelente iniciativa, Carlos. Tenho dados de arquivos provinciais que indicam que no Huambo, a transição foi mais lenta devido à falta de agências bancárias operacionais na época.',
    timeAgo: '2h atrás',
    likes: 5,
    replies: [
      ForumComment(
        id: '1-1',
        authorName: 'João Silva',
        authorInitials: 'JS',
        avatarBg: Color(0xFF059669),
        avatarFg: Colors.white,
        text:
            '@Ana Paula Ana, conseguiria partilhar essas fontes? Estou a fazer uma tese sobre a rede bancária colonial vs pós-independência.',
        timeAgo: '1h atrás',
        likes: 2,
      ),
    ],
  ),
  ForumComment(
    id: '2',
    authorName: 'Rita Manuel',
    authorInitials: 'RM',
    avatarBg: Color(0xFF14B8A6),
    avatarFg: Colors.white,
    text:
        'Excelente questão. A questão da liquidez física é frequentemente negligenciada nestas análises macroeconómicas clássicas.',
    timeAgo: '45 min atrás',
    likes: 0,
  ),
  ForumComment(
    id: '3',
    authorName: 'Milton Jorge',
    authorInitials: 'MJ',
    avatarBg: Color(0xFF7B001C),
    avatarFg: Colors.white,
    text:
        'A institucionalização do Kwanza representou acima de tudo afirmação de soberania política. A nível económico, os mercados paralelos serviram de válvula de escape.',
    timeAgo: '30 min atrás',
    likes: 0,
  ),
];

const mockSubscriptions = [
  SubscriptionAuthor(
    initials: 'AS',
    name: 'Prof. Ana\nSilva',
    role: 'Historiadora',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
  SubscriptionAuthor(
    initials: 'MB',
    name: 'Prof. Manuel\nBento',
    role: 'Economista',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
  SubscriptionAuthor(
    initials: 'SM',
    name: 'Prof. Silva\nMaria',
    role: 'Docente',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
];

const mockRecent = [
  RecentPublication(
    authorInitials: 'AS',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
    publishedText: 'Prof. Ana Silva publicou:',
    title: 'A Evolução da Moeda em Luanda: Do Zimbo ao Kwanza Moderno',
    type: 'Artigo',
    duration: '8 min',
    timeAgo: 'Hoje',
  ),
  RecentPublication(
    authorInitials: 'BM',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
    publishedText: 'Dr. Manuel Bento publicou:',
    title: 'O Ciclo do Café e o Impacto no Comércio Regional (1950-1970)',
    type: 'Vídeo',
    duration: '12 min',
    timeAgo: 'Ontem',
  ),
  RecentPublication(
    authorInitials: 'BM',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
    publishedText: 'Dr. Manuel Bento publicou:',
    title: 'O Ciclo do Café e o Impacto no Comércio Regional (1950-1970)',
    type: 'Vídeo',
    duration: '12 min',
    timeAgo: 'Ontem',
  ),
];

const mockSuggested = [
  SubscriptionAuthor(
    initials: 'EM',
    name: 'Eduardo Mateus',
    role: 'Especialista em Macroeconomia',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
  SubscriptionAuthor(
    initials: 'EM',
    name: 'Eduardo Mateus',
    role: 'Especialista em Macroeconomia',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
  SubscriptionAuthor(
    initials: 'EM',
    name: 'Eduardo Mateus',
    role: 'Especialista em Macroeconomia',
    avatarBg: AppColors.winePill,
    avatarFg: AppColors.wine,
  ),
];
