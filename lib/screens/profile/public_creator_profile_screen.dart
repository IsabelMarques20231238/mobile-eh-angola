import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../articles/article_detail_screen.dart';
import '../../routes/app_routes.dart';

class PublicCreatorProfileScreen extends StatefulWidget {
  final String name;
  final String initials;
  final String role;
  final String institution;

  const PublicCreatorProfileScreen({
    super.key,
    this.name = 'Prof. Ana Silva',
    this.initials = 'PA',
    this.role = 'Prof.',
    this.institution = 'ISPTEC',
  });

  @override
  State<PublicCreatorProfileScreen> createState() =>
      _PublicCreatorProfileScreenState();
}

class _PublicCreatorProfileScreenState extends State<PublicCreatorProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _following = false;
  bool _bioExpanded = false;

  static const _tags = ['ECONOMIA', 'HISTÓRIA', 'DCSA'];

  static const _articles = [
    _ProfileArticle(
      featured: true,
      timeAgo: 'Há 2 dias',
      category: '',
      title: 'O Impacto do Café na Economia Colonial de...',
      excerpt:
          'Uma análise profunda sobre os fluxos comerciais entre Luanda e...',
      imageColor: Color(0xFF5C3D2E),
      icon: Icons.coffee,
    ),
    _ProfileArticle(
      category: 'HISTÓRIA ECONÓMICA',
      title: 'Caminhos de Ferro: De Benguela ao Moxico',
      excerpt:
          'Como a infraestrutura ferroviária moldou o PIB das províncias...',
      imageColor: Color(0xFF8B7355),
      icon: Icons.train,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.card,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textMain, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.textMain, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textMain, size: 20),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileBanner(
                  initials: widget.initials,
                  following: _following,
                  onFollowTap: () => setState(() => _following = !_following),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 36),
                      _NameRow(name: widget.name),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.role} · ${widget.institution}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BioBlock(
                        expanded: _bioExpanded,
                        onToggle: () =>
                            setState(() => _bioExpanded = !_bioExpanded),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map((t) => _InterestTag(label: t))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      const _StatsRow(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.wine,
                unselectedLabelColor: AppColors.textMain,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                indicatorColor: AppColors.wine,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.borderLight,
                tabs: const [
                  Tab(text: 'Conteúdo'),
                  Tab(text: 'Quiz'),
                  Tab(text: 'Fórum'),
                  Tab(text: 'Sobre'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ConteudoTab(
              articles: _articles,
              following: _following,
              onFollowProfile: () => setState(() => _following = true),
            ),
            const _PlaceholderTab(
              icon: Icons.quiz_outlined,
              message: 'Quizzes publicados por este criador.',
            ),
            const _PlaceholderTab(
              icon: Icons.forum_outlined,
              message: 'Tópicos e debates do fórum.',
            ),
            const _SobreTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  final String initials;
  final bool following;
  final VoidCallback onFollowTap;

  const _ProfileBanner({
    required this.initials,
    required this.following,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 118,
          width: double.infinity,
          child: CustomPaint(painter: _BannerPatternPainter()),
        ),
        Positioned(
          left: 16,
          bottom: -28,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.card, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 8,
          child: Material(
            color: following ? AppColors.winePill : AppColors.wine,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onFollowTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Text(
                  following ? 'A seguir' : 'Seguir',
                  style: TextStyle(
                    color: following ? AppColors.wine : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFFDF0F5);
    canvas.drawRect(Offset.zero & size, bg);

    final stripe = Paint()
      ..color = const Color(0xFFF5D6E2).withValues(alpha: .55)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stripe);
    }

    final wave = Paint()
      ..color = const Color(0xFFEAB6C8).withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    path.moveTo(0, size.height * .72);
    path.quadraticBezierTo(
      size.width * .25,
      size.height * .55,
      size.width * .5,
      size.height * .68,
    );
    path.quadraticBezierTo(
      size.width * .78,
      size.height * .82,
      size.width,
      size.height * .58,
    );
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NameRow extends StatelessWidget {
  final String name;
  const _NameRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 13),
        ),
      ],
    );
  }
}

class _BioBlock extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _BioBlock({required this.expanded, required this.onToggle});

  static const _fullBio =
      'Especialista em Macroeconomia e História Económica de Angola. '
      'Investigadora focada no desenvolvimento sustentável da DCSA.';

  @override
  Widget build(BuildContext context) {
    const preview =
        'Especialista em Macroeconomia e História Económica de Angola. '
        'Investigadora focada no desenvolvimento sustentável da DCSA.';
    final text = expanded ? _fullBio : preview;

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: text),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                expanded ? ' Ver menos' : ' Ver mais',
                style: const TextStyle(
                  color: AppColors.wine,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  const _InterestTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.winePill,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: const Row(
        children: [
          Expanded(child: _StatCell(value: '32', label: 'Artigos')),
          _StatDivider(),
          Expanded(child: _StatCell(value: '248', label: 'Seguidores')),
          _StatDivider(),
          Expanded(
            child: _StatCell(value: '4.8 ★', label: 'Avaliação'),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.borderLight,
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.wine,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.card,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ConteudoTab extends StatelessWidget {
  final List<_ProfileArticle> articles;
  final bool following;
  final VoidCallback onFollowProfile;

  const _ConteudoTab({
    required this.articles,
    required this.following,
    required this.onFollowProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        ...articles.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ArticleRowCard(
              article: a,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(
                      article: featuredArticleDetails.first,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const _JindungoAccessCard(),
        const SizedBox(height: 20),
        const _SectionHeading(
          title: 'Quizzes Populares',
          trailing: '14 publicados',
        ),
        const SizedBox(height: 12),
        _PopularQuizCard(
          onPlay: () => Navigator.pushNamed(context, AppRoutes.quizList),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppColors.borderLight, height: 1),
        const SizedBox(height: 14),
        _ProfileFooter(
          following: following,
          onFollowProfile: onFollowProfile,
        ),
      ],
    );
  }
}

class _ArticleRowCard extends StatelessWidget {
  final _ProfileArticle article;
  final VoidCallback onTap;

  const _ArticleRowCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.featured)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.wine,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'DESTAQUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.timeAgo ?? '',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else if (article.category.isNotEmpty)
                      Text(
                        article.category,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                    SizedBox(height: article.featured ? 8 : 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ArticleThumb(
                color: article.imageColor,
                icon: article.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleThumb extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ArticleThumb({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: .75), color],
          ),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: .9), size: 32),
      ),
    );
  }
}

class _JindungoAccessCard extends StatelessWidget {
  const _JindungoAccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.wine, width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            top: -8,
            child: Icon(
              Icons.local_fire_department,
              size: 72,
              color: AppColors.winePill.withValues(alpha: .65),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF7A45),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Textos com Jindungo',
                    style: TextStyle(
                      color: AppColors.wine,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesso exclusivo a análises sem filtros sobre as flutuações cambiais e o mercado informal.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    showAppToast(context, 'Pedido de acesso enviado', type: AppToastType.success);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Solicitar acesso',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeading({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PopularQuizCard extends StatelessWidget {
  final VoidCallback onPlay;

  const _PopularQuizCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.wine, width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.crop_square,
                  size: 22,
                  color: AppColors.wine.withValues(alpha: .35),
                ),
                Transform.translate(
                  offset: const Offset(4, -4),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.wine,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moedas de Angola: Do Kwanza ao Lwei',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '10 Perguntas • 5 min',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.wine,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlay,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  final bool following;
  final VoidCallback onFollowProfile;

  const _ProfileFooter({
    required this.following,
    required this.onFollowProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.wine,
            side: const BorderSide(color: AppColors.wine, width: 1.5),
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.chat_bubble, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: following ? null : onFollowProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.winePill,
                disabledForegroundColor: AppColors.wine,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                following ? 'A seguir' : 'Seguir Perfil',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SobreTab extends StatelessWidget {
  const _SobreTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Sobre',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Professora e investigadora no ISPTEC, com foco em macroeconomia, história económica de Angola e políticas de desenvolvimento na DCSA.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20),
        _SobreInfoRow(label: 'Instituição', value: 'ISPTEC'),
        _SobreInfoRow(label: 'Departamento', value: 'DCSA — Economia'),
        _SobreInfoRow(label: 'Membro desde', value: 'Março 2024'),
        _SobreInfoRow(label: 'Idioma', value: 'Português'),
      ],
    );
  }
}

class _SobreInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SobreInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PlaceholderTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.winePill),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileArticle {
  final bool featured;
  final String? timeAgo;
  final String category;
  final String title;
  final String excerpt;
  final Color imageColor;
  final IconData icon;

  const _ProfileArticle({
    this.featured = false,
    this.timeAgo,
    this.category = '',
    required this.title,
    required this.excerpt,
    required this.imageColor,
    required this.icon,
  });
}
