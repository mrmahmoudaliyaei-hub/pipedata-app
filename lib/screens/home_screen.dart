import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';
import '../core/favorites.dart';
import '../core/models.dart';
import '../widgets/category_row.dart';
import 'category_detail_screen.dart';
import 'pipeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  void _open(CategoryMeta meta, {int sizeIdx = 0, String? subSelection, String valveType = 'Gate Valve'}) {
    if (meta.category == ComponentCategory.pipelineTransport) {
      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PipelineScreen()));
    } else {
      Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: meta.category,
          initialSizeIdx: sizeIdx,
          initialSubSelection: subSelection,
          initialValveType: valveType,
        ),
      ));
    }
  }

  void _openFavorite(FavoriteEntry entry) {
    _open(
      CategoryRegistry.of(entry.category),
      sizeIdx: entry.index,
      subSelection: entry.subSelection,
      valveType: entry.valveType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.trim().isNotEmpty;
    final List<CategoryMeta> results = searching ? CategoryRegistry.search(_query) : [];

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(
            backgroundColor: Color(0xFF000000),
            border: null,
            largeTitle: Text('Piping Data Pro'),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'ASME and MSS dimensional reference for industrial piping',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: CupertinoSearchTextField(
                placeholder: 'Search components or sizes',
                style: const TextStyle(color: CupertinoColors.white),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          if (!searching) _buildFavoritesSliver(),
          if (searching)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverToBoxAdapter(child: _buildGroupCard(results)),
            )
          else
            ..._buildGroupedSlivers(),
        ],
      ),
    );
  }

  Widget _buildFavoritesSliver() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: favoritesController,
        builder: (context, _) {
          final entries = favoritesController.entries;
          if (entries.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 0, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Favorites', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFAEAEB2))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final meta = CategoryRegistry.of(entry.category);
                      final dataset = meta.dataset();
                      final nps = entry.index < dataset.length ? dataset[entry.index]['nps'] as String : '?';
                      return GestureDetector(
                        onTap: () => _openFavorite(entry),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161618),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0xFF232326)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.star_fill, size: 10, color: meta.color),
                              const SizedBox(width: 6),
                              Text('$nps ${meta.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One shared rounded container holding every row in [items], with a
  /// hairline divider between rows and none after the last — the grouped
  /// list-section look used throughout the rest of this pass, instead of
  /// a grid of individually-shadowed cards.
  Widget _buildGroupCard(List<CategoryMeta> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232326), width: 0.6),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            CategoryRow(meta: items[i], onTap: () => _open(items[i]), showDivider: i < items.length - 1),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSlivers() {
    final List<Widget> slivers = [];
    for (final group in CategoryRegistry.groups) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(group.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFAEAEB2))),
        ),
      ));
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(child: _buildGroupCard(group.items)),
      ));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return slivers;
  }
}

