import 'package:flutter/material.dart';
import 'core/models.dart';
import 'painters/schematic_painter.dart';

void main() => runApp(const ApplePipingApp());

class ApplePipingApp extends StatelessWidget {
  const ApplePipingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piping Data Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED True Black
        primaryColor: const Color(0xFF0A84FF),
        cardColor: const Color(0xFF1C1C1E),
        fontFamily: 'SF Pro Display',
      ),
      home: const WorkstationView(),
    );
  }
}

class WorkstationView extends StatefulWidget {
  const WorkstationView({super.key});

  @override
  State<WorkstationView> createState() => _WorkstationViewState();
}

class _WorkstationViewState extends State<WorkstationView> {
  ComponentCategory _category = ComponentCategory.pipe;
  int _selectedSizeIndex = 4; // NPS 2" پیش‌فرض
  String _selectedSubOption = 'Sch 40 (STD)';

  List<ComponentMetric> get _currentList {
    switch (_category) {
      case ComponentCategory.pipe:
        return PipingDatabase.pipes;
      case ComponentCategory.flange:
        return PipingDatabase.flanges;
      case ComponentCategory.buttWeld:
        return PipingDatabase.buttWelds;
      case ComponentCategory.socketWeld:
        return PipingDatabase.socketWelds;
      case ComponentCategory.threaded:
        return PipingDatabase.threadeds;
    }
  }

  void _updateSubOption() {
    final item = _currentList[_selectedSizeIndex];
    if (_category == ComponentCategory.pipe) {
      final schs = (item.data['schedules'] as Map<String, dynamic>).keys.toList();
      if (!schs.contains(_selectedSubOption)) _selectedSubOption = schs.contains('Sch 40 (STD)') ? 'Sch 40 (STD)' : schs.first;
    } else if (_category == ComponentCategory.flange) {
      final clss = (item.data['classes'] as Map<String, dynamic>).keys.toList();
      if (!clss.contains(_selectedSubOption)) _selectedSubOption = clss.contains('Class 150') ? 'Class 150' : clss.first;
    } else {
      _selectedSubOption = '';
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSubOption();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSizeIndex >= _currentList.length) _selectedSizeIndex = 0;
    final item = _currentList[_selectedSizeIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppleHeader(),
            _buildSegmentedCategoryControl(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _buildSizeSlider(item),
                  if (_category == ComponentCategory.pipe || _category == ComponentCategory.flange)
                    _buildSubOptionSelector(item),
                  const SizedBox(height: 12),
                  _buildSchematicView(item),
                  const SizedBox(height: 14),
                  _buildAppleMetricsGrid(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Piping Data Pro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
              SizedBox(height: 2),
              Text('ASME INDUSTRIAL WORKSTATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93), letterSpacing: 0.8)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 12),
                SizedBox(width: 5),
                Text('ASME VERIFIED', style: TextStyle(fontSize: 10, color: Color(0xFF30D158), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedCategoryControl() {
    final categories = [
      {'label': 'Pipes', 'cat': ComponentCategory.pipe},
      {'label': 'Flanges', 'cat': ComponentCategory.flange},
      {'label': 'Butt-Weld', 'cat': ComponentCategory.buttWeld},
      {'label': 'Socket-Weld', 'cat': ComponentCategory.socketWeld},
      {'label': 'Threaded', 'cat': ComponentCategory.threaded},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: categories.map((c) {
          final isSelected = _category == c['cat'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _category = c['cat'] as ComponentCategory;
                  _selectedSizeIndex = 0;
                  _updateSubOption();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSizeSlider(ComponentMetric item) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _currentList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedSizeIndex == i;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSizeIndex = i;
                _updateSubOption();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2C2C2E)),
              ),
              child: Text(
                '${_currentList[i].nps} (DN ${_currentList[i].dn})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubOptionSelector(ComponentMetric item) {
    List<String> options = [];
    if (_category == ComponentCategory.pipe) {
      options = (item.data['schedules'] as Map<String, dynamic>).keys.toList();
    } else if (_category == ComponentCategory.flange) {
      options = (item.data['classes'] as Map<String, dynamic>).keys.toList();
    }

    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opt = options[i];
          final isSelected = _selectedSubOption == opt;
          return GestureDetector(
            onTap: () => setState(() => _selectedSubOption = opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF8E8E93)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchematicView(ComponentMetric item) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CROSS-SECTION CAD SCHEMATIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93), letterSpacing: 0.5)),
              Text(item.data['std'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9F0A))),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(240, 160),
                painter: SchematicPainter(category: _category, metric: item, subTypeKey: _selectedSubOption),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleMetricsGrid(ComponentMetric item) {
    final Map<String, String> displayMap = {};

    displayMap['Nominal Pipe Size'] = item.nps;
    displayMap['Diameter Nominal'] = 'DN ${item.dn}';
    displayMap['Outside Diameter (OD)'] = '${item.od} mm';
    displayMap['Standard Specification'] = item.data['std'] as String;

    if (_category == ComponentCategory.pipe) {
      final schMap = (item.data['schedules'] as Map<String, dynamic>)[_selectedSubOption] ?? {};
      displayMap['Active Schedule'] = _selectedSubOption;
      displayMap['Wall Thickness (t)'] = '${schMap['thk']} mm';
      displayMap['Inside Diameter (ID)'] = '${schMap['id']} mm';
      displayMap['Weight per Meter'] = '${schMap['wt']} kg/m';
    } else if (_category == ComponentCategory.flange) {
      final clsMap = (item.data['classes'] as Map<String, dynamic>)[_selectedSubOption] ?? {};
      displayMap['Pressure Rating'] = _selectedSubOption;
      displayMap['Flange Thickness (C)'] = '${clsMap['thk']} mm';
      displayMap['Pitch Circle Dia (PCD)'] = '${clsMap['pcd']} mm';
      displayMap['Bolt Holes Quantity'] = '${clsMap['bolts']}';
      displayMap['Bolt Stud Diameter'] = '${clsMap['boltDia']}';
      displayMap['Length Thru Hub'] = '${clsMap['len']} mm';
    } else if (_category == ComponentCategory.buttWeld) {
      displayMap['90° LR Center-to-End'] = '${item.data['elbow90LR']} mm';
      displayMap['90° SR Center-to-End'] = '${item.data['elbow90SR']} mm';
      displayMap['45° Elbow Center-to-End'] = '${item.data['elbow45']} mm';
      displayMap['Equal Tee Center-to-End'] = '${item.data['teeCtoE']} mm';
      displayMap['Reducer Length (H)'] = '${item.data['reducerH']} mm';
    } else if (_category == ComponentCategory.socketWeld) {
      displayMap['Socket Bore Diameter'] = '${item.data['bore']} mm';
      displayMap['Socket Minimum Depth'] = '${item.data['depth']} mm';
      displayMap['Center-to-End Fitting'] = '${item.data['cToE']} mm';
      displayMap['Minimum Wall (G)'] = '${item.data['minWall']} mm';
      displayMap['Thermal Fit-up Gap'] = '${item.data['gap']} mm';
    } else if (_category == ComponentCategory.threaded) {
      displayMap['Threads per Inch (TPI)'] = '${item.data['tpi']}';
      displayMap['Effective Thread (L2)'] = '${item.data['minThreadL2']} mm';
      displayMap['Center-to-End Fitting'] = '${item.data['cToE']} mm';
      displayMap['Thread Form & Taper'] = 'NPT 1:16 Taper';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        children: displayMap.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500)),
                Text(entry.value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
