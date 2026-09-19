import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

enum ComponentCategory {
  pipe,
  flange,
  socketWeld,
  threaded,
  reducer,
  gasket,
  valve,
  tee,
  elbow,
  cap,
  weldolet,
  sockolet,
  threadolet,
  pipelineTransport,
}

enum MaterialGrade { a106B, a312Tp316L, a333Gr6 }

/// API Spec 5L line-pipe grades used for ASME B31.4 transport-pipeline MAOP.
enum PipelineGrade { gradeB, x42, x52, x60, x65, x70 }

class PressureCalculationResult {
  final double mawpBar;
  final double mawpPsi;
  final double hydroTestBar;
  final double hydroTestPsi;
  final double netTMin;
  final double allowableStressMpa;

  const PressureCalculationResult({
    required this.mawpBar,
    required this.mawpPsi,
    required this.hydroTestBar,
    required this.hydroTestPsi,
    required this.netTMin,
    required this.allowableStressMpa,
  });
}

class PipelineCalculationResult {
  final double maopBar;
  final double maopPsi;
  final double hydroTestBar;
  final double hydroTestPsi;
  final double smysMpa;
  final double designFactor;

  const PipelineCalculationResult({
    required this.maopBar,
    required this.maopPsi,
    required this.hydroTestBar,
    required this.hydroTestPsi,
    required this.smysMpa,
    required this.designFactor,
  });
}

class PipingStressEngine {
  /// ASME B31.3 Section 304.1.2 Internal Design Pressure Equation:
  /// P = (2 * S * E * W * t) / (D - 2 * Y * t)
  /// t = nominalThk * (1 - millTolerance) - corrosionAllowance
  static PressureCalculationResult calculatePipeMAWP({
    required double outerDiameterMm,
    required double nominalWallThkMm,
    required MaterialGrade material,
    double designTempC = 38.0,
    double corrosionAllowanceMm = 1.5,
    double millToleranceRatio = 0.125, // 12.5% ASTM standard manufacturing tolerance
    double weldJointEfficiency = 1.0,  // Seamless (E = 1.00)
  }) {
    // S: Basic Allowable Stress in MPa (ASME B31.3 Table A-1)
    double sMpa;
    switch (material) {
      case MaterialGrade.a106B:
        sMpa = 138.0;
        if (designTempC > 93) sMpa = 138.0 - ((designTempC - 93) * 0.05);
        if (designTempC > 200) sMpa = 120.0;
        if (designTempC > 300) sMpa = 105.0;
        break;
      case MaterialGrade.a312Tp316L:
        sMpa = 115.0;
        if (designTempC > 100) sMpa = 102.0;
        if (designTempC > 200) sMpa = 91.0;
        if (designTempC > 300) sMpa = 82.0;
        break;
      case MaterialGrade.a333Gr6:
        sMpa = 138.0;
        break;
    }

    const double yFactor = 0.4; // Valid for ferritic/austenitic below 482 C
    const double wFactor = 1.0; // Weld strength reduction factor (1.0 for temp < 510 C)

    // Structural wall thickness available
    double tNet = (nominalWallThkMm * (1.0 - millToleranceRatio)) - corrosionAllowanceMm;
    if (tNet < 0.2) tNet = 0.2;

    double pMpa = (2 * sMpa * weldJointEfficiency * wFactor * tNet) /
        (outerDiameterMm - (2 * yFactor * tNet));
    if (pMpa < 0) pMpa = 0;

    double pBar = pMpa * 10.0;
    double pPsi = pBar * 14.50377;
    double hydroBar = pBar * 1.5; // ASME B31.3 Para 345.4.2 Hydrostatic Test: 1.5 * Design Pressure
    double hydroPsi = hydroBar * 14.50377;

    return PressureCalculationResult(
      mawpBar: double.parse(pBar.toStringAsFixed(1)),
      mawpPsi: double.parse(pPsi.toStringAsFixed(0)),
      hydroTestBar: double.parse(hydroBar.toStringAsFixed(1)),
      hydroTestPsi: double.parse(hydroPsi.toStringAsFixed(0)),
      netTMin: double.parse(tNet.toStringAsFixed(2)),
      allowableStressMpa: double.parse(sMpa.toStringAsFixed(1)),
    );
  }

  /// ASME B16.5 Table 2-1.1 Pressure-Temperature Containment Ratings (Group 1.1 - Carbon Steel A105)
  static Map<String, dynamic> getFlangePressureContainment(String ratingClass) {
    final Map<String, Map<String, double>> ratings = {
      'Class 150': {'ambient': 19.6, 't100': 17.7, 't200': 13.8, 't300': 10.2, 't400': 6.5, 'hydroShell': 29.5},
      'Class 300': {'ambient': 51.1, 't100': 46.6, 't200': 43.8, 't300': 39.8, 't400': 34.7, 'hydroShell': 77.0},
      'Class 600': {'ambient': 102.1, 't100': 93.2, 't200': 87.6, 't300': 79.7, 't400': 69.4, 'hydroShell': 153.5},
      'Class 900': {'ambient': 153.2, 't100': 139.8, 't200': 131.4, 't300': 119.5, 't400': 104.2, 'hydroShell': 230.0},
      'Class 1500': {'ambient': 255.3, 't100': 233.0, 't200': 219.0, 't300': 199.2, 't400': 173.6, 'hydroShell': 383.5},
      'Class 2500': {'ambient': 425.5, 't100': 388.3, 't200': 364.9, 't300': 331.9, 't400': 289.4, 'hydroShell': 638.5},
    };
    return ratings[ratingClass] ?? ratings['Class 150']!;
  }
}

/// ASME B31.4 "Pipeline Transportation Systems for Liquids and Slurries".
///
/// SAFETY-CRITICAL: the 0.72 design factor (F) below is the ASME B31.4 base
/// design factor for liquid transport pipelines (Table 403.2.1). This
/// constant, and the Barlow formula it feeds, should be treated like any
/// other safety-factor change — do not alter it without engineering
/// sign-off; it mirrors the same 0.72 factor already used in the
/// PipelineEngineerPro project.
class PipelineTransportEngine {
  static const double designFactorF = 0.72;

  /// ASME B31.4 Para. 403.2.1 (Barlow's formula):
  /// P = (2 * S * t * F) / D
  /// P = MAOP, S = Specified Minimum Yield Strength (SMYS, API 5L), t = nominal
  /// wall thickness, D = outside diameter, F = design factor (0.72).
  static PipelineCalculationResult calculateMAOP({
    required double outerDiameterMm,
    required double nominalWallThkMm,
    required PipelineGrade grade,
  }) {
    // S: Specified Minimum Yield Strength (SMYS) in MPa, per API Spec 5L.
    double sMpa;
    switch (grade) {
      case PipelineGrade.gradeB:
        sMpa = 241.0;
        break;
      case PipelineGrade.x42:
        sMpa = 290.0;
        break;
      case PipelineGrade.x52:
        sMpa = 358.0;
        break;
      case PipelineGrade.x60:
        sMpa = 414.0;
        break;
      case PipelineGrade.x65:
        sMpa = 448.0;
        break;
      case PipelineGrade.x70:
        sMpa = 483.0;
        break;
    }

    double pMpa = (2 * sMpa * nominalWallThkMm * designFactorF) / outerDiameterMm;
    if (pMpa < 0) pMpa = 0;

    double pBar = pMpa * 10.0;
    double pPsi = pBar * 14.50377;
    // ASME B31.4 Para. 437.4.1 / 49 CFR 195: hydrostatic test at 1.25x MAOP for liquid pipelines.
    double hydroBar = pBar * 1.25;
    double hydroPsi = hydroBar * 14.50377;

    return PipelineCalculationResult(
      maopBar: double.parse(pBar.toStringAsFixed(1)),
      maopPsi: double.parse(pPsi.toStringAsFixed(0)),
      hydroTestBar: double.parse(hydroBar.toStringAsFixed(1)),
      hydroTestPsi: double.parse(hydroPsi.toStringAsFixed(0)),
      smysMpa: sMpa,
      designFactor: designFactorF,
    );
  }
}

class PipingMasterCatalog {
  // Complete ASME B36.10M / B36.19M Pipes Dataset (NPS 1/2" up to NPS 24")
  static List<Map<String, dynamic>> pipes = [];  // populated by loadAll();

  // ASME B16.5 Weld Neck Raised Face (WNRF) Flanges
  // TODO(data-audit): the 'torqueNm' values below do not progress monotonically
  // with size/class in several rows (e.g. 1/2" Class150=45 -> 3/4" Class150=435
  // -> 1" Class150=55) — this is inconsistent with real bolt-torque tables and
  // should NOT be relied on for actual bolting work until re-derived from a
  // verified source (e.g. manufacturer torque charts or a proper stress-based
  // calc from bolt size/stud material). Flagging rather than guessing new
  // numbers, since bolt torque is safety-relevant.
  static List<Map<String, dynamic>> flanges = [];  // populated by loadAll();

  // ASME B16.11 Forged Socket-Weld Class 3000 / 6000
  static List<Map<String, dynamic>> socketWelds = [];  // populated by loadAll();

  // ASME B16.11 / NPT Forged Threaded Class 3000
  static List<Map<String, dynamic>> threadeds = [];  // populated by loadAll();

  // ASME B16.9 Concentric & Eccentric Reducers - Center-to-End Length (H)
  // H is identical for concentric and eccentric patterns at a given large-NPS x small-NPS pair.
  // TODO(data-audit): '20" x 16"' and '24" x 20"' both list H=508.0mm below.
  // Could not confirm the correct 24"x20" value against an authoritative
  // ASME B16.9 table in this session — verify before relying on it; it is
  // unusual (though not impossible) for two different reduction pairs to
  // share an identical length.
  static List<Map<String, dynamic>> reducers = [];  // populated by loadAll();

  // ASME B16.20 Spiral Wound Gaskets (CG style, no inner ring) - sealing-element ID/OD by Class
  static List<Map<String, dynamic>> gaskets = [];  // populated by loadAll();

  // ASME B16.10 Flanged Valve Face-to-Face, by valve type (Gate/Ball share the
  // short/long pattern per class; Globe and Swing Check share the B16.10 long pattern).
  static List<Map<String, dynamic>> valves = [];  // populated by loadAll();

  // ASME B16.9 Equal Tees - Center-to-End (C)
  static List<Map<String, dynamic>> tees = [];  // populated by loadAll();

  // ASME B16.9 Butt-Weld Elbows - Center-to-End by pattern (90 LR / 90 SR / 45)
  static List<Map<String, dynamic>> elbows = [];  // populated by loadAll();

  // ASME B16.9 Butt-Weld Caps - Length (E)
  static List<Map<String, dynamic>> caps = [];  // populated by loadAll();

  // MSS SP-97 Weldolets, size-on-size, Standard Weight - Height (A, from run pipe OD to top face)
  static List<Map<String, dynamic>> weldolets = [];  // populated by loadAll();

  // MSS SP-97 Sockolets, size-on-size, Class 3000 - Height (A) and socket depth (E)
  static List<Map<String, dynamic>> sockolets = [];  // populated by loadAll();

  // MSS SP-97 Threadolets, size-on-size, Class 3000 - Height (A)
  static List<Map<String, dynamic>> threadolets = [];  // populated by loadAll();

  static bool _loaded = false;

  /// Loads every dataset above from assets/data/*.json.
  ///
  /// Call this once, before runApp() (see main.dart) — every screen in this
  /// app reads these fields synchronously, so they all have to be populated
  /// before the widget tree that uses them is built. Safe to call more than
  /// once; later calls are a no-op.
  static Future<void> loadAll() async {
    if (_loaded) return;
    pipes = await _loadList('pipes');
    flanges = await _loadList('flanges');
    socketWelds = await _loadList('socketWelds');
    threadeds = await _loadList('threadeds');
    reducers = await _loadList('reducers');
    gaskets = await _loadList('gaskets');
    valves = await _loadList('valves');
    tees = await _loadList('tees');
    elbows = await _loadList('elbows');
    caps = await _loadList('caps');
    weldolets = await _loadList('weldolets');
    sockolets = await _loadList('sockolets');
    threadolets = await _loadList('threadolets');
    _loaded = true;
  }

  static Future<List<Map<String, dynamic>>> _loadList(String assetName) async {
    final raw = await rootBundle.loadString('assets/data/$assetName.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
