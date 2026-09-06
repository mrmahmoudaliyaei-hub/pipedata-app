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
        scaffoldBackgroundColor: const Color(0xFF000000), // Apple OLED Deep Black
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
  int _sizeIdx = 4; // پیش‌فرض 2 اینچ
  String _subSelection = 'Sch 40 (STD)';
  MaterialGrade _selectedMaterial = MaterialGrade.a106B;
  int _activeViewTab = 0; // 0: مشخصات ابعادی, 1: تحلیل فشار و تست هیدرو, 2: محاسبات اتصال و پیچ‌کشی

  List<Map<String, dynamic>> get _dataset {
    switch (_category) {
      case ComponentCategory.pipe:
        return FullPipingDataset.pipes;
      case ComponentCategory.flange:
        return FullPipingDataset.flanges;
      case ComponentCategory.buttWeld:
        return FullPipingDataset.buttWelds;
      case ComponentCategory.socketWeld:
        return FullPipingDataset.socketWelds;
      case ComponentCategory.threaded:
        return FullPipingDataset.threadeds;
    }
  }

  void _syncSubSelection() {
    final item = _dataset[_sizeIdx];
    if (_category == ComponentCategory.pipe) {
      final schs = (item['schedules'] as Map<String, dynamic>).keys.toList();
      if (!schs.contains(_subSelection)) _subSelection = schs.contains('Sch 40 (STD)') ? 'Sch 40 (STD)' : schs.first;
    } else if (_category == ComponentCategory.flange) {
      final clss = (item['classes'] as Map<String, dynamic>).keys.toList();
      if (!clss.contains(_subSelection)) _subSelection = clss.contains('Class 150') ? 'Class 150' : clss.first;
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
                  if (_category == ComponentCategory.pipe || _category == ComponentCategory.flange)
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
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: categories.map((c) {
          final isSel = _category == c['cat'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _category = c['cat'] as ComponentCategory;
                  _sizeIdx = 0;
                  _syncSubSelection();
                });
              },
              child: Container(
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
            ),
          );
        }).toList(),
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
                '${_dataset[i]['nps']} (DN ${_dataset[i]['dn']})',
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
    } else if (_category == ComponentCategory.flange) {
      opts = (item['classes'] as Map<String, dynamic>).keys.toList();
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
                painter: ProfessionalCadPainter(category: _category, data: item, subType: _subSelection),
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

  // تب محاسبات فشار مجاز و تست هیدرو بر اساس استاندارد ASME B31.3 / B16.5
  Widget _buildPressureTab(Map<String, dynamic> item) {
    if (_category == ComponentCategory.pipe) {
      final schs = item['schedules'] as Map<String, dynamic>;
      final currentSch = schs[_subSelection] ?? schs.values.first;
      final od = (item['od'] as num).toDouble();
      final thk = (currentSch['thk'] as num).toDouble();

      final results = PipingEngine.calculatePipePressure(
        od: od,
        nominalThk: thk,
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
                const Text('MATERIAL SELECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
                DropdownButton<MaterialGrade>(
                  value: _selectedMaterial,
                  dropdownColor: const Color(0xFF1C1C1E),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: MaterialGrade.a106B, child: Text('ASTM A106 Gr. B (Carbon Steel)', style: TextStyle(fontSize: 11, color: Colors.white))),
                    DropdownMenuItem(value: MaterialGrade.a312Tp316L, child: Text('ASTM A312 TP316L (Stainless)', style: TextStyle(fontSize: 11, color: Colors.white))),
                  ],
                  onChanged: (val) => setState(() => _selectedMaterial = val!),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 20),
            _buildDataRow('Allowable Working Pressure (MAWP)', '${results['mawpBar']} Bar (${results['mawpPsi']} PSI)', highlightColor: const Color(0xFF30D158)),
            _buildDataRow('ASME Hydrostatic Test Pressure (1.5x)', '${results['hydroTestBar']} Bar', highlightColor: const Color(0xFF0A84FF)),
            _buildDataRow('Mill Tolerance Deduction (-12.5%)', '${(thk * 0.125).toStringAsFixed(2)} mm'),
            _buildDataRow('Corrosion Allowance Included', '1.5 mm'),
            _buildDataRow('Minimum Net Structural Wall (t_min)', '${results['tMin']} mm'),
          ],
        ),
      );
    } else if (_category == ComponentCategory.flange) {
      final pRatings = PipingEngine.getFlangeRating(_subSelection, _selectedMaterial);
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
            _buildDataRow('Flange Hydrostatic Shell Test (1.5x)', '${pRatings['hydro']} Bar', highlightColor: const Color(0xFF0A84FF)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: const Text('Forged fittings rated equivalent to mating pipe schedule per ASME B16.11.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
            _buildDataRow('Flange Gasket Standard', 'ASME B16.20 Spiral Wound (316L/Graphite)'),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: const Text('Bolting calculations apply exclusively to ASME B16.5 Flange sets.', style: TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _buildDimensionsTab(Map<String, dynamic> item) {
    final Map<String, String> d = {};
    d['Nominal Pipe Size (NPS)'] = item['nps'] as String;
    d['Diameter Nominal'] = 'DN ${item['dn']}';

    if (_category == ComponentCategory.pipe) {
      final schs = item['schedules'] as Map<String, dynamic>;
      final s = schs[_subSelection] ?? schs.values.first;
      d['Outside Diameter (OD)'] = '${item['od']} mm';
      d['Schedule / Thickness Class'] = _subSelection;
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
      d['Expansion Fit-up Gap'] = '1.6 mm (1/16")';
    } else if (_category == ComponentCategory.threaded) {
      d['Threads per Inch (TPI)'] = '${item['tpi']}';
      d['Thread Pitch (p)'] = '${item['pitch']} mm';
      d['Effective Thread Length (L2)'] = '${item['minThreadL2']} mm';
      d['Standard Taper Ratio'] = '${item['taper']}';
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
