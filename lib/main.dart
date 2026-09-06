import 'package:flutter/material.dart';
import 'core/models.dart';
import 'painters/schematic_painter.dart';

void main() => runApp(const PipingApp());

class PipingApp extends StatelessWidget {
  const PipingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const IndustrialDashboard(),
    );
  }
}

class IndustrialDashboard extends StatefulWidget {
  const IndustrialDashboard({super.key});

  @override
  State<IndustrialDashboard> createState() => _IndustrialDashboardState();
}

class _IndustrialDashboardState extends State<IndustrialDashboard> {
  ComponentCategory _category = ComponentCategory.pipe;
  int _selectedIndex = 2;

  final Map<ComponentCategory, List<ComponentRecord>> _data = {
    ComponentCategory.pipe: [
      ComponentRecord(nps: '1/2"', dn: 15, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 21.3, 'sch': '40', 'thk': 2.77, 'id': 15.8, 'wt': 1.27}),
      ComponentRecord(nps: '3/4"', dn: 20, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 26.7, 'sch': '40', 'thk': 2.87, 'id': 20.93, 'wt': 1.69}),
      ComponentRecord(nps: '1"', dn: 25, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 33.4, 'sch': '40', 'thk': 3.38, 'id': 26.64, 'wt': 2.50}),
      ComponentRecord(nps: '2"', dn: 50, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 60.3, 'sch': '40', 'thk': 3.91, 'id': 52.51, 'wt': 5.44}),
      ComponentRecord(nps: '3"', dn: 80, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 88.9, 'sch': '40', 'thk': 5.49, 'id': 77.92, 'wt': 11.29}),
      ComponentRecord(nps: '4"', dn: 100, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 114.3, 'sch': '40', 'thk': 6.02, 'id': 102.26, 'wt': 16.07}),
      ComponentRecord(nps: '6"', dn: 150, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 168.3, 'sch': '40', 'thk': 7.11, 'id': 154.08, 'wt': 28.26}),
      ComponentRecord(nps: '8"', dn: 200, standard: 'ASME B36.10M', typeName: 'Pipe', metrics: {'od': 219.1, 'sch': '40', 'thk': 8.18, 'id': 202.74, 'wt': 42.55}),
    ],
    ComponentCategory.flange: [
      ComponentRecord(nps: '1/2"', dn: 15, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 89.0, 'pcd': 60.3, 'bolts': 4, 'boltDia': 15.9, 'thk': 11.1}),
      ComponentRecord(nps: '3/4"', dn: 20, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 98.0, 'pcd': 69.9, 'bolts': 4, 'boltDia': 15.9, 'thk': 12.7}),
      ComponentRecord(nps: '1"', dn: 25, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 108.0, 'pcd': 79.4, 'bolts': 4, 'boltDia': 15.9, 'thk': 14.3}),
      ComponentRecord(nps: '2"', dn: 50, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 152.0, 'pcd': 120.7, 'bolts': 4, 'boltDia': 19.1, 'thk': 19.1}),
      ComponentRecord(nps: '3"', dn: 80, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 190.0, 'pcd': 152.4, 'bolts': 4, 'boltDia': 19.1, 'thk': 23.8}),
      ComponentRecord(nps: '4"', dn: 100, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 229.0, 'pcd': 190.5, 'bolts': 8, 'boltDia': 19.1, 'thk': 23.8}),
      ComponentRecord(nps: '6"', dn: 150, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 279.0, 'pcd': 241.3, 'bolts': 8, 'boltDia': 22.2, 'thk': 25.4}),
      ComponentRecord(nps: '8"', dn: 200, standard: 'ASME B16.5', typeName: 'Flange', metrics: {'class': 150, 'od': 343.0, 'pcd': 298.5, 'bolts': 8, 'boltDia': 22.2, 'thk': 28.6}),
    ],
    ComponentCategory.buttWeld: [
      ComponentRecord(nps: '1/2"', dn: 15, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 38.0, 'elbow90SR': 25.4, 'teeCenter': 25.0, 'reducerH': 38.0}),
      ComponentRecord(nps: '1"', dn: 25, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 38.0, 'elbow90SR': 25.4, 'teeCenter': 38.0, 'reducerH': 51.0}),
      ComponentRecord(nps: '2"', dn: 50, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 76.0, 'elbow90SR': 51.0, 'teeCenter': 64.0, 'reducerH': 76.0}),
      ComponentRecord(nps: '3"', dn: 80, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 114.0, 'elbow90SR': 76.0, 'teeCenter': 86.0, 'reducerH': 89.0}),
      ComponentRecord(nps: '4"', dn: 100, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 152.0, 'elbow90SR': 102.0, 'teeCenter': 105.0, 'reducerH': 102.0}),
      ComponentRecord(nps: '6"', dn: 150, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 229.0, 'elbow90SR': 152.0, 'teeCenter': 143.0, 'reducerH': 140.0}),
      ComponentRecord(nps: '8"', dn: 200, standard: 'ASME B16.9', typeName: 'BW Elbow', metrics: {'elbow90LR': 305.0, 'elbow90SR': 203.0, 'teeCenter': 178.0, 'reducerH': 152.0}),
    ],
    ComponentCategory.socketWeld: [
      ComponentRecord(nps: '1/2"', dn: 15, standard: 'ASME B16.11', typeName: 'SW Fitting', metrics: {'bore': 21.8, 'depth': 9.5, 'cToE': 24.5, 'gap': 1.6}),
      ComponentRecord(nps: '3/4"', dn: 20, standard: 'ASME B16.11', typeName: 'SW Fitting', metrics: {'bore': 27.2, 'depth': 12.5, 'cToE': 28.5, 'gap': 1.6}),
      ComponentRecord(nps: '1"', dn: 25, standard: 'ASME B16.11', typeName: 'SW Fitting', metrics: {'bore': 33.9, 'depth': 12.5, 'cToE': 34.0, 'gap': 1.6}),
      ComponentRecord(nps: '2"', dn: 50, standard: 'ASME B16.11', typeName: 'SW Fitting', metrics: {'bore': 61.2, 'depth': 16.0, 'cToE': 47.5, 'gap': 1.6}),
    ],
    ComponentCategory.threaded: [
      ComponentRecord(nps: '1/2"', dn: 15, standard: 'ASME B16.11 / NPT', typeName: 'THD Elbow', metrics: {'cToE': 25.0, 'minThreadL2': 13.5, 'tpi': 14}),
      ComponentRecord(nps: '3/4"', dn: 20, standard: 'ASME B16.11 / NPT', typeName: 'THD Elbow', metrics: {'cToE': 28.5, 'minThreadL2': 14.0, 'tpi': 14}),
      ComponentRecord(nps: '1"', dn: 25, standard: 'ASME B16.11 / NPT', typeName: 'THD Elbow', metrics: {'cToE': 34.0, 'minThreadL2': 17.5, 'tpi': 11.5}),
      ComponentRecord(nps: '2"', dn: 50, standard: 'ASME B16.11 / NPT', typeName: 'THD Elbow', metrics: {'cToE': 52.5, 'minThreadL2': 19.5, 'tpi': 11.5}),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final list = _data[_category]!;
    if (_selectedIndex >= list.length) _selectedIndex = 0;
    final item = list[_selectedIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSizeSelector(list),
                  const SizedBox(height: 14),
                  _buildSchematicCard(item),
                  const SizedBox(height: 14),
                  _buildMetricsCard(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Piping Data Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
            child: const Text('ASME INDUSTRIAL', style: TextStyle(fontSize: 10, color: Color(0xFF30D158), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = [
      {'label': 'Pipes', 'cat': ComponentCategory.pipe},
      {'label': 'Flanges', 'cat': ComponentCategory.flange},
      {'label': 'Butt-Weld', 'cat': ComponentCategory.buttWeld},
      {'label': 'Socket-Weld', 'cat': ComponentCategory.socketWeld},
      {'label': 'Threaded', 'cat': ComponentCategory.threaded},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _category == tabs[i]['cat'];
          return GestureDetector(
            onTap: () => setState(() { _category = tabs[i]['cat'] as ComponentCategory; _selectedIndex = 0; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2C2C2E) : const Color(0xFF161618),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(tabs[i]['label'] as String, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeSelector(List<ComponentRecord> list) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _selectedIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${list[i].nps} (DN ${list[i].dn})', style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchematicCard(ComponentRecord item) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CROSS-SECTION SCHEMATIC', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
              Text(item.standard, style: const TextStyle(fontSize: 10, color: Color(0xFFFF9F0A), fontWeight: FontWeight.bold)),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(220, 140),
                painter: ComponentSchematicPainter(category: _category, record: item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(ComponentRecord item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: item.metrics.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text('${e.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
