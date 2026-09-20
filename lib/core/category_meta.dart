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

  // Professional dark-blue accent family — every category still gets its
  // own distinct shade (so cards read as separate, intentional items, not
  // one repeated color), but all of them now live within the same blue
  // spectrum instead of a multicolor rainbow, per the requested redesign.
  // Names kept as-is (not renamed to _navy1/_navy2/...) so every existing
  // reference below and in pipeline_screen.dart's group color didn't need
  // to change, only what each name actually points to.
  static const _blue = Color(0xFF2E7DF7); // primary azure
  static const _teal = Color(0xFF1FA9D6); // teal-blue
  static const _indigo = Color(0xFF4A5FD1); // indigo-blue
  static const _mint = Color(0xFF5FD1E8); // pale cyan-blue
  static const _orange = Color(0xFF3D8EFF); // mid azure (was orange)
  static const _purple = Color(0xFF5D6BD8); // blue-violet
  static const _pink = Color(0xFF4C82E8); // soft blue (was pink)
  static const _red = Color(0xFF1E4FA8); // deep navy (was red — Valves)
  static const _yellow = Color(0xFF6FADF0); // pale azure (was yellow)
  static const _cyan = Color(0xFF17A2D6); // cyan-blue
  static const _green = Color(0xFF2AA8C4); // teal-cyan (was green)
  static const _skyBlue = Color(0xFF4FA0E8);
  // Distinct from _red (Valves) — Pipeline (Transport) used to share _red,
  // which broke the "one accent per category" rule; this is its own accent.
  static const _crimson = Color(0xFF17356B); // deep midnight blue (was crimson)

  static final List<CategoryMeta> _all = [
    CategoryMeta(
      category: ComponentCategory.pipe,
      label: 'Pipes',
      standard: 'ASME B36.10M / API 5L',
      icon: CupertinoIcons.smallcircle_circle,
      color: _blue,
      subOptionKind: SubOptionKind.schedules,
      dataset: () => PipingMasterCatalog.pipes,
    ),
    CategoryMeta(
      category: ComponentCategory.elbow,
      label: 'Elbows',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.arrow_turn_left_up,
      color: _teal,
      subOptionKind: SubOptionKind.angles,
      dataset: () => PipingMasterCatalog.elbows,
    ),
    CategoryMeta(
      category: ComponentCategory.tee,
      label: 'Tees',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.share,
      color: _indigo,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.tees,
    ),
    CategoryMeta(
      category: ComponentCategory.cap,
      label: 'Caps',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.lock_fill,
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
      icon: CupertinoIcons.link_circle,
      color: _yellow,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.socketWelds,
    ),
    CategoryMeta(
      category: ComponentCategory.weldolet,
      label: 'Weldolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.link,
      color: _cyan,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.weldolets,
    ),
    CategoryMeta(
      category: ComponentCategory.sockolet,
      label: 'Sockolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.arrow_up_right,
      color: _green,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.sockolets,
    ),
    CategoryMeta(
      category: ComponentCategory.threadolet,
      label: 'Threadolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.rotate_right_fill,
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

  // Ordered to follow how a piping engineer actually thinks through a
  // system: the pipe itself, then the fittings that route it, then the
  // bolted connections (flange+gasket), then flow control (valves get
  // their own top-billed group, not buried inside Flanged Components),
  // then branch/small-bore work, then the separate pipeline calculator.
  static final List<CategoryGroup> groups = [
    CategoryGroup('Pipe & Fittings', _blue, [
      of(ComponentCategory.pipe),
      of(ComponentCategory.elbow),
      of(ComponentCategory.tee),
      of(ComponentCategory.reducer),
      of(ComponentCategory.cap),
    ]),
    CategoryGroup('Flanges & Gaskets', _purple, [
      of(ComponentCategory.flange),
      of(ComponentCategory.gasket),
    ]),
    CategoryGroup('Valves', _red, [
      of(ComponentCategory.valve),
    ]),
    CategoryGroup('Branch Outlets (MSS SP-97)', _cyan, [
      of(ComponentCategory.weldolet),
      of(ComponentCategory.sockolet),
      of(ComponentCategory.threadolet),
    ]),
    CategoryGroup('Small-Bore Connections', _yellow, [
      of(ComponentCategory.socketWeld),
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
