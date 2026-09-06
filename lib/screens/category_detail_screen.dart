import 'package:flutter/cupertino.dart';
import '../core/category_meta.dart';
import '../core/models.dart';
import '../painters/schematic_painter.dart';

class CategoryDetailScreen extends StatefulWidget {
  final ComponentCategory category;
  const CategoryDetailScreen({super.key, required this.category});

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

  List<Map<String, dynamic>> get _dataset => _meta.dataset();

  @override
  void initState() {
    super.initState();
    _meta = CategoryRegistry.of(widget.category);
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
        final opts = (item['classes'] as Map<String, dynamic>).keys.toList();
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

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xF0161618),
        border: Border(bottom: BorderSide(color: _meta.color.withOpacity(0.25), width: 0.6)),
        middle: Text(_meta.label),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _buildStandardBadge(),
            const SizedBox(height: 10),
            if (_dataset.length > 6) _buildSizeSearch(),
            _buildSizeChips(),
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
    );
  }

  Widget _buildStandardBadge() {
    final Color c = _meta.color;
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

  Widget _buildSubOptionChips(Map<String, dynamic> item) {
    List<String> opts = [];
    switch (_meta.subOptionKind) {
      case SubOptionKind.schedules:
        opts = (item['schedules'] as Map<String, dynamic>).keys.toList();
        break;
      case SubOptionKind.classes:
        opts = (item['classes'] as Map<String, dynamic>).keys.toList();
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
    return Container(
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
              const Text('CROSS-SECTION ENGINEERING BLUEPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.6)),
              Text('CAD VECTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(260, 150),
                painter: VectorBlueprintPainter(category: _meta.category, data: item, subType: _subSelection),
              ),
            ),
          ),
        ],
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
    final Map<String, String> d = {};
    d['Nominal Pipe Size (NPS)'] = item['nps'] as String;
    if (item.containsKey('dn')) d['Diameter Nominal'] = 'DN ${item['dn']}';

    switch (_meta.category) {
      case ComponentCategory.pipe:
      case ComponentCategory.pipelineTransport:
        final schs = item['schedules'] as Map<String, dynamic>;
        final s = schs[_subSelection] ?? schs.values.first;
        d['Outside Diameter (OD)'] = '${item['od']} mm';
        d['Schedule / Wall Class'] = _subSelection;
        d['Wall Thickness (t)'] = '${s['thk']} mm';
        d['Inside Diameter (ID)'] = '${s['id']} mm';
        d['Linear Weight'] = '${s['wt']} kg/m';
        break;
      case ComponentCategory.flange:
        final clss = item['classes'] as Map<String, dynamic>;
        final f = clss[_subSelection] ?? clss.values.first;
        d['Pressure Rating'] = _subSelection;
        d['Flange Outside Diameter (O)'] = '${f['od']} mm';
        d['Minimum Flange Thickness (C)'] = '${f['thk']} mm';
        d['Pitch Circle Diameter (PCD)'] = '${f['pcd']} mm';
        break;
      case ComponentCategory.tee:
        d['Center-to-End (C)'] = '${item['teeCtoE']} mm';
        d['Standard'] = 'ASME B16.9 Equal Tee';
        break;
      case ComponentCategory.elbow:
        final angles = item['angles'] as Map<String, dynamic>;
        final lenMm = (angles[_subSelection] ?? angles.values.first) as num;
        d['Pattern'] = _subSelection;
        d['Center-to-End (C)'] = '${lenMm.toStringAsFixed(1)} mm';
        d['Standard'] = 'ASME B16.9';
        break;
      case ComponentCategory.cap:
        d['Length (E)'] = '${item['capLen']} mm';
        d['Standard'] = 'ASME B16.9 Domed Cap';
        break;
      case ComponentCategory.socketWeld:
        d['Socket Bore Diameter'] = '${item['boreDia']} mm';
        d['Socket Minimum Depth'] = '${item['depth']} mm';
        d['Center-to-End Distance'] = '${item['cToE']} mm';
        d['Fitting Minimum Wall'] = '${item['minWall']} mm';
        d['Thermal Fit-up Gap'] = '1.6 mm (1/16")';
        break;
      case ComponentCategory.threaded:
        d['Threads per Inch (TPI)'] = '${item['tpi']}';
        d['Thread Pitch (p)'] = '${item['pitch']} mm';
        d['Effective Thread Length (L2)'] = '${item['minThreadL2']} mm';
        d['Standard Taper Ratio'] = '${item['taper']}';
        break;
      case ComponentCategory.reducer:
        final lens = item['lengths'] as Map<String, dynamic>;
        final lenMm = (lens[_subSelection] ?? lens.values.first) as num;
        d['Reduction Pattern'] = _subSelection;
        d['Large End DN'] = 'DN ${item['largeDn']}';
        d['Small End DN'] = 'DN ${item['smallDn']}';
        d['Center-to-End Length (H)'] = '${lenMm.toStringAsFixed(0)} mm';
        d['Standard'] = 'ASME B16.9';
        break;
      case ComponentCategory.gasket:
        final clss = item['classes'] as Map<String, dynamic>;
        final g = clss[_subSelection] ?? clss.values.first;
        d['Pressure Class'] = _subSelection;
        d['Gasket Inside Diameter (ID)'] = '${g['id']} mm';
        d['Gasket Outside Diameter (OD)'] = '${g['od']} mm';
        d['Nominal Thickness'] = '${g['thk']} mm';
        d['Style'] = 'Spiral-Wound, CG (316L windings / flexible graphite filler)';
        d['Standard'] = 'ASME B16.20';
        break;
      case ComponentCategory.valve:
        final clss = item['classes'] as Map<String, dynamic>;
        final v = clss[_subSelection] ?? clss.values.first;
        d['Pressure Class'] = _subSelection;
        d['Gate Valve Face-to-Face'] = '${v['gateFtf']} mm';
        d['Ball Valve Face-to-Face (Short Pattern)'] = '${v['ballFtf']} mm';
        d['Swing Check Valve Face-to-Face'] = '${v['checkFtf']} mm';
        d['End Connection'] = 'Raised Face Flanged (RF)';
        d['Standard'] = 'ASME B16.10';
        break;
      case ComponentCategory.weldolet:
        d['Outlet Height (A)'] = '${item['height']} mm';
        d['End Connection'] = 'Butt-Weld Outlet';
        d['Standard'] = 'MSS SP-97 (size-on-size, STD)';
        break;
      case ComponentCategory.sockolet:
        d['Outlet Height (A)'] = '${item['height']} mm';
        d['Socket Depth'] = '${item['socketDepth']} mm';
        d['End Connection'] = 'Socket-Weld Outlet';
        d['Standard'] = 'MSS SP-97 (size-on-size, Class 3000)';
        break;
      case ComponentCategory.threadolet:
        d['Outlet Height (A)'] = '${item['height']} mm';
        d['End Connection'] = 'NPT Threaded Outlet';
        d['Standard'] = 'MSS SP-97 (size-on-size, Class 3000)';
        break;
    }

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
              _dataRow('Allowable Working Pressure (MAWP)', '${res.mawpBar} Bar (${res.mawpPsi} PSI)', highlight: const Color(0xFF30D158)),
              _dataRow('ASME Hydrostatic Test Pressure (1.5x)', '${res.hydroTestBar} Bar (${res.hydroTestPsi} PSI)', highlight: const Color(0xFF0A84FF)),
              _dataRow('Allowable Stress (S @ 38°C)', '${res.allowableStressMpa} MPa'),
              _dataRow('Mill Under-Tolerance (-12.5%)', '${(thk * 0.125).toStringAsFixed(2)} mm'),
              _dataRow('Corrosion Allowance Included', '1.5 mm'),
              _dataRow('Net Structural Wall (t_min)', '${res.netTMin} mm'),
            ]),
          ],
        );

      case ComponentCategory.pipelineTransport:
        return _card([
          _dataRow('Design Factor & MAOP', 'See the Pipeline calculator', highlight: const Color(0xFFFF453A)),
        ]);

      case ComponentCategory.flange:
        final pRatings = PipingStressEngine.getFlangePressureContainment(_subSelection);
        return _card([
          _dataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlight: const Color(0xFF30D158)),
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
          _dataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlight: const Color(0xFF30D158)),
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
        return _note('Branch outlet fittings are rated by the run pipe\'s schedule and the reinforcement area at the outlet per MSS SP-97 / ASME B31.3 Ch. II, Part 4 — a full area-replacement check is outside this quick-reference tool.');
    }
  }

  // ---------------- Bolting ----------------

  Widget _buildBoltingTab(Map<String, dynamic> item) {
    if (_meta.category == ComponentCategory.flange) {
      final classes = item['classes'] as Map<String, dynamic>;
      final flg = classes[_subSelection] ?? classes.values.first;
      return _card([
        _dataRow('Bolt Stud Diameter', '${flg['boltSize']} UNC'),
        _dataRow('Stud Bolt Quantity', '${flg['bolts']} Studs'),
        _dataRow('Recommended Stud Length', '${flg['studLen']} mm'),
        _dataRow('Recommended Tightening Torque', '${flg['torqueNm']} N·m (${(flg['torqueNm'] * 0.7375).toStringAsFixed(0)} ft-lb)', highlight: const Color(0xFFFF9F0A)),
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
