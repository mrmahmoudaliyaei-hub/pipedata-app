import 'package:flutter/cupertino.dart';
import 'models.dart';

enum SubOptionKind { none, schedules, classes, lengths, angles }

/// Central registry describing how each ComponentCategory should be
/// presented in the UI: label, icon, grouping, governing standard, and
/// which map key (if any) holds its selectable sub-options.
class CategoryMeta {
  final ComponentCategory category;
  final String label;
  final String standard;
  final IconData icon;
  final SubOptionKind subOptionKind;
  final List<Map<String, dynamic>> Function() dataset;

  const CategoryMeta({
    required this.category,
    required this.label,
    required this.standard,
    required this.icon,
    required this.subOptionKind,
    required this.dataset,
  });
}

class CategoryGroup {
  final String title;
  final List<CategoryMeta> items;
  const CategoryGroup(this.title, this.items);
}

class CategoryRegistry {
  static final Map<ComponentCategory, CategoryMeta> _byCategory = {
    for (final m in _all) m.category: m,
  };

  static CategoryMeta of(ComponentCategory c) => _byCategory[c]!;

  static final List<CategoryMeta> _all = [
    CategoryMeta(
      category: ComponentCategory.pipe,
      label: 'Pipes',
      standard: 'ASME B36.10M',
      icon: CupertinoIcons.circle,
      subOptionKind: SubOptionKind.schedules,
      dataset: () => PipingMasterCatalog.pipes,
    ),
    CategoryMeta(
      category: ComponentCategory.elbow,
      label: 'Elbows',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.compass,
      subOptionKind: SubOptionKind.angles,
      dataset: () => PipingMasterCatalog.elbows,
    ),
    CategoryMeta(
      category: ComponentCategory.tee,
      label: 'Tees',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.grid,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.tees,
    ),
    CategoryMeta(
      category: ComponentCategory.cap,
      label: 'Caps',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.flag_fill,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.caps,
    ),
    CategoryMeta(
      category: ComponentCategory.reducer,
      label: 'Reducers',
      standard: 'ASME B16.9',
      icon: CupertinoIcons.arrow_2_circlepath,
      subOptionKind: SubOptionKind.lengths,
      dataset: () => PipingMasterCatalog.reducers,
    ),
    CategoryMeta(
      category: ComponentCategory.flange,
      label: 'Flanges',
      standard: 'ASME B16.5',
      icon: CupertinoIcons.circle_filled,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.flanges,
    ),
    CategoryMeta(
      category: ComponentCategory.gasket,
      label: 'Gaskets',
      standard: 'ASME B16.20',
      icon: CupertinoIcons.layers_fill,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.gaskets,
    ),
    CategoryMeta(
      category: ComponentCategory.valve,
      label: 'Valves',
      standard: 'ASME B16.10',
      icon: CupertinoIcons.bolt,
      subOptionKind: SubOptionKind.classes,
      dataset: () => PipingMasterCatalog.valves,
    ),
    CategoryMeta(
      category: ComponentCategory.socketWeld,
      label: 'Socket-Weld',
      standard: 'ASME B16.11',
      icon: CupertinoIcons.gear_alt,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.socketWelds,
    ),
    CategoryMeta(
      category: ComponentCategory.threaded,
      label: 'Threaded (NPT)',
      standard: 'ASME B16.11',
      icon: CupertinoIcons.gear,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.threadeds,
    ),
    CategoryMeta(
      category: ComponentCategory.weldolet,
      label: 'Weldolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.hammer,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.weldolets,
    ),
    CategoryMeta(
      category: ComponentCategory.sockolet,
      label: 'Sockolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.wrench,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.sockolets,
    ),
    CategoryMeta(
      category: ComponentCategory.threadolet,
      label: 'Threadolets',
      standard: 'MSS SP-97',
      icon: CupertinoIcons.square,
      subOptionKind: SubOptionKind.none,
      dataset: () => PipingMasterCatalog.threadolets,
    ),
    CategoryMeta(
      category: ComponentCategory.pipelineTransport,
      label: 'Pipeline (Transport)',
      standard: 'ASME B31.4',
      icon: CupertinoIcons.drop,
      subOptionKind: SubOptionKind.schedules,
      dataset: () => PipingMasterCatalog.pipes,
    ),
  ];

  static final List<CategoryGroup> groups = [
    CategoryGroup('Pipes & Fittings', [
      of(ComponentCategory.pipe),
      of(ComponentCategory.elbow),
      of(ComponentCategory.tee),
      of(ComponentCategory.cap),
      of(ComponentCategory.reducer),
    ]),
    CategoryGroup('Flanged Components', [
      of(ComponentCategory.flange),
      of(ComponentCategory.gasket),
      of(ComponentCategory.valve),
    ]),
    CategoryGroup('Small-Bore Connections', [
      of(ComponentCategory.socketWeld),
      of(ComponentCategory.threaded),
    ]),
    CategoryGroup('Branch Outlets (MSS SP-97)', [
      of(ComponentCategory.weldolet),
      of(ComponentCategory.sockolet),
      of(ComponentCategory.threadolet),
    ]),
    CategoryGroup('Pipeline Transport', [
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
