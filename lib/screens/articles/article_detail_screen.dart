import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../profile/public_creator_profile_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleDetail article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 44,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border,
              color: AppColors.wine,
              size: 18,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.wine,
              size: 20,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 78),
        children: [
          _HeroVisual(article: article),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(label: article.category.toUpperCase()),
                    const SizedBox(width: 10),
                    Text(
                      article.readTime,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicCreatorProfileScreen(
                              name: article.author,
                              initials: article.authorInitials,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.wine,
                            child: Text(
                              article.authorInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.author,
                            style: const TextStyle(
                              color: AppColors.textMain,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      article.date,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      color: AppColors.muted,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.likes}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.muted,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.commentCount} comentários',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 26, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...article.paragraphs.take(3).map((text) => _Paragraph(text)),
                _QuoteCard(text: article.quote),
                ...article.paragraphs.skip(3).map((text) => _Paragraph(text)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.wine,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(double.infinity, 34),
                  ),
                  child: const Text(
                    'Continuar lendo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Comentários (${article.commentCount})',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...article.comments
                    .take(2)
                    .map((comment) => _CommentTile(comment: comment)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.wine,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(double.infinity, 32),
                  ),
                  child: const Text(
                    'Ver todos os comentários',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _CommentComposer(),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final ArticleDetail article;

  const _HeroVisual({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: article.accent.withValues(alpha: .18),
      child: Stack(
        children: [
          Positioned(
            left: -18,
            bottom: -34,
            child: Icon(
              Icons.account_balance,
              size: 160,
              color: Colors.white.withValues(alpha: .48),
            ),
          ),
          Positioned(
            right: -18,
            top: 18,
            child: Icon(
              Icons.trending_up,
              size: 96,
              color: Colors.white.withValues(alpha: .38),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(article.icon, color: article.accent, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: AppColors.wine),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.58,
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String text;

  const _QuoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFBEEF3),
        border: Border(left: BorderSide(color: AppColors.wine, width: 3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
          height: 1.55,
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final ArticleComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: comment.avatarColor,
            child: Text(
              comment.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'Adicionar comentário...',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              height: 38,
              child: IconButton.filled(
                onPressed: () {},
                style: IconButton.styleFrom(backgroundColor: AppColors.wine),
                icon: const Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleDetail {
  final String category;
  final String readTime;
  final String title;
  final String author;
  final String authorInitials;
  final String date;
  final int likes;
  final int commentCount;
  final Color accent;
  final IconData icon;
  final String quote;
  final List<String> paragraphs;
  final List<ArticleComment> comments;

  const ArticleDetail({
    required this.category,
    required this.readTime,
    required this.title,
    required this.author,
    required this.authorInitials,
    required this.date,
    required this.likes,
    required this.commentCount,
    required this.accent,
    required this.icon,
    required this.quote,
    required this.paragraphs,
    required this.comments,
  });
}

class ArticleComment {
  final String author;
  final String initials;
  final String text;
  final String timeAgo;
  final Color avatarColor;

  const ArticleComment({
    required this.author,
    required this.initials,
    required this.text,
    required this.timeAgo,
    required this.avatarColor,
  });
}

const featuredArticleDetails = [
  ArticleDetail(
    category: 'Economia',
    readTime: '8 min leitura',
    title:
        'A Evolução do Sistema Bancário em Angola: Do Período Colonial à Atualidade',
    author: 'Prof. Ana Silva',
    authorInitials: 'AS',
    date: '12 Abr 2026',
    likes: 12,
    commentCount: 8,
    accent: AppColors.wine,
    icon: Icons.article,
    quote:
        '"A resiliência das instituições financeiras angolanas reside na sua capacidade de se adaptarem aos ciclos do petróleo, mantendo a soberania monetária em tempos de incerteza."',
    paragraphs: [
      'O percurso da banca angolana é um espelho das profundas transformações políticas e sociais que o país atravessou ao longo das últimas décadas.',
      'Desde a fundação das primeiras instituições de crédito no período colonial, o sector financeiro serviu como motor de estruturação económica.',
      'Banco Nacional de Angola a assumir papéis multifacetados que hoje seriam impensáveis numa economia de mercado moderna.',
      'A transição para o multipartidarismo e a liberalização económica nos anos 90 trouxeram o surgimento de novos players privados, redesenhando o panorama competitivo e fomentando a inclusão financeira nas províncias mais remotas...',
    ],
    comments: [
      ArticleComment(
        author: 'Ricardo Mendonça',
        initials: 'RM',
        timeAgo: '2h atrás',
        avatarColor: Color(0xFF2F536B),
        text:
            'Excelente análise, professora. Seria interessante aprofundar o impacto das Fintechs atuais...',
      ),
      ArticleComment(
        author: 'Elena K.',
        initials: 'EK',
        timeAgo: '5h atrás',
        avatarColor: Color(0xFF8B4B1F),
        text:
            'Obrigada por partilhar estes dados históricos. Ajudou muito no meu trabalho académico!',
      ),
      ArticleComment(
        author: 'Manuel Pedro',
        initials: 'MP',
        timeAgo: '1d atrás',
        avatarColor: AppColors.wine,
        text:
            'O enquadramento colonial ajuda a compreender muitas das limitações actuais.',
      ),
    ],
  ),
  ArticleDetail(
    category: 'Economia',
    readTime: '6 min leitura',
    title: 'A Evolução da Moeda: do Zimbo ao Kwanza Moderno',
    author: 'Dr. Manuel Bento',
    authorInitials: 'MB',
    date: '09 Abr 2026',
    likes: 28,
    commentCount: 6,
    accent: AppColors.green,
    icon: Icons.account_balance,
    quote:
        '"A moeda angolana revela a memória económica do território, das trocas locais à construção de soberania."',
    paragraphs: [
      'A história monetária de Angola atravessa formas tradicionais de troca, circuitos coloniais e reformas que marcaram a independência.',
      'O Zimbo teve papel simbólico e prático em mercados costeiros, muito antes da consolidação de moedas emitidas pelo Estado.',
      'Com o Kwanza, Angola procurou criar uma referência monetária própria e reorganizar a confiança económica nacional.',
      'As reformas posteriores continuaram a responder aos desafios da inflação, da estabilidade cambial e da modernização bancária...',
    ],
    comments: [
      ArticleComment(
        author: 'Ricardo Mendonça',
        initials: 'RM',
        timeAgo: '1h atrás',
        avatarColor: Color(0xFF2F536B),
        text:
            'A ligação entre moeda e soberania ficou muito clara neste texto.',
      ),
      ArticleComment(
        author: 'Elena K.',
        initials: 'EK',
        timeAgo: '4h atrás',
        avatarColor: Color(0xFF8B4B1F),
        text: 'Gostei da contextualização sobre o Zimbo e os mercados locais.',
      ),
    ],
  ),
];
