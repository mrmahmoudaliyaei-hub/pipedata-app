import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';
import '../core/component_icons.dart';
import '../core/dimension_builder.dart';
import '../core/favorites.dart';
import '../core/models.dart';
import '../core/pdf_export.dart';
import '../core/units.dart';
import 'compare_screen.dart';
import 'schematic_fullscreen_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final ComponentCategory category;
  final int initialSizeIdx;
  final String? initialSubSelection;
  final String initialValveType;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.initialSizeIdx = 0,
    this.initialSubSelection,
    this.initialValveType = 'Gate Valve',
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late CategoryMeta _meta;
  int _sizeIdx = 0;
  String _subSelection = '';
  String _sizeQuery = '';
  MaterialGrade _selectedMaterial = MaterialGrade.a106B;
  int _activeTab = 0;

  // Valve-only: which body type (Gate/Globe/Ball/Swing Check) is selected.
  // Each type has its own face-to-face length per pressure class, so valves
  // need this second, independent selector alongside the usual class chips.
  static const List<String> _valveTypes = ['Gate Valve', 'Globe Valve', 'Ball Valve', 'Swing Check Valve'];
  String _valveType = 'Gate Valve';

  List<Map<String, dynamic>> get _dataset => _meta.dataset();

  @override
  void initState() {
    super.initState();
    _meta = CategoryRegistry.of(widget.category);
    _valveType = widget.initialValveType;
    if (widget.initialSizeIdx >= 0 && widget.initialSizeIdx < _dataset.length) {
      _sizeIdx = widget.initialSizeIdx;
    }
    if (widget.initialSubSelection != null) _subSelection = widget.initialSubSelection!;
    _syncSubSelection();
  }

  void _syncSubSelection() {
    if (_sizeIdx >= _dataset.length) _sizeIdx = 0;
    final item = _dataset[_sizeIdx];
    switch (_meta.subOptionKind) {
      case SubOptionKind.schedules:
        final opts = (item['schedules'] as Map<String, dynamic>).keys.toList();
        if (!opts.contains(_subSelection)) _subSelection = opts.contains('Sch 40 (STD)') ? 'Sch 40 (STD)' : opts.first;
        break;
      case SubOptionKind.classes:
        final opts = _meta.category == ComponentCategory.valve
            ? ((item['types'] as Map<String, dynamic>)[_valveType] as Map<String, dynamic>).keys.toList()
            : (item['classes'] as Map<String, dynamic>).keys.toList();
        if (!opts.contains(_subSelection)) _subSelection = opts.contains('Class 150') ? 'Class 150' : opts.first;
        break;
      case SubOptionKind.lengths:
        final opts = (item['lengths'] as Map<String, dynamic>).keys.toList();
        if (!opts.contains(_subSelection)) _subSelection = opts.contains('Concentric') ? 'Concentric' : opts.first;
        break;
      case SubOptionKind.angles:
        final opts = (item['angles'] as Map<String, dynamic>).keys.toList();
        if (!opts.contains(_subSelection)) _subSelection = opts.contains('90° Long Radius') ? '90° Long Radius' : opts.first;
        break;
      case SubOptionKind.none:
        _subSelection = '';
        break;
    }
  }

  List<int> get _visibleIndices {
    if (_sizeQuery.trim().isEmpty) return List.generate(_dataset.length, (i) => i);
    final q = _sizeQuery.trim().toLowerCase();
    final out = <int>[];
    for (int i = 0; i < _dataset.length; i++) {
      if ((_dataset[i]['nps'] as String).toLowerCase().contains(q)) out.add(i);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final item = _dataset[_sizeIdx];

    // Wraps navigationBar + body together so the unit-toggle button's own
    // label ('mm'/'in') and every formatted dimension in the body update
    // together on tap, without needing a full State.setState().
    return ValueListenableBuilder<LengthUnit>(
      valueListenable: unitsController,
      builder: (context, _, __) => CupertinoPageScaffold(
        backgroundColor: const Color(0xFF000000),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: const Color(0xF0161618),
          border: Border(bottom: BorderSide(color: _meta.color.withOpacity(0.25), width: 0.6)),
          middle: Text(_meta.label),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShareButton(item),
              const SizedBox(width: 8),
              _buildCompareButton(),
              const SizedBox(width: 8),
              _buildUnitToggle(),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _buildStandardBadge(item),
              const SizedBox(height: 10),
              if (_dataset.length > 6) _buildSizeSearch(),
              _buildSizeChips(),
              if (_meta.category == ComponentCategory.valve) _buildValveTypeChips(item),
              if (_meta.subOptionKind != SubOptionKind.none) _buildSubOptionChips(item),
              const SizedBox(height: 8),
              _buildSchematicCard(item),
              const SizedBox(height: 14),
              _buildTabSwitcher(),
              const SizedBox(height: 10),
              _buildActiveContent(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        final rows = buildDimensionRows(
          category: _meta.category,
          item: item,
          subSelection: _subSelection,
          valveType: _valveType,
        );
        shareDataSheet(
          title: '${item['nps']} ${_meta.label}',
          standard: _meta.standard,
          rows: rows,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Icon(CupertinoIcons.share, size: 16, color: _meta.color),
      ),
    );
  }

  Widget _buildCompareButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => CompareScreen(
            category: _meta.category,
            initialIndexA: _sizeIdx,
            initialSubSelectionA: _subSelection,
            initialValveType: _valveType,
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Icon(CupertinoIcons.arrow_left_right, size: 16, color: _meta.color),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return GestureDetector(
      onTap: () => unitsController.toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Text(
          unitsController.value == LengthUnit.mm ? 'mm' : 'in',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _meta.color),
        ),
      ),
    );
  }

  Widget _buildStandardBadge(Map<String, dynamic> item) {
    final Color c = _meta.color;
    final entry = FavoriteEntry(category: _meta.category, index: _sizeIdx, subSelection: _subSelection, valveType: _valveType);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.30)),
          ),
          child: Row(
            children: [
              Icon(_meta.icon, color: c, size: 13),
              const SizedBox(width: 6),
              Text(_meta.standard, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
            ],
          ),
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: favoritesController,
          builder: (context, _) {
            final isFav = favoritesController.isFavorite(entry);
            return GestureDetector(
              onTap: () => favoritesController.toggle(entry),
              child: Icon(
                isFav ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: isFav ? const Color(0xFF5FD1E8) : const Color(0xFF8E8E93),
                size: 20,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: c.withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
          ]),
        ),
      ],
    );
  }

  Widget _buildSizeSearch() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CupertinoSearchTextField(
        placeholder: 'Filter sizes',
        style: const TextStyle(color: CupertinoColors.white),
        onChanged: (v) => setState(() => _sizeQuery = v),
      ),
    );
  }

  Widget _buildSizeChips() {
    final indices = _visibleIndices;
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, k) {
          final i = indices[k];
          final row = _dataset[i];
          final isSel = _sizeIdx == i;
          return GestureDetector(
            onTap: () => setState(() {
              _sizeIdx = i;
              _syncSubSelection();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? CupertinoColors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? CupertinoColors.white : const Color(0xFF2C2C2E)),
              ),
              child: Text(
                row.containsKey('dn') ? '${row['nps']} (DN ${row['dn']})' : '${row['nps']}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? CupertinoColors.black : CupertinoColors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValveTypeChips(Map<String, dynamic> item) {
    const icons = {
      'Gate Valve': CupertinoIcons.arrow_up_down,
      'Globe Valve': CupertinoIcons.circle_grid_hex,
      'Ball Valve': CupertinoIcons.circle_filled,
      'Swing Check Valve': CupertinoIcons.arrow_right,
    };
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _valveTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = _valveTypes[i];
          final isSel = _valveType == t;
          return GestureDetector(
            onTap: () => setState(() {
              _valveType = t;
              _syncSubSelection();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? _meta.color.withOpacity(0.18) : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: isSel ? _meta.color : const Color(0xFF2C2C2E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[t], size: 13, color: isSel ? _meta.color : const Color(0xFF8E8E93)),
                  const SizedBox(width: 6),
                  Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubOptionChips(Map<String, dynamic> item) {
    List<String> opts = [];
    switch (_meta.subOptionKind) {
      case SubOptionKind.schedules:
        opts = (item['schedules'] as Map<String, dynamic>).keys.toList();
        break;
      case SubOptionKind.classes:
        opts = _meta.category == ComponentCategory.valve
            ? ((item['types'] as Map<String, dynamic>)[_valveType] as Map<String, dynamic>).keys.toList()
            : (item['classes'] as Map<String, dynamic>).keys.toList();
        break;
      case SubOptionKind.lengths:
        opts = (item['lengths'] as Map<String, dynamic>).keys.toList();
        break;
      case SubOptionKind.angles:
        opts = (item['angles'] as Map<String, dynamic>).keys.toList();
        break;
      case SubOptionKind.none:
        break;
    }
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSel = _subSelection == opts[i];
          return GestureDetector(
            onTap: () => setState(() => _subSelection = opts[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? _meta.color : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSel ? [BoxShadow(color: _meta.color.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Text(opts[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchematicCard(Map<String, dynamic> item) {
    final Color c = _meta.color;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => SchematicFullscreenScreen(
          category: _meta.category,
          data: item,
          subType: _subSelection,
          accentColor: c,
          valveType: _valveType,
          title: _meta.label,
        ),
      )),
      child: Container(
        height: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF17171A), Color.lerp(const Color(0xFF161618), c, 0.04)!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product reference photo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
                ),
                Icon(CupertinoIcons.zoom_in, size: 15, color: c),
              ],
            ),
            Expanded(
              child: Center(
                child: Image.asset(resolveIconAsset(_meta.category, valveType: _valveType), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return CupertinoSlidingSegmentedControl<int>(
      backgroundColor: const Color(0xFF1C1C1E),
      thumbColor: Color.lerp(const Color(0xFF2C2C2E), _meta.color, 0.22)!,
      groupValue: _activeTab,
      children: const {
        0: Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: Text('Dimensions', style: TextStyle(fontSize: 11, color: CupertinoColors.white))),
        1: Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: Text('Rating', style: TextStyle(fontSize: 11, color: CupertinoColors.white))),
        2: Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: Text('Bolting', style: TextStyle(fontSize: 11, color: CupertinoColors.white))),
      },
      onValueChanged: (v) {
        if (v != null) setState(() => _activeTab = v);
      },
    );
  }

  Widget _buildActiveContent(Map<String, dynamic> item) {
    if (_activeTab == 1) return _buildRatingTab(item);
    if (_activeTab == 2) return _buildBoltingTab(item);
    return _buildDimensionsTab(item);
  }

  // ---------------- Dimensions ----------------

  Widget _buildDimensionsTab(Map<String, dynamic> item) {
    final d = buildDimensionRows(
      category: _meta.category,
      item: item,
      subSelection: _subSelection,
      valveType: _valveType,
    );
    return _card(d.entries.map((e) => _dataRow(e.key, e.value)).toList());
  }

  // ---------------- Rating ----------------

  Widget _buildRatingTab(Map<String, dynamic> item) {
    switch (_meta.category) {
      case ComponentCategory.pipe:
        final schs = item['schedules'] as Map<String, dynamic>;
        final currentSch = schs[_subSelection] ?? schs.values.first;
        final od = (item['od'] as num).toDouble();
        final thk = (currentSch['thk'] as num).toDouble();
        final res = PipingStressEngine.calculatePipeMAWP(outerDiameterMm: od, nominalWallThkMm: thk, material: _selectedMaterial);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _materialChips(),
            const SizedBox(height: 8),
            _card([
              _dataRow('Allowable Working Pressure (MAWP)', '${res.mawpBar} Bar (${res.mawpPsi} PSI)', highlight: const Color(0xFF3D8EFF)),
              _dataRow('ASME Hydrostatic Test Pressure (1.5x)', '${res.hydroTestBar} Bar (${res.hydroTestPsi} PSI)', highlight: const Color(0xFF0A84FF)),
              _dataRow('Allowable Stress (S @ 38°C)', '${res.allowableStressMpa} MPa'),
              _dataRow('Mill Under-Tolerance (-12.5%)', unitsController.format(thk * 0.125)),
              _dataRow('Corrosion Allowance Included', unitsController.format(1.5)),
              _dataRow('Net Structural Wall (t_min)', unitsController.format(res.netTMin)),
            ]),
          ],
        );

      // Same unreachable-via-this-screen note as in _buildDimensionsTab above.
      case ComponentCategory.pipelineTransport:
        return _card([
          _dataRow('Design Factor & MAOP', 'See the Pipeline calculator', highlight: const Color(0xFF17356B)),
        ]);

      case ComponentCategory.flange:
        final pRatings = PipingStressEngine.getFlangePressureContainment(_subSelection);
        return _card([
          _dataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlight: const Color(0xFF3D8EFF)),
          _dataRow('High-Temp Rating @ 100°C', '${pRatings['t100']} Bar'),
          _dataRow('High-Temp Rating @ 200°C', '${pRatings['t200']} Bar'),
          _dataRow('High-Temp Rating @ 300°C', '${pRatings['t300']} Bar'),
          _dataRow('High-Temp Rating @ 400°C', '${pRatings['t400']} Bar'),
          _dataRow('Flange Hydrostatic Shell Test (1.5x)', '${pRatings['hydroShell']} Bar', highlight: const Color(0xFF0A84FF)),
        ]);

      case ComponentCategory.gasket:
      case ComponentCategory.valve:
        final matchClass = _subSelection.isNotEmpty ? _subSelection : 'Class 150';
        final pRatings = PipingStressEngine.getFlangePressureContainment(matchClass);
        return _card([
          _dataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlight: const Color(0xFF3D8EFF)),
          _dataRow('High-Temp Rating @ 200°C', '${pRatings['t200']} Bar'),
          _dataRow('High-Temp Rating @ 400°C', '${pRatings['t400']} Bar'),
          _dataRow('Hydrostatic Shell Test (1.5x)', '${pRatings['hydroShell']} Bar', highlight: const Color(0xFF0A84FF)),
        ], note: 'Rated per mating ASME B16.5 flange, $matchClass.');

      case ComponentCategory.reducer:
        return _note('Reducers are rated equivalent to the wall thickness/schedule of the mating pipe at each end per ASME B31.3 — see Pipes for that schedule\'s MAWP.');
      case ComponentCategory.tee:
      case ComponentCategory.elbow:
      case ComponentCategory.cap:
        return _note('Butt-weld fittings are rated equivalent to the matching pipe schedule per ASME B16.9 — see Pipes for that schedule\'s MAWP.');
      case ComponentCategory.socketWeld:
      case ComponentCategory.threaded:
        return _note('Forged fittings are rated equivalent to matching pipe schedule per ASME B16.11.');
      case ComponentCategory.weldolet:
      case ComponentCategory.sockolet:
      case ComponentCategory.threadolet:
        return _buildReinforcementNote();
    }
  }

  Widget _buildReinforcementNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Branch reinforcement — area-replacement method (ASME B31.3 §304.3.3)',
            style: TextStyle(color: Color(0xFFAEAEB2), fontSize: 12, fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'For a 90° branch, the area removed by the outlet must be replaced within the reinforcement zone:',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF0E0E10), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'A1 = d1 · th\nA2 + A3 + A4  ≥  A1',
              style: TextStyle(color: Color(0xFF6FADF0), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A1: required area · d1: branch opening in the run wall · th: run pipe\'s '
            'pressure design thickness (from the design pressure, NOT the schedule\'s '
            'nominal wall) · A2: excess run wall in the reinforcement zone · A3: excess '
            'branch wall in the zone · A4: attached weld metal.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'This tool doesn\'t collect a design pressure, temperature, or corrosion '
            'allowance for branch outlets, so it can\'t compute th (or A1-A4) for this '
            'specific item — showing a pass/fail here without those inputs would be a '
            'guess dressed up as a calculation. Run the full check in a proper piping '
            'stress tool (or by hand from the formula above) before use in a real design.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ---------------- Bolting ----------------

  Widget _buildBoltingTab(Map<String, dynamic> item) {
    if (_meta.category == ComponentCategory.flange) {
      final classes = item['classes'] as Map<String, dynamic>;
      final flg = classes[_subSelection] ?? classes.values.first;
      return _card([
        _dataRow('Bolt Stud Diameter', '${flg['boltSize']} UNC'),
        _dataRow('Stud Bolt Quantity', '${flg['bolts']} Studs'),
        _dataRow('Recommended Stud Length', unitsController.format(flg['studLen'] as num)),
        _dataRow('Recommended Tightening Torque', '${flg['torqueNm']} N·m (${(flg['torqueNm'] * 0.7375).toStringAsFixed(0)} ft-lb)', highlight: const Color(0xFF6FADF0)),
        _dataRow('Gasket Standard', 'ASME B16.20 Spiral Wound (316L/Graphite)'),
      ]);
    }
    if (_meta.category == ComponentCategory.gasket || _meta.category == ComponentCategory.valve) {
      final cls = _subSelection.isNotEmpty ? _subSelection : 'Class 150';
      return _note('Bolting for this component follows the mating ASME B16.5 flange ($cls) — see Flanges at the same class for stud size, quantity, and torque.');
    }
    return _note('Bolting data is specific to ASME B16.5 Flange assemblies.');
  }

  // ---------------- Shared widgets ----------------

  Widget _materialChips() {
    final options = {
      MaterialGrade.a106B: 'A106 Gr. B (Carbon)',
      MaterialGrade.a312Tp316L: 'A312 TP316L (SS)',
      MaterialGrade.a333Gr6: 'A333 Gr. 6 (Low-Temp)',
    };
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final grade = options.keys.elementAt(i);
          final isSel = _selectedMaterial == grade;
          return GestureDetector(
            onTap: () => setState(() => _selectedMaterial = grade),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(options[grade]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
            ),
          );
        },
      ),
    );
  }

  Widget _card(List<Widget> rows, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
          child: Column(children: rows),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(note, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
          ),
      ],
    );
  }

  Widget _note(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 12, height: 1.4)),
    );
  }

  Widget _dataRow(String label, String value, {Color? highlight}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF242426), width: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 12.5, color: highlight ?? CupertinoColors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
