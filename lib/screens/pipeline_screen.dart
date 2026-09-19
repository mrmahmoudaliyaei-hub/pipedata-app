import 'package:flutter/cupertino.dart';
import '../core/models.dart';
import '../core/units.dart';
import '../painters/schematic_painter.dart';

/// ASME B31.4 liquid transport pipeline MAOP calculator. Reuses the same
/// B36.10M pipe OD/schedule dataset as the Pipes category, but computes
/// MAOP with the Barlow formula + 0.72 design factor (see
/// PipelineTransportEngine — this constant is safety-critical and mirrors
/// the PipelineEngineerPro project's own 0.72 design factor).
class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  int _sizeIdx = 4; // 2"
  String _schedule = 'Sch 40 (STD)';
  PipelineGrade _grade = PipelineGrade.x52;

  List<Map<String, dynamic>> get _dataset => PipingMasterCatalog.pipes;

  void _syncSchedule() {
    final schs = (_dataset[_sizeIdx]['schedules'] as Map<String, dynamic>).keys.toList();
    if (!schs.contains(_schedule)) _schedule = schs.contains('Sch 40 (STD)') ? 'Sch 40 (STD)' : schs.first;
  }

  static const Map<PipelineGrade, String> _gradeLabels = {
    PipelineGrade.gradeB: 'API 5L Grade B',
    PipelineGrade.x42: 'API 5L X42',
    PipelineGrade.x52: 'API 5L X52',
    PipelineGrade.x60: 'API 5L X60',
    PipelineGrade.x65: 'API 5L X65',
    PipelineGrade.x70: 'API 5L X70',
  };

  @override
  Widget build(BuildContext context) {
    final item = _dataset[_sizeIdx];
    final schs = item['schedules'] as Map<String, dynamic>;
    final currentSch = schs[_schedule] ?? schs.values.first;
    final od = (item['od'] as num).toDouble();
    final thk = (currentSch['thk'] as num).toDouble();
    final res = PipelineTransportEngine.calculateMAOP(outerDiameterMm: od, nominalWallThkMm: thk, grade: _grade);

    return ValueListenableBuilder<LengthUnit>(
      valueListenable: unitsController,
      builder: (context, _, __) => _buildScaffold(context, item, od, thk, res),
    );
  }

  Widget _buildScaffold(BuildContext context, Map<String, dynamic> item, double od, double thk, PipelineCalculationResult res) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xF0161618),
        middle: const Text('Pipeline (Transport)'),
        trailing: _buildUnitToggle(),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C2C2E)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.drop, color: Color(0xFFFF453A), size: 12),
                      SizedBox(width: 5),
                      Text('ASME B31.4', style: TextStyle(fontSize: 10, color: Color(0xFFFF453A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _sectionLabel('LINE PIPE SIZE'),
            _buildSizeChips(),
            _sectionLabel('WALL SCHEDULE'),
            _buildScheduleChips(item),
            _sectionLabel('LINE PIPE GRADE (API 5L)'),
            _buildGradeChips(),
            const SizedBox(height: 8),
            _buildSchematicCard(item),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2C2C2E))),
              child: Column(
                children: [
                  _dataRow('Maximum Allowable Operating Pressure (MAOP)', '${res.maopBar} Bar (${res.maopPsi} PSI)', highlight: const Color(0xFF30D158)),
                  _dataRow('Hydrostatic Test Pressure (1.25x MAOP)', '${res.hydroTestBar} Bar (${res.hydroTestPsi} PSI)', highlight: const Color(0xFF0A84FF)),
                  _dataRow('SMYS ($_gradeLabelText)', '${res.smysMpa.toStringAsFixed(0)} MPa'),
                  _dataRow('Design Factor (F)', res.designFactor.toStringAsFixed(2), highlight: const Color(0xFFFF453A)),
                  _dataRow('Outside Diameter (D)', unitsController.format(od)),
                  _dataRow('Nominal Wall Thickness (t)', unitsController.format(thk)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF161618), borderRadius: BorderRadius.circular(14)),
              child: const Text(
                'P = (2 · S · t · F) / D — ASME B31.4 §403.2.1 (Barlow\'s formula). '
                'The 0.72 design factor is a fixed safety constant for liquid transport pipelines; '
                'treat any change to it, or to this formula, as requiring engineering sign-off before use in a real design — '
                'the same convention used in the PipelineEngineerPro project.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _gradeLabelText => _gradeLabels[_grade]!;

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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF453A)),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.6)),
    );
  }

  Widget _buildSizeChips() {
    return SizedBox(
      height: 42,
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
              _syncSchedule();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? CupertinoColors.white : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? CupertinoColors.white : const Color(0xFF2C2C2E)),
              ),
              child: Text(
                '${_dataset[i]['nps']} (DN ${_dataset[i]['dn']})',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? CupertinoColors.black : CupertinoColors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleChips(Map<String, dynamic> item) {
    final opts = (item['schedules'] as Map<String, dynamic>).keys.toList();
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSel = _schedule == opts[i];
          return GestureDetector(
            onTap: () => setState(() => _schedule = opts[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFFF453A) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(opts[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeChips() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gradeLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final grade = _gradeLabels.keys.elementAt(i);
          final isSel = _grade == grade;
          return GestureDetector(
            onTap: () => setState(() => _grade = grade),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFFF453A) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_gradeLabels[grade]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? CupertinoColors.white : const Color(0xFF8E8E93))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchematicCard(Map<String, dynamic> item) {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CROSS-SECTION ENGINEERING BLUEPRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.6)),
              Text('CAD VECTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9F0A))),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(260, 150),
                painter: VectorBlueprintPainter(category: ComponentCategory.pipelineTransport, data: item, subType: _schedule, accentColor: const Color(0xFFFF453A)),
              ),
            ),
          ),
        ],
      ),
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
