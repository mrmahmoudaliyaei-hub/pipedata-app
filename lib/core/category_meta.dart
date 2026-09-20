import 'package:flutter/cupertino.dart';
import 'models.dart';

enum SubOptionKind { none, schedules, classes, lengths, angles }

/// Central registry describing how each ComponentCategory should be
/// presented in the UI: label, icon, accent color, grouping, governing
/// standard, and which map key (if any) holds its selectable sub-options.
class CategoryMeta {
  final ComponentCategory category;
  final String label;
  final String standard;
  final IconData icon;
  final Color color;
  final SubOptionKind subOptionKind;
  final List<Map<String, dynamic>> Function() dataset;

  const CategoryMeta({
    required this.category,
    required this.label,
    required this.standard,
    required this.icon,
    required this.color,
    required this.subOptionKind,
    required this.dataset,
  });
}

class CategoryGroup {
  final String title;
  final Color color;
  final List<CategoryMeta> items;
  const CategoryGroup(this.title, this.color, this.items);
}

class CategoryRegistry {
  static final Map<ComponentCategory, CategoryMeta> _byCategory = {
    for (final m in _all) m.category: m,
  };

  static CategoryMeta of(ComponentCategory c) => _byCategory[c]!;

  // Apple system-palette accents, one per category, chosen so every card on
  // the home screen reads as a distinct, intentional "brand" rather than a
  // single repeated blue tint.
  static const _blue = Color(0xFF0A84FF);
  static const _teal = Color(0xFF64D2FF);
  static const _indigo = Color(0xFF5E5CE6);
  static const _mint = Color(0xFF63E6E2);
  static const _orange = Color(0xFFFF9F0A);
  static const _purple = Color(0xFFBF5AF2);
  static const _pink = Color(0xFFFF375F);
  static const _red = Color(0xFFFF453A);
  static const _yellow = Color(0xFFFFD60A);
  static const _cyan = Color(0xFF6AC4DC);
  static const _green = Color(0xFF30D158);
  static const _skyBlue = Color(0xFF409CFF);
  // Distinct from _red (Valves) — Pipeline (Transport) used to share _red,
  // which broke the "one accent per category" rule; this is its own accent.
  static const _crimson = Color(0xFFFF6482);

  static final List<CategoryMeta> _all = [
    CategoryMeta(
      category: ComponentCategory.pipe,
      label: 'Pipes',
      standard: 'ASME B36.10M',
      icon: CupertinoIcons.smallcircle_circle,
      color: _blue,
      subOptionKind: SubOptionKind.schedules,
      dataset: () => PipingMasterCatalog.pipes,
    ),
    CategoryMeta(
      category: ComponentCategory.elbow,
      label: 'Elbows',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.compass,
      color: _teal,
      subOptionKind: SubOptionKind.angles,
      dataset: () => PipingMasterCatalog.elbows,
    ),
    CategoryMeta(
      category: ComponentCategory.tee,
      label: 'Tees',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.grid,
      color: _indigo,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.tees,
    ),
    CategoryMeta(
      category: ComponentCategory.cap,
      label: 'Caps',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.checkmark_seal,
      color: _mint,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.caps,
    ),
    CategoryMeta(
      category: ComponentCategory.reducer,
      label: 'Reducers',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.resize,
      color: _orange,
      subOptionKind: SubOptionKind.lengths,
      dataset: () => PipingMasterCatalog.reducers,
    ),
    CategoryMeta(
      category: ComponentCategory.flange,
      label: 'Flanges',
      standard: 'ASME B16.5',
      icon: CupertinoIcons.circle_filled,
      color: _purple,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.flanges,
    ),
    CategoryMeta(
      category: ComponentCategory.gasket,
      label: 'Gaskets',
      standard: 'ASME B16.20',
      icon: CupertinoIcons.layers_fill,
      color: _pink,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.gaskets,
    ),
    CategoryMeta(
      category: ComponentCategory.valve,
      label: 'Valves',
      standard: 'ASME B16.10',
      icon: CupertinoIcons.gauge,
      color: _red,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.valves,
    ),
    CategoryMeta(
      category: ComponentCategory.socketWeld,
      label: 'Socket-Weld',
      standard: 'ASME B16.11',
      icon: CupertinoIcons.gear_alt,
      color: _yellow,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.socketWelds,
    ),
    CategoryMeta(
      category: ComponentCategory.weldolet,
      label: 'Weldolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.hammer,
      color: _cyan,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.weldolets,
    ),
    CategoryMeta(
      category: ComponentCategory.sockolet,
      label: 'Sockolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.wrench,
      color: _green,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.sockolets,
    ),
    CategoryMeta(
      category: ComponentCategory.threadolet,
      label: 'Threadolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.square,
      color: _skyBlue,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.threadolets,
    ),
    CategoryMeta(
      category: ComponentCategory.pipelineTransport,
      label: 'Pipeline (Transport)',
      standard: 'ASME B31.4',
      icon: CupertinoIcons.drop,
      color: _crimson,
      subOptionKind: SubOptionKind.schedules,
      dataset: () => PipingMasterCatalog.pipes,
    ),
  ];

  static final List<CategoryGroup> groups = [
    CategoryGroup('Pipes & Fittings', _blue, [
      of(ComponentCategory.pipe),
      of(ComponentCategory.elbow),
      of(ComponentCategory.tee),
      of(ComponentCategory.cap),
      of(ComponentCategory.reducer),
    ]),
    CategoryGroup('Flanged Components', _purple, [
      of(ComponentCategory.flange),
      of(ComponentCategory.gasket),
      of(ComponentCategory.valve),
    ]),
    CategoryGroup('Small-Bore Connections', _yellow, [
      of(ComponentCategory.socketWeld),
    ]),
    CategoryGroup('Branch Outlets (MSS SP-97)', _cyan, [
      of(ComponentCategory.weldolet),
      of(ComponentCategory.sockolet),
      of(ComponentCategory.threadolet),
    ]),
    CategoryGroup('Pipeline Transport', _crimson, [
      of(ComponentCategory.pipelineTransport),
    ]),
  ];

  static List<CategoryMeta> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((m) {
      if (m.label.toLowerCase().contains(q) || m.standard.toLowerCase().contains(q)) return true;
      return m.dataset().any((row) => (row['nps'] as String).toLowerCase().contains(q));
    }).toList();
  }
}
