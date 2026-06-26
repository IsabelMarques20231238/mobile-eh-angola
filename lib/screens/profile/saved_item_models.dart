enum SavedItemType { article, video, podcast }

enum SavedItemFilter { all, forum, articles, videos, podcasts }

extension SavedItemFilterLabel on SavedItemFilter {
  String get label => switch (this) {
    SavedItemFilter.all => 'Todos',
    SavedItemFilter.forum => 'Fórum',
    SavedItemFilter.articles => 'Artigos',
    SavedItemFilter.videos => 'Vídeos',
    SavedItemFilter.podcasts => 'Podcasts',
  };
}

class SavedItem {
  final String id;
  final SavedItemType type;
  final String title;
  final String duration;
  final String author;
  final String savedAgo;
  final bool offline;
  final String imageUrl;
  final int? articleDetailIndex;

  const SavedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.duration,
    required this.author,
    required this.savedAgo,
    this.offline = false,
    required this.imageUrl,
    this.articleDetailIndex,
  });

  String get meta => '$duration • $author';
}

class SavedItemData {
  static const totalCount = 32;

  static const List<SavedItem> items = [
    SavedItem(
      id: 'a1',
      type: SavedItemType.article,
      title: 'A Evolução da Moeda em Angola: Do Zimbo ao Kwanza',
      duration: '8 min',
      author: 'Prof. Ana Silva',
      savedAgo: 'Guardado há 2 dias',
      offline: true,
      imageUrl:
          'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=200&h=200&fit=crop',
      articleDetailIndex: 1,
    ),
    SavedItem(
      id: 'a2',
      type: SavedItemType.article,
      title: 'Comércio Transatlântico e o Impacto na Economia Local',
      duration: '12 min',
      author: 'Dr. Carlos Bento',
      savedAgo: 'Guardado há 3 dias',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=200&h=200&fit=crop',
      articleDetailIndex: 0,
    ),
    SavedItem(
      id: 'a3',
      type: SavedItemType.article,
      title: 'Industrialização Pós-Independência: Desafios e Oportunidades',
      duration: '15 min',
      author: 'Prof. Ana Silva',
      savedAgo: 'Guardado há 5 dias',
      offline: true,
      imageUrl:
          'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=200&h=200&fit=crop',
      articleDetailIndex: 0,
    ),
    SavedItem(
      id: 'a4',
      type: SavedItemType.article,
      title: 'O Kwanza Colonial e a Transição Monetária',
      duration: '10 min',
      author: 'Dr. Manuel Bento',
      savedAgo: 'Guardado há 1 semana',
      imageUrl:
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=200&h=200&fit=crop',
      articleDetailIndex: 1,
    ),
    SavedItem(
      id: 'v1',
      type: SavedItemType.video,
      title: 'O Ciclo do Café e a Riqueza de Angola',
      duration: '24:15',
      author: 'Prof. Carlos Manuel',
      savedAgo: 'Guardado há 1 dia',
      imageUrl:
          'https://images.unsplash.com/photo-1511379935019-47ba7259eef0?w=200&h=200&fit=crop',
    ),
    SavedItem(
      id: 'v2',
      type: SavedItemType.video,
      title: 'Mercados Tradicionais: O Pulso da Economia',
      duration: '18:40',
      author: 'Equipa EH',
      savedAgo: 'Guardado há 4 dias',
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=200&h=200&fit=crop',
    ),
    SavedItem(
      id: 'p1',
      type: SavedItemType.podcast,
      title: 'Economia em Foco: Ep. 45',
      duration: '32 min',
      author: 'Análise do Orçamento Geral do Estado',
      savedAgo: 'Guardado ontem',
      imageUrl:
          'https://images.unsplash.com/photo-1478737273439-47f3ceecc1c2?w=200&h=200&fit=crop',
    ),
    SavedItem(
      id: 'p2',
      type: SavedItemType.podcast,
      title: 'Mulheres nos negócios angolanos',
      duration: '22 min',
      author: 'Prof. Ana Silva',
      savedAgo: 'Guardado há 6 dias',
      imageUrl:
          'https://images.unsplash.com/photo-1590602847861-f357a9335301?w=200&h=200&fit=crop',
    ),
  ];
}

bool savedItemMatchesFilter(SavedItem item, SavedItemFilter filter) {
  return switch (filter) {
    SavedItemFilter.all => true,
    SavedItemFilter.forum => false, // tópicos de fórum são geridos separadamente
    SavedItemFilter.articles => item.type == SavedItemType.article,
    SavedItemFilter.videos => item.type == SavedItemType.video,
    SavedItemFilter.podcasts => item.type == SavedItemType.podcast,
  };
}

SavedItemFilter? filterForType(SavedItemType type) => switch (type) {
  SavedItemType.article => SavedItemFilter.articles,
  SavedItemType.video => SavedItemFilter.videos,
  SavedItemType.podcast => SavedItemFilter.podcasts,
};

String sectionTitleForType(SavedItemType type) => switch (type) {
  SavedItemType.article => 'Artigos',
  SavedItemType.video => 'Vídeos',
  SavedItemType.podcast => 'Podcasts',
};
