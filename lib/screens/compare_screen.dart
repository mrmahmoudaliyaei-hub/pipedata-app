import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';
import '../core/dimension_builder.dart';
import '../core/models.dart';
import '../core/units.dart';

/// Lets the user pick a second size/class within the same category and
/// see both sets of Dimensions at once — e.g. "4" Sch 40 vs 4" Sch 80 (XS)"
/// or "2" Class 150 vs 2" Class 300" flange.
class CompareScreen extends StatefulWidget {
  final ComponentCategory category;
  final int initialIndexA;
  final String initialSubSelectionA;
  final String initialValveType;

  const CompareScreen({
    super.key,
    required this.category,
    required this.initialIndexA,
    required this.initialSubSelectionA,
    this.initialValveType = 'Gate Valve',
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareItemState {
  int index;
  String subSelection;
  String valveType;
  _CompareItemState({required this.index, required this.subSelection, this.valveType = 'Gate Valve'});
}

class _CompareScreenState extends State<CompareScreen> {
  late final CategoryMeta _meta = CategoryRegistry.of(widget.category);
  late final List<Map<String, dynamic>> _dataset = _meta.dataset();
  static const List<String> _valveTypes = ['Gate Valve', 'Globe Valve', 'Ball Valve', 'Swing Check Valve'];

  late final _CompareItemState _a = _CompareItemState(
    index: widget.initialIndexA,
    subSelection: widget.initialSubSelectionA,
    valveType: widget.initialValveType,
  );
  // B starts one size up from A (wrapping), so the two cards differ by default.
  late final _CompareItemState _b = _CompareItemState(
    index: (widget.initialIndexA + 1) % _dataset.length,
    subSelection: widget.initialSubSelectionA,
    valveType: widget.initialValveType,
  );

  List<String> _subOptions(Map<String, dynamic> item, String valveType) {
    switch (_meta.subOptionKind) {
      case SubOptionKind.schedules:
        return (item['schedules'] as Map<String, dynamic>).keys.toList();
      case SubOptionKind.classes:
        return _meta.category == ComponentCategory.valve
            ? ((item['types'] as Map<String, dynamic>)[valveType] as Map<String, dynamic>).keys.toList()
            : (item['classes'] as Map<String, dynamic>).keys.toList();
      case SubOptionKind.lengths:
        return (item['lengths'] as Map<String, dynamic>).keys.toList();
      case SubOptionKind.angles:
        return (item['angles'] as Map<String, dynamic>).keys.toList();
      case SubOptionKind.none:
        return const [];
    }
  }

  void _syncSub(_CompareItemState s) {
    final item = _dataset[s.index];
    final opts = _subOptions(item, s.valveType);
    if (opts.isNotEmpty && !opts.contains(s.subSelection)) s.subSelection = opts.first;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LengthUnit>(
      valueListenable: unitsController,
      builder: (context, _, __) => CupertinoPageScaffold(
        backgroundColor: const Color(0xFF000000),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: const Color(0xF0161618),
          middle: Text('Compare — ${_meta.label}'),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _buildSection('A', _a, const Color(0xFF0A84FF)),
              const SizedBox(height: 18),
              _buildSection('B', _b, const Color(0xFF5FD1E8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, _CompareItemState s, Color accent) {
    final item = _dataset[s.index];
    final opts = _subOptions(item, s.valveType);
    final rows = buildDimensionRows(
      category: _meta.category,
      item: item,
      subSelection: s.subSelection,
      valveType: s.valveType,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
            ),
            const SizedBox(width: 8),
            Text('Item $label', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CupertinoColors.white)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dataset.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final isSel = s.index == i;
              return GestureDetector(
                onTap: () => setState(() {
                  s.index = i;
                  _syncSub(s);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? accent : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_dataset[i]['nps']}',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isSel ? CupertinoColors.black : CupertinoColors.white),
                  ),
                ),
              );
            },
          ),
        ),
        if (_meta.category == ComponentCategory.valve) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _valveTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final t = _valveTypes[i];
                final isSel = s.valveType == t;
                return GestureDetector(
                  onTap: () => setState(() {
                    s.valveType = t;
                    _syncSub(s);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? accent.withOpacity(0.2) : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: isSel ? accent : const Color(0xFF2C2C2E)),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
                  ),
                );
              },
            ),
          ),
        ],
        if (opts.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: opts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final isSel = s.subSelection == opts[i];
                return GestureDetector(
                  onTap: () => setState(() => s.subSelection = opts[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? accent : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(opts[i], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.black : const Color(0xFF8E8E93))),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161618),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Column(
            children: rows.entries
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF242426), width: 0.6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E8E93)))),
                          const SizedBox(width: 8),
                          Text(e.value, style: const TextStyle(fontSize: 12, color: CupertinoColors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
