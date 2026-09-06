import 'package:flutter/material.dart';
import 'core/models.dart';
import 'painters/schematic_painter.dart';

void main() => runApp(const PipingWorkstationApp());

class PipingWorkstationApp extends StatelessWidget {
  const PipingWorkstationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piping Data Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF0A84FF),
      ),
      home: const MainWorkstation(),
    );
  }
}

class MainWorkstation extends StatefulWidget {
  const MainWorkstation({super.key});

  @override
  State<MainWorkstation> createState() => _MainWorkstationState();
}

class _MainWorkstationState extends State<MainWorkstation> {
  ComponentCategory _category = ComponentCategory.pipe;
  int _sizeIdx = 4; // NPS 2"
  String _subSelection = 'Sch 40 (STD)';
  MaterialGrade _selectedMaterial = MaterialGrade.a106B;
  int _activeViewTab = 0; // 0: Dimensions, 1: Pressure & Hydro, 2: Bolting

  List<Map<String, dynamic>> get _dataset {
    switch (_category) {
      case ComponentCategory.pipe:
        return PipingMasterCatalog.pipes;
      case ComponentCategory.flange:
        return PipingMasterCatalog.flanges;
      case ComponentCategory.buttWeld:
        return PipingMasterCatalog.buttWelds;
      case ComponentCategory.socketWeld:
        return PipingMasterCatalog.socketWelds;
      case ComponentCategory.threaded:
        return PipingMasterCatalog.threadeds;
      case ComponentCategory.reducer:
        return PipingMasterCatalog.reducers;
      case ComponentCategory.gasket:
        return PipingMasterCatalog.gaskets;
      case ComponentCategory.valve:
        return PipingMasterCatalog.valves;
    }
  }

  void _syncSubSelection() {
    final item = _dataset[_sizeIdx];
    if (_category == ComponentCategory.pipe) {
      final schs = (item['schedules'] as Map<String, dynamic>).keys.toList();
      if (!schs.contains(_subSelection)) _subSelection = schs.contains('Sch 40 (STD)') ? 'Sch 40 (STD)' : schs.first;
    } else if (_category == ComponentCategory.flange || _category == ComponentCategory.gasket || _category == ComponentCategory.valve) {
      final clss = (item['classes'] as Map<String, dynamic>).keys.toList();
      if (!clss.contains(_subSelection)) _subSelection = clss.contains('Class 150') ? 'Class 150' : clss.first;
    } else if (_category == ComponentCategory.reducer) {
      final lens = (item['lengths'] as Map<String, dynamic>).keys.toList();
      if (!lens.contains(_subSelection)) _subSelection = lens.contains('Concentric') ? 'Concentric' : lens.first;
    } else {
      _subSelection = '';
    }
  }

  @override
  void initState() {
    super.initState();
    _syncSubSelection();
  }

  @override
  Widget build(BuildContext context) {
    if (_sizeIdx >= _dataset.length) _sizeIdx = 0;
    final item = _dataset[_sizeIdx];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppleNavBar(),
            _buildCategorySelector(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSizeSlider(item),
                  if (_category == ComponentCategory.pipe ||
                      _category == ComponentCategory.flange ||
                      _category == ComponentCategory.reducer ||
                      _category == ComponentCategory.gasket ||
                      _category == ComponentCategory.valve)
                    _buildSubOptionChips(item),
                  const SizedBox(height: 8),
                  _buildCadSchematicCard(item),
                  const SizedBox(height: 12),
                  _buildViewTabSwitcher(),
                  const SizedBox(height: 10),
                  _buildActiveContent(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Piping Data Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
              SizedBox(height: 2),
              Text('ASME INDUSTRIAL CAD & STRESS SUITE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93), letterSpacing: 0.6)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: Row(
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF30D158), size: 12),
                SizedBox(width: 5),
                Text('ASME B31.3', style: TextStyle(fontSize: 10, color: Color(0xFF30D158), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'label': 'Pipes', 'cat': ComponentCategory.pipe},
      {'label': 'Flanges', 'cat': ComponentCategory.flange},
      {'label': 'Butt-Weld', 'cat': ComponentCategory.buttWeld},
      {'label': 'Socket-Weld', 'cat': ComponentCategory.socketWeld},
      {'label': 'Threaded', 'cat': ComponentCategory.threaded},
      {'label': 'Reducers', 'cat': ComponentCategory.reducer},
      {'label': 'Gaskets', 'cat': ComponentCategory.gasket},
      {'label': 'Valves', 'cat': ComponentCategory.valve},
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(10)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSel = _category == c['cat'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _category = c['cat'] as ComponentCategory;
                _sizeIdx = 0;
                _syncSubSelection();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF2C2C2E) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c['label'] as String,
                style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400, color: isSel ? Colors.white : const Color(0xFF8E8E93)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeSlider(Map<String, dynamic> item) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dataset.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
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
                color: isSel ? Colors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? Colors.white : const Color(0xFF2C2C2E)),
              ),
              child: Text(
                _dataset[i].containsKey('dn')
                    ? '${_dataset[i]['nps']} (DN ${_dataset[i]['dn']})'
                    : '${_dataset[i]['nps']}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.black : Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubOptionChips(Map<String, dynamic> item) {
    List<String> opts = [];
    if (_category == ComponentCategory.pipe) {
      opts = (item['schedules'] as Map<String, dynamic>).keys.toList();
    } else if (_category == ComponentCategory.flange ||
        _category == ComponentCategory.gasket ||
        _category == ComponentCategory.valve) {
      opts = (item['classes'] as Map<String, dynamic>).keys.toList();
    } else if (_category == ComponentCategory.reducer) {
      opts = (item['lengths'] as Map<String, dynamic>).keys.toList();
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
                color: isSel ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(opts[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF8E8E93))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCadSchematicCard(Map<String, dynamic> item) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('CROSS-SECTION ENGINEERING BLUEPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.6)),
              Text('CAD VECTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9F0A))),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(260, 150),
                painter: VectorBlueprintPainter(category: _category, data: item, subType: _subSelection),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabSwitcher() {
    final tabs = ['Dimensional Data', 'Pressure & Hydro Rating', 'Bolting & Standards'];
    return Container(
      height: 34,
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSel = _activeViewTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeViewTab = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF2C2C2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(tabs[i], style: TextStyle(fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF8E8E93))),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveContent(Map<String, dynamic> item) {
    if (_activeViewTab == 1) {
      return _buildPressureTab(item);
    } else if (_activeViewTab == 2) {
      return _buildBoltingTab(item);
    }
    return _buildDimensionsTab(item);
  }

  Widget _buildPressureTab(Map<String, dynamic> item) {
    if (_category == ComponentCategory.pipe) {
      final schs = item['schedules'] as Map<String, dynamic>;
      final currentSch = schs[_subSelection] ?? schs.values.first;
      final od = (item['od'] as num).toDouble();
      final thk = (currentSch['thk'] as num).toDouble();

      final res = PipingStressEngine.calculatePipeMAWP(
        outerDiameterMm: od,
        nominalWallThkMm: thk,
        material: _selectedMaterial,
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MATERIAL GRADE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
                DropdownButton<MaterialGrade>(
                  value: _selectedMaterial,
                  dropdownColor: const Color(0xFF1C1C1E),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: MaterialGrade.a106B, child: Text('ASTM A106 Gr. B (Carbon)', style: TextStyle(fontSize: 11, color: Colors.white))),
                    DropdownMenuItem(value: MaterialGrade.a312Tp316L, child: Text('ASTM A312 TP316L (SS)', style: TextStyle(fontSize: 11, color: Colors.white))),
                    DropdownMenuItem(value: MaterialGrade.a333Gr6, child: Text('ASTM A333 Gr. 6 (Low-Temp)', style: TextStyle(fontSize: 11, color: Colors.white))),
                  ],
                  onChanged: (val) => setState(() => _selectedMaterial = val!),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 18),
            _buildDataRow('Allowable Working Pressure (MAWP)', '${res.mawpBar} Bar (${res.mawpPsi} PSI)', highlightColor: const Color(0xFF30D158)),
            _buildDataRow('ASME Hydrostatic Test Pressure (1.5x)', '${res.hydroTestBar} Bar (${res.hydroTestPsi} PSI)', highlightColor: const Color(0xFF0A84FF)),
            _buildDataRow('Allowable Stress (S @ 38°C)', '${res.allowableStressMpa} MPa'),
            _buildDataRow('Mill Under-Tolerance (-12.5%)', '${(thk * 0.125).toStringAsFixed(2)} mm'),
            _buildDataRow('Corrosion Allowance Included', '1.5 mm'),
            _buildDataRow('Net Structural Wall (t_min)', '${res.netTMin} mm'),
          ],
        ),
      );
    } else if (_category == ComponentCategory.flange) {
      final pRatings = PipingStressEngine.getFlangePressureContainment(_subSelection);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ASME B16.5 PRESSURE-TEMPERATURE CONTAINMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            const SizedBox(height: 10),
            _buildDataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlightColor: const Color(0xFF30D158)),
            _buildDataRow('High-Temp Rating @ 100°C', '${pRatings['t100']} Bar'),
            _buildDataRow('High-Temp Rating @ 200°C', '${pRatings['t200']} Bar'),
            _buildDataRow('High-Temp Rating @ 300°C', '${pRatings['t300']} Bar'),
            _buildDataRow('High-Temp Rating @ 400°C', '${pRatings['t400']} Bar'),
            _buildDataRow('Flange Hydrostatic Shell Test (1.5x)', '${pRatings['hydroShell']} Bar', highlightColor: const Color(0xFF0A84FF)),
          ],
        ),
      );
    } else if (_category == ComponentCategory.gasket || _category == ComponentCategory.valve) {
      // Gaskets and flanged valves are pressure-rated by their mating ASME B16.5 flange class.
      final matchClass = _subSelection.isNotEmpty ? _subSelection : 'Class 150';
      final pRatings = PipingStressEngine.getFlangePressureContainment(matchClass);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RATED PER MATING ASME B16.5 FLANGE ($matchClass)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            const SizedBox(height: 10),
            _buildDataRow('Ambient Working Pressure (-29 to 38°C)', '${pRatings['ambient']} Bar', highlightColor: const Color(0xFF30D158)),
            _buildDataRow('High-Temp Rating @ 200°C', '${pRatings['t200']} Bar'),
            _buildDataRow('High-Temp Rating @ 400°C', '${pRatings['t400']} Bar'),
            _buildDataRow('Hydrostatic Shell Test (1.5x)', '${pRatings['hydroShell']} Bar', highlightColor: const Color(0xFF0A84FF)),
          ],
        ),
      );
    } else if (_category == ComponentCategory.reducer) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
        child: const Text('Reducers are rated equivalent to the wall thickness/schedule of the mating pipe at each end per ASME B31.3 — see the Pipes tab for that schedule\'s MAWP.', style: TextStyle(color: Colors.white70, fontSize: 12)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: const Text('Forged fittings are rated equivalent to matching pipe schedule per ASME B16.11.', style: TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _buildBoltingTab(Map<String, dynamic> item) {
    if (_category == ComponentCategory.flange) {
      final classes = item['classes'] as Map<String, dynamic>;
      final flg = classes[_subSelection] ?? classes.values.first;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
        child: Column(
          children: [
            _buildDataRow('Bolt Stud Diameter', '${flg['boltSize']} UNC'),
            _buildDataRow('Stud Bolt Quantity', '${flg['bolts']} Studs'),
            _buildDataRow('Recommended Stud Length', '${flg['studLen']} mm'),
            _buildDataRow('Recommended Tightening Torque', '${flg['torqueNm']} N·m (${(flg['torqueNm'] * 0.7375).toStringAsFixed(0)} ft-lb)', highlightColor: const Color(0xFFFF9F0A)),
            _buildDataRow('Gasket Standard', 'ASME B16.20 Spiral Wound (316L/Graphite)'),
          ],
        ),
      );
    } else if (_category == ComponentCategory.gasket || _category == ComponentCategory.valve) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
        child: Text('Bolting for this component follows the mating ASME B16.5 flange (${_subSelection.isNotEmpty ? _subSelection : "Class 150"}) — see the Flanges tab at the same class for stud size, quantity, and torque.', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: const Text('Bolting data is specific to ASME B16.5 Flange assemblies.', style: TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _buildDimensionsTab(Map<String, dynamic> item) {
    final Map<String, String> d = {};
    d['Nominal Pipe Size (NPS)'] = item['nps'] as String;
    if (item.containsKey('dn')) d['Diameter Nominal'] = 'DN ${item['dn']}';

    if (_category == ComponentCategory.pipe) {
      final schs = item['schedules'] as Map<String, dynamic>;
      final s = schs[_subSelection] ?? schs.values.first;
      d['Outside Diameter (OD)'] = '${item['od']} mm';
      d['Schedule / Wall Class'] = _subSelection;
      d['Wall Thickness (t)'] = '${s['thk']} mm';
      d['Inside Diameter (ID)'] = '${s['id']} mm';
      d['Linear Weight'] = '${s['wt']} kg/m';
    } else if (_category == ComponentCategory.flange) {
      final clss = item['classes'] as Map<String, dynamic>;
      final f = clss[_subSelection] ?? clss.values.first;
      d['Pressure Rating'] = _subSelection;
      d['Flange Outside Diameter (O)'] = '${f['od']} mm';
      d['Minimum Flange Thickness (C)'] = '${f['thk']} mm';
      d['Pitch Circle Diameter (PCD)'] = '${f['pcd']} mm';
    } else if (_category == ComponentCategory.buttWeld) {
      d['90° LR Center-to-End'] = '${item['lrElbow90']} mm';
      d['90° SR Center-to-End'] = '${item['srElbow90']} mm';
      d['45° Elbow Center-to-End'] = '${item['elbow45']} mm';
      d['Equal Tee Center-to-End'] = '${item['teeCtoE']} mm';
      d['Reducer Length (H)'] = '${item['redLen']} mm';
    } else if (_category == ComponentCategory.socketWeld) {
      d['Socket Bore Diameter'] = '${item['boreDia']} mm';
      d['Socket Minimum Depth'] = '${item['depth']} mm';
      d['Center-to-End Distance'] = '${item['cToE']} mm';
      d['Fitting Minimum Wall'] = '${item['minWall']} mm';
      d['Thermal Fit-up Gap'] = '1.6 mm (1/16")';
    } else if (_category == ComponentCategory.threaded) {
      d['Threads per Inch (TPI)'] = '${item['tpi']}';
      d['Thread Pitch (p)'] = '${item['pitch']} mm';
      d['Effective Thread Length (L2)'] = '${item['minThreadL2']} mm';
      d['Standard Taper Ratio'] = '${item['taper']}';
    } else if (_category == ComponentCategory.reducer) {
      final lens = item['lengths'] as Map<String, dynamic>;
      final lenMm = (lens[_subSelection] ?? lens.values.first) as num;
      d['Reduction Pattern'] = _subSelection;
      d['Large End DN'] = 'DN ${item['largeDn']}';
      d['Small End DN'] = 'DN ${item['smallDn']}';
      d['Center-to-End Length (H)'] = '${lenMm.toStringAsFixed(0)} mm';
      d['Standard'] = 'ASME B16.9';
    } else if (_category == ComponentCategory.gasket) {
      final clss = item['classes'] as Map<String, dynamic>;
      final g = clss[_subSelection] ?? clss.values.first;
      d['Pressure Class'] = _subSelection;
      d['Gasket Inside Diameter (ID)'] = '${g['id']} mm';
      d['Gasket Outside Diameter (OD)'] = '${g['od']} mm';
      d['Nominal Thickness'] = '${g['thk']} mm';
      d['Style'] = 'Spiral-Wound, CG (316L windings / flexible graphite filler)';
      d['Standard'] = 'ASME B16.20';
    } else if (_category == ComponentCategory.valve) {
      final clss = item['classes'] as Map<String, dynamic>;
      final v = clss[_subSelection] ?? clss.values.first;
      d['Pressure Class'] = _subSelection;
      d['Gate Valve Face-to-Face'] = '${v['gateFtf']} mm';
      d['Ball Valve Face-to-Face (Short Pattern)'] = '${v['ballFtf']} mm';
      d['Swing Check Valve Face-to-Face'] = '${v['checkFtf']} mm';
      d['End Connection'] = 'Raised Face Flanged (RF)';
      d['Standard'] = 'ASME B16.10';
    }

    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
      child: Column(
        children: d.entries.map((e) => _buildDataRow(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {Color? highlightColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF242426), width: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 12.5, color: highlightColor ?? Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
