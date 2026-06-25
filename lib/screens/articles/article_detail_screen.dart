import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../profile/public_creator_profile_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleDetail article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 54,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicCreatorProfileScreen(
                        name: article.author,
                        initials: article.authorInitials,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.winePill,
                        child: Text(
                          article.authorInitials,
                          style: const TextStyle(
                            color: AppColors.wine,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.author,
                            style: const TextStyle(
                              color: AppColors.wine,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            article.date,
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
                for (int i = 0; i < article.comments.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 24, color: AppColors.borderLight),
                  _CommentTile(comment: article.comments[i]),
                ],
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
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 270,
          child: article.imageUrl != null
              ? Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(),
                )
              : _fallback(),
        ),
        // bottom fade to white
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => Container(
    color: article.accent.withValues(alpha: .15),
    child: Center(
      child: Icon(article.icon, size: 64, color: article.accent.withValues(alpha: .5)),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.winePill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.wine,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
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

class _CommentTile extends StatefulWidget {
  final ArticleComment comment;

  const _CommentTile({required this.comment});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late int _likes;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.muted),
              title: const Text('Reportar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppColors.muted),
              title: const Text('Copiar texto'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.muted),
              title: const Text('Partilhar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: AppColors.muted),
              title: const Text('Bloquear utilizador'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const indent = 46.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.comment.avatarColor,
              child: Text(
                widget.comment.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.comment.author,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' • ${widget.comment.timeAgo}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: indent),
          child: Text(
            widget.comment.text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: indent - 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? AppColors.wine : AppColors.muted,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_likes',
                      style: TextStyle(
                        color: _liked ? AppColors.wine : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Responder',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showOptions,
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
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
  final String? imageUrl;
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
    this.imageUrl,
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
  final int likes;

  const ArticleComment({
    required this.author,
    required this.initials,
    required this.text,
    required this.timeAgo,
    required this.avatarColor,
    this.likes = 0,
  });
}

const featuredArticleDetails = [
  ArticleDetail(
    imageUrl:
        'https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?auto=format&fit=crop&w=900&q=80',
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
        likes: 7,
        text:
            'Excelente análise, professora. Seria interessante aprofundar o impacto das Fintechs atuais...',
      ),
      ArticleComment(
        author: 'Elena K.',
        initials: 'EK',
        timeAgo: '5h atrás',
        avatarColor: Color(0xFF8B4B1F),
        likes: 3,
        text:
            'Obrigada por partilhar estes dados históricos. Ajudou muito no meu trabalho académico!',
      ),
      ArticleComment(
        author: 'Manuel Pedro',
        initials: 'MP',
        timeAgo: '1d atrás',
        avatarColor: AppColors.wine,
        likes: 1,
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
        likes: 5,
        text:
            'A ligação entre moeda e soberania ficou muito clara neste texto.',
      ),
      ArticleComment(
        author: 'Elena K.',
        initials: 'EK',
        timeAgo: '4h atrás',
        avatarColor: Color(0xFF8B4B1F),
        likes: 2,
        text: 'Gostei da contextualização sobre o Zimbo e os mercados locais.',
      ),
    ],
  ),
];
