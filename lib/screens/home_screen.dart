import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';
import '../core/favorites.dart';
import '../core/models.dart';
import '../widgets/category_card.dart';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      placeholder: 'Search components or sizes',
                      style: const TextStyle(color: CupertinoColors.white),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C2C2E)),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.shield, color: Color(0xFF30D158), size: 12),
                        SizedBox(width: 5),
                        Text('ASME / MSS Reference Suite', style: TextStyle(fontSize: 10, color: Color(0xFF30D158), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!searching) _buildFavoritesSliver(),
          if (searching)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => CategoryCard(meta: results[i], onTap: () => _open(results[i])),
                  childCount: results.length,
                ),
              ),
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
            padding: const EdgeInsets.fromLTRB(18, 6, 0, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.star_fill, color: Color(0xFFFFD60A), size: 13),
                    SizedBox(width: 6),
                    Text(
                      'FAVORITES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
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
                            color: meta.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: meta.color.withOpacity(0.35)),
                          ),
                          child: Text(
                            '$nps ${meta.label}',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: meta.color),
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

  List<Widget> _buildGroupedSlivers() {
    final List<Widget> slivers = [];
    for (final group in CategoryRegistry.groups) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 16, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(color: group.color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                group.title.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.6),
              ),
            ],
          ),
        ),
      ));
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => CategoryCard(meta: group.items[i], onTap: () => _open(group.items[i])),
            childCount: group.items.length,
          ),
        ),
      ));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return slivers;
  }
}
