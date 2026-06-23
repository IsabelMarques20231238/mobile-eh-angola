import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../articles/article_detail_screen.dart';
import '../podcast/podcast_detail_screen.dart';
import '../video/video_detail_screen.dart';
import 'saved_item_models.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  SavedItemFilter _filter = SavedItemFilter.all;
  late List<SavedItem> _items;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _items = List.of(SavedItemData.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<SavedItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (!savedItemMatchesFilter(item, _filter)) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.author.toLowerCase().contains(query);
    }).toList();
  }

  void _removeItem(SavedItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removido dos guardados')),
    );
  }

  void _openItem(SavedItem item) {
    switch (item.type) {
      case SavedItemType.article:
        final index = item.articleDetailIndex ?? 0;
        final article = featuredArticleDetails[index % featuredArticleDetails.length];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      case SavedItemType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VideoDetailScreen(video: featuredVideo),
          ),
        );
      case SavedItemType.podcast:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PodcastDetailScreen(episode: featuredPodcast),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SavedHeader(
                    onSearchTap: () {
                      setState(() => _showSearch = !_showSearch);
                      if (_showSearch) _searchFocus.requestFocus();
                    },
                  ),
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar itens guardados...',
                          hintStyle: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.wine),
                          ),
                        ),
                      ),
                    ),
                  _FilterChips(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptySavedItems(),
              )
            else if (_filter == SavedItemFilter.all)
              ..._buildGroupedSlivers(filtered)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _SavedItemTile(
                      item: item,
                      onTap: () => _openItem(item),
                      onRemove: () => _removeItem(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavMock(index: 4),
    );
  }

  List<Widget> _buildGroupedSlivers(List<SavedItem> filtered) {
    final slivers = <Widget>[];
    for (final type in SavedItemType.values) {
      final sectionItems =
          filtered.where((item) => item.type == type).toList();
      if (sectionItems.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: sectionTitleForType(type),
            onSeeAll: () => setState(
              () => _filter = filterForType(type) ?? SavedItemFilter.all,
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          sliver: SliverList.separated(
            itemCount: sectionItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final item = sectionItems[index];
              return _SavedItemTile(
                item: item,
                onTap: () => _openItem(item),
                onRemove: () => _removeItem(item),
              );
            },
          ),
        ),
      );
    }
    return slivers;
  }
}

class _SavedHeader extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _SavedHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.wine, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Itens Guardados',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.wine, size: 24),
            onPressed: onSearchTap,
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final SavedItemFilter selected;
  final ValueChanged<SavedItemFilter> onSelected;

  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final filter in SavedItemFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != SavedItemFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.wine : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.wine : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'Ver todos',
              style: TextStyle(
                color: AppColors.wine,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  final SavedItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedItemTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  static const _offlineGreen = Color(0xFFE8F7EF);
  static const _offlineGreenText = Color(0xFF15945B);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.savedAgo,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.bookmarks,
              color: AppColors.wine,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final SavedItem item;

  const _Thumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 72,
                height: 72,
                color: AppColors.wineBg,
                child: Icon(
                  _iconForType(item.type),
                  color: AppColors.wine.withValues(alpha: .5),
                ),
              ),
            ),
          ),
          if (item.offline)
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _SavedItemTile._offlineGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: _SavedItemTile._offlineGreenText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          if (item.type == SavedItemType.video)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          if (item.type == SavedItemType.podcast)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.withValues(alpha: .15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.podcasts,
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

  IconData _iconForType(SavedItemType type) => switch (type) {
    SavedItemType.article => Icons.article_outlined,
    SavedItemType.video => Icons.play_circle_outline,
    SavedItemType.podcast => Icons.podcasts,
  };
}

class _EmptySavedItems extends StatelessWidget {
  const _EmptySavedItems();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Nenhum item guardado encontrado',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
