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
  static final List<Map<String, dynamic>> pipes = [
    {
      'nps': '1/2"', 'dn': 15, 'od': 21.34,
      'schedules': {
        'Sch 10': {'thk': 2.11, 'id': 17.12, 'wt': 1.00},
        'Sch 40 (STD)': {'thk': 2.77, 'id': 15.80, 'wt': 1.27},
        'Sch 80 (XS)': {'thk': 3.73, 'id': 13.88, 'wt': 1.62},
        'Sch 160': {'thk': 4.78, 'id': 11.78, 'wt': 1.95},
        'XXS': {'thk': 7.47, 'id': 6.40, 'wt': 2.55},
      }
    },
    {
      'nps': '3/4"', 'dn': 20, 'od': 26.67,
      'schedules': {
        'Sch 10': {'thk': 2.11, 'id': 22.45, 'wt': 1.28},
        'Sch 40 (STD)': {'thk': 2.87, 'id': 20.93, 'wt': 1.69},
        'Sch 80 (XS)': {'thk': 3.91, 'id': 18.85, 'wt': 2.20},
        'Sch 160': {'thk': 5.56, 'id': 15.55, 'wt': 2.90},
        'XXS': {'thk': 7.82, 'id': 11.03, 'wt': 3.64},
      }
    },
    {
      'nps': '1"', 'dn': 25, 'od': 33.40,
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 27.86, 'wt': 2.09},
        'Sch 40 (STD)': {'thk': 3.38, 'id': 26.64, 'wt': 2.50},
        'Sch 80 (XS)': {'thk': 4.55, 'id': 24.30, 'wt': 3.24},
        'Sch 160': {'thk': 6.35, 'id': 20.70, 'wt': 4.24},
        'XXS': {'thk': 9.09, 'id': 15.22, 'wt': 5.46},
      }
    },
    {
      'nps': '1-1/2"', 'dn': 40, 'od': 48.26,
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 42.72, 'wt': 3.11},
        'Sch 40 (STD)': {'thk': 3.68, 'id': 40.90, 'wt': 4.05},
        'Sch 80 (XS)': {'thk': 5.08, 'id': 38.10, 'wt': 5.41},
        'Sch 160': {'thk': 7.14, 'id': 33.98, 'wt': 7.25},
        'XXS': {'thk': 10.15, 'id': 27.96, 'wt': 9.56},
      }
    },
    {
      'nps': '2"', 'dn': 50, 'od': 60.33,
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 54.79, 'wt': 3.93},
        'Sch 40 (STD)': {'thk': 3.91, 'id': 52.51, 'wt': 5.44},
        'Sch 80 (XS)': {'thk': 5.54, 'id': 49.25, 'wt': 7.48},
        'Sch 160': {'thk': 8.74, 'id': 42.85, 'wt': 11.11},
        'XXS': {'thk': 11.07, 'id': 38.19, 'wt': 13.44},
      }
    },
    {
      'nps': '3"', 'dn': 80, 'od': 88.90,
      'schedules': {
        'Sch 10': {'thk': 3.05, 'id': 82.80, 'wt': 6.46},
        'Sch 40 (STD)': {'thk': 5.49, 'id': 77.92, 'wt': 11.29},
        'Sch 80 (XS)': {'thk': 7.62, 'id': 73.66, 'wt': 15.27},
        'Sch 160': {'thk': 11.13, 'id': 66.64, 'wt': 21.35},
        'XXS': {'thk': 15.24, 'id': 58.42, 'wt': 27.68},
      }
    },
    {
      'nps': '4"', 'dn': 100, 'od': 114.30,
      'schedules': {
        'Sch 10': {'thk': 3.05, 'id': 108.20, 'wt': 8.37},
        'Sch 40 (STD)': {'thk': 6.02, 'id': 102.26, 'wt': 16.07},
        'Sch 80 (XS)': {'thk': 8.56, 'id': 97.18, 'wt': 22.32},
        'Sch 120': {'thk': 11.13, 'id': 92.04, 'wt': 28.32},
        'Sch 160': {'thk': 13.49, 'id': 87.32, 'wt': 33.54},
        'XXS': {'thk': 17.12, 'id': 80.06, 'wt': 41.03},
      }
    },
    {
      'nps': '5"', 'dn': 125, 'od': 141.30,
      'schedules': {
        'Sch 10': {'thk': 3.40, 'id': 134.50, 'wt': 11.56},
        'Sch 40 (STD)': {'thk': 6.55, 'id': 128.20, 'wt': 21.77},
        'Sch 80 (XS)': {'thk': 9.52, 'id': 122.26, 'wt': 30.94},
        'Sch 120': {'thk': 12.70, 'id': 115.90, 'wt': 40.28},
        'Sch 160': {'thk': 15.88, 'id': 109.54, 'wt': 49.11},
        'XXS': {'thk': 19.05, 'id': 103.20, 'wt': 57.43},
      }
    },
    {
      'nps': '6"', 'dn': 150, 'od': 168.28,
      'schedules': {
        'Sch 10': {'thk': 3.40, 'id': 161.48, 'wt': 13.82},
        'Sch 40 (STD)': {'thk': 7.11, 'id': 154.06, 'wt': 28.26},
        'Sch 80 (XS)': {'thk': 10.97, 'id': 146.34, 'wt': 42.56},
        'Sch 160': {'thk': 18.26, 'id': 131.76, 'wt': 67.56},
        'XXS': {'thk': 21.95, 'id': 124.38, 'wt': 79.22},
      }
    },
    {
      'nps': '8"', 'dn': 200, 'od': 219.08,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 206.38, 'wt': 33.31},
        'Sch 40 (STD)': {'thk': 8.18, 'id': 202.72, 'wt': 42.55},
        'Sch 80 (XS)': {'thk': 12.70, 'id': 193.68, 'wt': 64.64},
        'Sch 160': {'thk': 23.01, 'id': 173.06, 'wt': 111.27},
        'XXS': {'thk': 22.23, 'id': 174.62, 'wt': 107.92},
      }
    },
    {
      'nps': '10"', 'dn': 250, 'od': 273.05,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 260.35, 'wt': 41.77},
        'Sch 40 (STD)': {'thk': 9.27, 'id': 254.51, 'wt': 60.31},
        'Sch 80 (XS)': {'thk': 15.09, 'id': 242.87, 'wt': 95.97},
        'Sch 120': {'thk': 21.44, 'id': 230.17, 'wt': 133.06},
        'Sch 160': {'thk': 28.58, 'id': 215.89, 'wt': 172.26},
      }
    },
    {
      'nps': '12"', 'dn': 300, 'od': 323.85,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 311.15, 'wt': 49.73},
        'Sch 40 (STD)': {'thk': 10.31, 'id': 303.23, 'wt': 79.73},
        'Sch 80 (XS)': {'thk': 17.48, 'id': 288.89, 'wt': 132.08},
        'Sch 160': {'thk': 33.32, 'id': 257.21, 'wt': 238.68},
      }
    },
    {
      'nps': '14"', 'dn': 350, 'od': 355.60,
      'schedules': {
        'Sch 10': {'thk': 6.35, 'id': 342.90, 'wt': 54.69},
        'Sch 20': {'thk': 7.92, 'id': 339.76, 'wt': 67.90},
        'Sch 40 (STD)': {'thk': 11.13, 'id': 333.34, 'wt': 94.55},
        'Sch 80 (XS)': {'thk': 19.05, 'id': 317.50, 'wt': 158.10},
        'Sch 160': {'thk': 35.71, 'id': 284.18, 'wt': 281.70},
      }
    },
    {
      'nps': '16"', 'dn': 400, 'od': 406.40,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 393.70, 'wt': 62.64},
        'Sch 40 (STD)': {'thk': 12.70, 'id': 381.00, 'wt': 123.30},
        'Sch 80 (XS)': {'thk': 21.44, 'id': 363.52, 'wt': 203.53},
        'Sch 160': {'thk': 40.49, 'id': 325.42, 'wt': 365.36},
      }
    },
    {
      'nps': '18"', 'dn': 450, 'od': 457.20,
      'schedules': {
        'Sch 10': {'thk': 6.35, 'id': 444.50, 'wt': 70.60},
        'Sch 20': {'thk': 7.92, 'id': 441.36, 'wt': 87.75},
        'Sch 40 (STD)': {'thk': 14.27, 'id': 428.66, 'wt': 155.87},
        'Sch 80 (XS)': {'thk': 23.83, 'id': 409.54, 'wt': 254.67},
        'Sch 160': {'thk': 45.24, 'id': 366.72, 'wt': 459.59},
      }
    },
    {
      'nps': '20"', 'dn': 500, 'od': 508.00,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 495.30, 'wt': 78.55},
        'Sch 40 (STD)': {'thk': 15.09, 'id': 477.82, 'wt': 183.42},
        'Sch 80 (XS)': {'thk': 26.19, 'id': 455.62, 'wt': 311.17},
      }
    },
    {
      'nps': '22"', 'dn': 550, 'od': 558.80,
      'schedules': {
        'Sch 10': {'thk': 6.35, 'id': 546.10, 'wt': 86.51},
        'Std (Sch 20)': {'thk': 9.52, 'id': 539.76, 'wt': 128.95},
        'XS (Sch 30)': {'thk': 12.70, 'id': 533.40, 'wt': 171.03},
      }
    },
    {
      'nps': '24"', 'dn': 600, 'od': 609.60,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 596.90, 'wt': 94.46},
        'Sch 40 (STD)': {'thk': 17.48, 'id': 574.64, 'wt': 255.41},
        'Sch 80 (XS)': {'thk': 30.96, 'id': 547.68, 'wt': 441.97}, // FIXED: was 447.68 (typo — should be OD 609.60 - 2*30.96 = 547.68)
      }
    },
    {
      'nps': '26"', 'dn': 650, 'od': 660.40,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 644.56, 'wt': 127.43},
        'Std (Sch 20)': {'thk': 9.52, 'id': 641.36, 'wt': 152.80},
        'XS (Sch 30)': {'thk': 12.70, 'id': 635.00, 'wt': 202.85},
      }
    },
    {
      'nps': '28"', 'dn': 700, 'od': 711.20,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 695.36, 'wt': 137.36},
        'Std (Sch 20)': {'thk': 9.52, 'id': 692.16, 'wt': 164.73},
        'XS (Sch 30)': {'thk': 12.70, 'id': 685.80, 'wt': 218.76},
      }
    },
    {
      'nps': '30"', 'dn': 750, 'od': 762.00,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 746.16, 'wt': 147.28},
        'Std (Sch 20)': {'thk': 9.52, 'id': 742.96, 'wt': 176.65},
        'XS (Sch 30)': {'thk': 12.70, 'id': 736.60, 'wt': 234.67},
      }
    },
    {
      'nps': '32"', 'dn': 800, 'od': 812.80,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 796.96, 'wt': 157.20},
        'Std (Sch 20)': {'thk': 9.52, 'id': 793.76, 'wt': 188.58},
        'XS (Sch 30)': {'thk': 12.70, 'id': 787.40, 'wt': 250.58},
      }
    },
    {
      'nps': '34"', 'dn': 850, 'od': 863.60,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 847.76, 'wt': 167.12},
        'Std (Sch 20)': {'thk': 9.52, 'id': 844.56, 'wt': 200.51},
        'XS (Sch 30)': {'thk': 12.70, 'id': 838.20, 'wt': 266.49},
      }
    },
    {
      'nps': '36"', 'dn': 900, 'od': 914.40,
      'schedules': {
        'Sch 10': {'thk': 7.92, 'id': 898.56, 'wt': 177.04},
        'Std (Sch 20)': {'thk': 9.52, 'id': 895.36, 'wt': 212.43},
        'XS (Sch 30)': {'thk': 12.70, 'id': 889.00, 'wt': 282.40},
      }
    },
    {
      'nps': '42"', 'dn': 1050, 'od': 1066.80,
      'schedules': {
        'Std (Sch 20)': {'thk': 9.52, 'id': 1047.76, 'wt': 248.21},
        'XS (Sch 30)': {'thk': 12.70, 'id': 1041.40, 'wt': 330.13},
      }
    },
    {
      'nps': '48"', 'dn': 1200, 'od': 1219.20,
      'schedules': {
        'Std (Sch 20)': {'thk': 9.52, 'id': 1200.16, 'wt': 283.99},
        'XS (Sch 30)': {'thk': 12.70, 'id': 1193.80, 'wt': 377.85},
      }
    },
  ];

  // ASME B16.5 Weld Neck Raised Face (WNRF) Flanges
  // TODO(data-audit): the 'torqueNm' values below do not progress monotonically
  // with size/class in several rows (e.g. 1/2" Class150=45 -> 3/4" Class150=435
  // -> 1" Class150=55) — this is inconsistent with real bolt-torque tables and
  // should NOT be relied on for actual bolting work until re-derived from a
  // verified source (e.g. manufacturer torque charts or a proper stress-based
  // calc from bolt size/stud material). Flagging rather than guessing new
  // numbers, since bolt torque is safety-relevant.
  static final List<Map<String, dynamic>> flanges = [
    {
      'nps': '1/2"', 'dn': 15,
      'classes': {
        'Class 150': {'od': 89.0, 'thk': 11.1, 'pcd': 60.3, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 60, 'torqueNm': 45},
        'Class 300': {'od': 95.0, 'thk': 14.3, 'pcd': 66.7, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 65, 'torqueNm': 55},
        'Class 600': {'od': 95.0, 'thk': 14.3, 'pcd': 66.7, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 75, 'torqueNm': 65},
        'Class 900': {'od': 120.0, 'thk': 22.2, 'pcd': 82.6, 'bolts': 4, 'boltSize': '3/4"', 'studLen': 110, 'torqueNm': 130},
        'Class 1500': {'od': 120.0, 'thk': 22.2, 'pcd': 82.6, 'bolts': 4, 'boltSize': '3/4"', 'studLen': 110, 'torqueNm': 130},
        'Class 2500': {'od': 135.0, 'thk': 30.2, 'pcd': 88.9, 'bolts': 4, 'boltSize': '3/4"', 'studLen': 120, 'torqueNm': 150},
      }
    },
    {
      'nps': '3/4"', 'dn': 20,
      'classes': {
        'Class 150': {'od': 98.6, 'thk': 12.7, 'pcd': 69.8, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 94, 'torqueNm': 435},
        'Class 300': {'od': 117.3, 'thk': 15.7, 'pcd': 82.5, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 116, 'torqueNm': 625},
        'Class 600': {'od': 117.3, 'thk': 15.7, 'pcd': 82.5, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 141, 'torqueNm': 825},
      }
    },
    {
      'nps': '1"', 'dn': 25,
      'classes': {
        'Class 150': {'od': 108.0, 'thk': 14.3, 'pcd': 79.4, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 65, 'torqueNm': 55},
        'Class 300': {'od': 125.0, 'thk': 17.5, 'pcd': 88.9, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 75, 'torqueNm': 110},
        'Class 600': {'od': 125.0, 'thk': 17.5, 'pcd': 88.9, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 85, 'torqueNm': 120},
        'Class 900': {'od': 150.0, 'thk': 28.6, 'pcd': 101.6, 'bolts': 4, 'boltSize': '7/8"', 'studLen': 125, 'torqueNm': 220},
        'Class 1500': {'od': 150.0, 'thk': 28.6, 'pcd': 101.6, 'bolts': 4, 'boltSize': '7/8"', 'studLen': 125, 'torqueNm': 220},
        'Class 2500': {'od': 160.0, 'thk': 35.0, 'pcd': 108.0, 'bolts': 4, 'boltSize': '7/8"', 'studLen': 140, 'torqueNm': 240},
      }
    },
    {
      'nps': '1-1/2"', 'dn': 40,
      'classes': {
        'Class 150': {'od': 127.0, 'thk': 17.5, 'pcd': 98.6, 'bolts': 4, 'boltSize': '1/2"', 'studLen': 104, 'torqueNm': 526},
        'Class 300': {'od': 155.4, 'thk': 20.6, 'pcd': 114.3, 'bolts': 4, 'boltSize': '3/4"', 'studLen': 129, 'torqueNm': 747},
        'Class 600': {'od': 155.4, 'thk': 20.6, 'pcd': 114.3, 'bolts': 4, 'boltSize': '3/4"', 'studLen': 154, 'torqueNm': 947},
      }
    },
    {
      'nps': '2"', 'dn': 50,
      'classes': {
        'Class 150': {'od': 152.0, 'thk': 19.1, 'pcd': 120.7, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 80, 'torqueNm': 120},
        'Class 300': {'od': 165.0, 'thk': 22.2, 'pcd': 127.0, 'bolts': 8, 'boltSize': '5/8"', 'studLen': 90, 'torqueNm': 130},
        'Class 600': {'od': 165.0, 'thk': 25.4, 'pcd': 127.0, 'bolts': 8, 'boltSize': '5/8"', 'studLen': 105, 'torqueNm': 140},
        'Class 900': {'od': 215.0, 'thk': 38.1, 'pcd': 165.1, 'bolts': 8, 'boltSize': '7/8"', 'studLen': 145, 'torqueNm': 260},
        'Class 1500': {'od': 215.0, 'thk': 38.1, 'pcd': 165.1, 'bolts': 8, 'boltSize': '7/8"', 'studLen': 145, 'torqueNm': 260},
        'Class 2500': {'od': 235.0, 'thk': 50.8, 'pcd': 171.5, 'bolts': 8, 'boltSize': '1"', 'studLen': 175, 'torqueNm': 410},
      }
    },
    {
      'nps': '3"', 'dn': 80,
      'classes': {
        'Class 150': {'od': 190.5, 'thk': 23.9, 'pcd': 152.4, 'bolts': 4, 'boltSize': '5/8"', 'studLen': 126, 'torqueNm': 729},
        'Class 300': {'od': 209.5, 'thk': 28.4, 'pcd': 168.1, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 148, 'torqueNm': 920},
        'Class 600': {'od': 209.5, 'thk': 31.8, 'pcd': 168.1, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 173, 'torqueNm': 1120},
        'Class 900': {'od': 241.3, 'thk': 38.1, 'pcd': 171.4, 'bolts': 8, 'boltSize': '7/8"', 'studLen': 234, 'torqueNm': 1672},
      }
    },
    {
      'nps': '4"', 'dn': 100,
      'classes': {
        'Class 150': {'od': 229.0, 'thk': 23.8, 'pcd': 190.5, 'bolts': 8, 'boltSize': '5/8"', 'studLen': 90, 'torqueNm': 130},
        'Class 300': {'od': 254.0, 'thk': 31.8, 'pcd': 200.0, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 110, 'torqueNm': 230},
        'Class 600': {'od': 273.0, 'thk': 38.1, 'pcd': 215.9, 'bolts': 8, 'boltSize': '7/8"', 'studLen': 135, 'torqueNm': 360},
        'Class 900': {'od': 292.0, 'thk': 44.5, 'pcd': 235.0, 'bolts': 8, 'boltSize': '1-1/8"', 'studLen': 170, 'torqueNm': 680},
        'Class 1500': {'od': 310.0, 'thk': 53.9, 'pcd': 241.3, 'bolts': 8, 'boltSize': '1-1/4"', 'studLen': 190, 'torqueNm': 950},
        'Class 2500': {'od': 355.0, 'thk': 76.2, 'pcd': 273.1, 'bolts': 8, 'boltSize': '1-1/2"', 'studLen': 245, 'torqueNm': 1650},
      }
    },
    {
      'nps': '5"', 'dn': 125,
      'classes': {
        'Class 150': {'od': 254.0, 'thk': 23.9, 'pcd': 215.9, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 148, 'torqueNm': 932},
        'Class 300': {'od': 279.4, 'thk': 35.1, 'pcd': 234.9, 'bolts': 8, 'boltSize': '7/8"', 'studLen': 172, 'torqueNm': 1144},
        'Class 600': {'od': 330.2, 'thk': 44.4, 'pcd': 266.7, 'bolts': 8, 'boltSize': '1"', 'studLen': 215, 'torqueNm': 1506},
        'Class 900': {'od': 361.9, 'thk': 57.1, 'pcd': 292.1, 'bolts': 8, 'boltSize': '1-1/4"', 'studLen': 276, 'torqueNm': 2058},
      }
    },
    {
      'nps': '6"', 'dn': 150,
      'classes': {
        'Class 150': {'od': 279.4, 'thk': 25.4, 'pcd': 241.3, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 157, 'torqueNm': 1014},
        'Class 300': {'od': 317.5, 'thk': 36.6, 'pcd': 269.7, 'bolts': 12, 'boltSize': '7/8"', 'studLen': 186, 'torqueNm': 1266},
        'Class 600': {'od': 355.6, 'thk': 47.8, 'pcd': 292.1, 'bolts': 12, 'boltSize': '1"', 'studLen': 224, 'torqueNm': 1587},
        'Class 900': {'od': 387.3, 'thk': 63.5, 'pcd': 317.5, 'bolts': 12, 'boltSize': '1-1/8"', 'studLen': 285, 'torqueNm': 2139},
      }
    },
    {
      'nps': '8"', 'dn': 200,
      'classes': {
        'Class 150': {'od': 343.0, 'thk': 28.6, 'pcd': 298.5, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 105, 'torqueNm': 240},
        'Class 300': {'od': 381.0, 'thk': 41.3, 'pcd': 330.2, 'bolts': 12, 'boltSize': '7/8"', 'studLen': 130, 'torqueNm': 380},
        'Class 600': {'od': 420.0, 'thk': 55.6, 'pcd': 349.3, 'bolts': 12, 'boltSize': '1-1/8"', 'studLen': 175, 'torqueNm': 720},
        'Class 900': {'od': 470.0, 'thk': 63.5, 'pcd': 393.7, 'bolts': 12, 'boltSize': '1-3/8"', 'studLen': 220, 'torqueNm': 1350},
      }
    },
    {
      'nps': '10"', 'dn': 250,
      'classes': {
        'Class 150': {'od': 406.4, 'thk': 30.2, 'pcd': 361.9, 'bolts': 12, 'boltSize': '7/8"', 'studLen': 202, 'torqueNm': 1420},
        'Class 300': {'od': 444.5, 'thk': 47.8, 'pcd': 387.3, 'bolts': 16, 'boltSize': '1"', 'studLen': 230, 'torqueNm': 1672},
        'Class 600': {'od': 508.0, 'thk': 63.5, 'pcd': 431.8, 'bolts': 16, 'boltSize': '1-1/4"', 'studLen': 277, 'torqueNm': 2075},
        'Class 900': {'od': 533.4, 'thk': 76.2, 'pcd': 444.5, 'bolts': 16, 'boltSize': '1-3/8"', 'studLen': 336, 'torqueNm': 2606},
      }
    },
    {
      'nps': '12"', 'dn': 300,
      'classes': {
        'Class 150': {'od': 483.0, 'thk': 31.8, 'pcd': 431.8, 'bolts': 12, 'boltSize': '7/8"', 'studLen': 115, 'torqueNm': 390},
        'Class 300': {'od': 521.0, 'thk': 50.8, 'pcd': 450.9, 'bolts': 16, 'boltSize': '1-1/8"', 'studLen': 160, 'torqueNm': 750},
        'Class 600': {'od': 559.0, 'thk': 66.7, 'pcd': 489.0, 'bolts': 20, 'boltSize': '1-1/4"', 'studLen': 200, 'torqueNm': 1100},
      }
    },
    {
      'nps': '14"', 'dn': 350,
      'classes': {
        'Class 150': {'od': 533.4, 'thk': 35.1, 'pcd': 476.2, 'bolts': 12, 'boltSize': '1"', 'studLen': 246, 'torqueNm': 1826},
        'Class 300': {'od': 584.2, 'thk': 53.8, 'pcd': 514.4, 'bolts': 20, 'boltSize': '1-1/8"', 'studLen': 279, 'torqueNm': 2119},
        'Class 600': {'od': 603.2, 'thk': 69.8, 'pcd': 527.0, 'bolts': 20, 'boltSize': '1-3/8"', 'studLen': 311, 'torqueNm': 2380},
      }
    },
    {
      'nps': '16"', 'dn': 400,
      'classes': {
        'Class 150': {'od': 596.9, 'thk': 36.6, 'pcd': 539.8, 'bolts': 16, 'boltSize': '1"', 'studLen': 268, 'torqueNm': 2030},
        'Class 300': {'od': 647.7, 'thk': 57.1, 'pcd': 571.5, 'bolts': 20, 'boltSize': '1-1/4"', 'studLen': 301, 'torqueNm': 2322},
        'Class 600': {'od': 685.8, 'thk': 76.2, 'pcd': 603.2, 'bolts': 20, 'boltSize': '1-1/2"', 'studLen': 340, 'torqueNm': 2644},
      }
    },
    {
      'nps': '18"', 'dn': 450,
      'classes': {
        'Class 150': {'od': 635.0, 'thk': 39.6, 'pcd': 577.9, 'bolts': 16, 'boltSize': '1-1/8"', 'studLen': 282, 'torqueNm': 2152},
        'Class 300': {'od': 711.2, 'thk': 60.5, 'pcd': 628.6, 'bolts': 24, 'boltSize': '1-1/4"', 'studLen': 323, 'torqueNm': 2525},
        'Class 600': {'od': 742.9, 'thk': 82.5, 'pcd': 654.0, 'bolts': 20, 'boltSize': '1-5/8"', 'studLen': 360, 'torqueNm': 2827},
      }
    },
    {
      'nps': '20"', 'dn': 500,
      'classes': {
        'Class 150': {'od': 698.5, 'thk': 42.9, 'pcd': 635.0, 'bolts': 20, 'boltSize': '1-1/8"', 'studLen': 304, 'torqueNm': 2355},
        'Class 300': {'od': 774.7, 'thk': 63.5, 'pcd': 685.8, 'bolts': 24, 'boltSize': '1-1/4"', 'studLen': 346, 'torqueNm': 2729},
        'Class 600': {'od': 812.8, 'thk': 91.9, 'pcd': 723.9, 'bolts': 20, 'boltSize': '1-3/4"', 'studLen': 384, 'torqueNm': 3050},
      }
    },
    {
      'nps': '24"', 'dn': 600,
      'classes': {
        'Class 150': {'od': 812.8, 'thk': 47.8, 'pcd': 749.3, 'bolts': 20, 'boltSize': '1-1/4"', 'studLen': 344, 'torqueNm': 2720},
        'Class 300': {'od': 914.4, 'thk': 69.8, 'pcd': 812.8, 'bolts': 24, 'boltSize': '1-3/8"', 'studLen': 395, 'torqueNm': 3176},
        'Class 600': {'od': 939.8, 'thk': 101.6, 'pcd': 838.2, 'bolts': 20, 'boltSize': '2"', 'studLen': 428, 'torqueNm': 3457},
      }
    },
  ];

  // ASME B16.11 Forged Socket-Weld Class 3000 / 6000
  static final List<Map<String, dynamic>> socketWelds = [
    {'nps': '1/2"', 'dn': 15, 'boreDia': 21.8, 'depth': 9.5, 'cToE': 24.5, 'minWall': 4.67, 'gap': 1.6},
    {'nps': '3/4"', 'dn': 20, 'boreDia': 27.2, 'depth': 12.5, 'cToE': 28.5, 'minWall': 4.90, 'gap': 1.6},
    {'nps': '1"', 'dn': 25, 'boreDia': 33.9, 'depth': 12.5, 'cToE': 34.0, 'minWall': 5.69, 'gap': 1.6},
    {'nps': '1-1/2"', 'dn': 40, 'boreDia': 48.8, 'depth': 12.5, 'cToE': 43.5, 'minWall': 6.35, 'gap': 1.6},
    {'nps': '2"', 'dn': 50, 'boreDia': 61.2, 'depth': 16.0, 'cToE': 47.5, 'minWall': 6.93, 'gap': 1.6},
    {'nps': '3"', 'dn': 80, 'boreDia': 89.8, 'depth': 16.0, 'cToE': 78.0, 'minWall': 8.76, 'gap': 1.6},
    {'nps': '4"', 'dn': 100, 'boreDia': 115.09, 'depth': 19.0, 'cToE': 92.0, 'minWall': 11.13, 'gap': 1.6},
  ];

  // ASME B16.11 / NPT Forged Threaded Class 3000
  static final List<Map<String, dynamic>> threadeds = [
    {'nps': '1/2"', 'dn': 15, 'cToE': 25.0, 'minThreadL2': 13.5, 'tpi': 14, 'pitch': 1.814, 'taper': '1:16'},
    {'nps': '3/4"', 'dn': 20, 'cToE': 28.5, 'minThreadL2': 14.0, 'tpi': 14, 'pitch': 1.814, 'taper': '1:16'},
    {'nps': '1"', 'dn': 25, 'cToE': 34.0, 'minThreadL2': 17.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1:16'},
    {'nps': '1-1/2"', 'dn': 40, 'cToE': 43.5, 'minThreadL2': 18.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1:16'},
    {'nps': '2"', 'dn': 50, 'cToE': 52.5, 'minThreadL2': 19.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1:16'},
    {'nps': '3"', 'dn': 80, 'cToE': 78.0, 'minThreadL2': 26.5, 'tpi': 8, 'pitch': 3.175, 'taper': '1:16'},
    {'nps': '4"', 'dn': 100, 'cToE': 92.0, 'minThreadL2': 29.0, 'tpi': 8, 'pitch': 3.175, 'taper': '1:16'},
  ];

  // ASME B16.9 Concentric & Eccentric Reducers - Center-to-End Length (H)
  // H is identical for concentric and eccentric patterns at a given large-NPS x small-NPS pair.
  // TODO(data-audit): '20" x 16"' and '24" x 20"' both list H=508.0mm below.
  // Could not confirm the correct 24"x20" value against an authoritative
  // ASME B16.9 table in this session — verify before relying on it; it is
  // unusual (though not impossible) for two different reduction pairs to
  // share an identical length.
  static final List<Map<String, dynamic>> reducers = [
    {'nps': '3/4" x 1/2"', 'largeDn': 20, 'smallDn': 15, 'lengths': {'Concentric': 38.0, 'Eccentric': 38.0}},
    {'nps': '1" x 3/4"', 'largeDn': 25, 'smallDn': 20, 'lengths': {'Concentric': 51.0, 'Eccentric': 51.0}},
    {'nps': '1-1/2" x 1"', 'largeDn': 40, 'smallDn': 25, 'lengths': {'Concentric': 64.0, 'Eccentric': 64.0}},
    {'nps': '2" x 1-1/2"', 'largeDn': 50, 'smallDn': 40, 'lengths': {'Concentric': 76.0, 'Eccentric': 76.0}},
    {'nps': '3" x 2"', 'largeDn': 80, 'smallDn': 50, 'lengths': {'Concentric': 89.0, 'Eccentric': 89.0}},
    {'nps': '4" x 3"', 'largeDn': 100, 'smallDn': 80, 'lengths': {'Concentric': 102.0, 'Eccentric': 102.0}},
    {'nps': '6" x 4"', 'largeDn': 150, 'smallDn': 100, 'lengths': {'Concentric': 140.0, 'Eccentric': 140.0}},
    {'nps': '8" x 6"', 'largeDn': 200, 'smallDn': 150, 'lengths': {'Concentric': 152.0, 'Eccentric': 152.0}},
    {'nps': '10" x 8"', 'largeDn': 250, 'smallDn': 200, 'lengths': {'Concentric': 178.0, 'Eccentric': 178.0}},
    {'nps': '12" x 10"', 'largeDn': 300, 'smallDn': 250, 'lengths': {'Concentric': 203.0, 'Eccentric': 203.0}},
    {'nps': '16" x 12"', 'largeDn': 400, 'smallDn': 300, 'lengths': {'Concentric': 356.0, 'Eccentric': 356.0}},
    {'nps': '20" x 16"', 'largeDn': 500, 'smallDn': 400, 'lengths': {'Concentric': 508.0, 'Eccentric': 508.0}},
    {'nps': '24" x 20"', 'largeDn': 600, 'smallDn': 500, 'lengths': {'Concentric': 508.0, 'Eccentric': 508.0}},
  ];

  // ASME B16.20 Spiral Wound Gaskets (CG style, no inner ring) - sealing-element ID/OD by Class
  static final List<Map<String, dynamic>> gaskets = [
    {
      'nps': '1/2"', 'dn': 15,
      'classes': {
        'Class 150': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
        'Class 300': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
        'Class 600': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
        'Class 900': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
        'Class 1500': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
        'Class 2500': {'id': 19.1, 'od': 31.8, 'thk': 3.2},
      }
    },
    {
      'nps': '3/4"', 'dn': 20,
      'classes': {
        'Class 150': {'id': 35.4, 'od': 49.0, 'thk': 3.2},
        'Class 300': {'id': 35.4, 'od': 49.0, 'thk': 3.2},
        'Class 600': {'id': 35.1, 'od': 49.8, 'thk': 3.2},
      }
    },
    {
      'nps': '1"', 'dn': 25,
      'classes': {
        'Class 150': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
        'Class 300': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
        'Class 600': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
        'Class 900': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
        'Class 1500': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
        'Class 2500': {'id': 31.8, 'od': 47.8, 'thk': 3.2},
      }
    },
    {
      'nps': '1-1/2"', 'dn': 40,
      'classes': {
        'Class 150': {'id': 57.5, 'od': 72.6, 'thk': 3.2},
        'Class 300': {'id': 57.5, 'od': 72.6, 'thk': 3.2},
        'Class 600': {'id': 57.0, 'od': 73.4, 'thk': 3.2},
      }
    },
    {
      'nps': '2"', 'dn': 50,
      'classes': {
        'Class 150': {'id': 69.9, 'od': 85.9, 'thk': 3.2},
        'Class 300': {'id': 69.9, 'od': 85.9, 'thk': 3.2},
        'Class 600': {'id': 69.9, 'od': 85.9, 'thk': 3.2},
        'Class 900': {'id': 58.7, 'od': 85.9, 'thk': 3.2},
        'Class 1500': {'id': 58.7, 'od': 85.9, 'thk': 3.2},
        'Class 2500': {'id': 58.7, 'od': 85.9, 'thk': 3.2},
      }
    },
    {
      'nps': '3"', 'dn': 80,
      'classes': {
        'Class 150': {'id': 99.2, 'od': 117.2, 'thk': 3.2},
        'Class 300': {'id': 99.2, 'od': 117.2, 'thk': 3.2},
        'Class 600': {'id': 98.3, 'od': 117.8, 'thk': 3.2},
        'Class 900': {'id': 97.4, 'od': 118.7, 'thk': 3.2},
      }
    },
    {
      'nps': '4"', 'dn': 100,
      'classes': {
        'Class 150': {'id': 127.0, 'od': 149.4, 'thk': 3.2},
        'Class 300': {'id': 127.0, 'od': 149.4, 'thk': 3.2},
        'Class 600': {'id': 120.7, 'od': 149.4, 'thk': 3.2},
        'Class 900': {'id': 120.7, 'od': 149.4, 'thk': 3.2},
        'Class 1500': {'id': 117.6, 'od': 149.4, 'thk': 3.2},
        'Class 2500': {'id': 117.6, 'od': 149.4, 'thk': 3.2},
      }
    },
    {
      'nps': '5"', 'dn': 125,
      'classes': {
        'Class 150': {'id': 152.9, 'od': 174.7, 'thk': 3.2},
        'Class 300': {'id': 152.9, 'od': 174.7, 'thk': 3.2},
        'Class 600': {'id': 151.5, 'od': 175.0, 'thk': 3.2},
        'Class 900': {'id': 150.1, 'od': 175.8, 'thk': 3.2},
      }
    },
    {
      'nps': '6"', 'dn': 150,
      'classes': {
        'Class 150': {'id': 180.5, 'od': 204.2, 'thk': 3.2},
        'Class 300': {'id': 180.5, 'od': 204.2, 'thk': 3.2},
        'Class 600': {'id': 178.8, 'od': 204.4, 'thk': 3.2},
        'Class 900': {'id': 177.1, 'od': 205.1, 'thk': 3.2},
      }
    },
    {
      'nps': '8"', 'dn': 200,
      'classes': {
        'Class 150': {'id': 233.4, 'od': 263.7, 'thk': 3.2},
        'Class 300': {'id': 233.4, 'od': 263.7, 'thk': 3.2},
        'Class 600': {'id': 225.6, 'od': 263.7, 'thk': 3.2},
        'Class 900': {'id': 222.3, 'od': 257.3, 'thk': 3.2},
        'Class 1500': {'id': 215.9, 'od': 257.3, 'thk': 3.2},
        'Class 2500': {'id': 215.9, 'od': 257.3, 'thk': 3.2},
      }
    },
    {
      'nps': '10"', 'dn': 250,
      'classes': {
        'Class 150': {'id': 287.9, 'od': 319.1, 'thk': 3.2},
        'Class 300': {'id': 287.9, 'od': 319.1, 'thk': 3.2},
        'Class 600': {'id': 285.2, 'od': 318.9, 'thk': 3.2},
        'Class 900': {'id': 282.4, 'od': 319.2, 'thk': 3.2},
      }
    },
    {
      'nps': '12"', 'dn': 300,
      'classes': {
        'Class 150': {'id': 339.9, 'od': 374.7, 'thk': 3.2},
        'Class 300': {'id': 339.9, 'od': 374.7, 'thk': 3.2},
        'Class 600': {'id': 327.2, 'od': 374.7, 'thk': 3.2},
        'Class 900': {'id': 323.9, 'od': 368.3, 'thk': 3.2},
        'Class 1500': {'id': 323.9, 'od': 368.3, 'thk': 3.2},
        'Class 2500': {'id': 317.5, 'od': 368.3, 'thk': 3.2},
      }
    },
    {
      'nps': '14"', 'dn': 350,
      'classes': {
        'Class 150': {'id': 372.4, 'od': 409.5, 'thk': 3.2},
        'Class 300': {'id': 372.4, 'od': 409.5, 'thk': 3.2},
        'Class 600': {'id': 368.8, 'od': 408.8, 'thk': 3.2},
      }
    },
    {
      'nps': '16"', 'dn': 400,
      'classes': {
        'Class 150': {'id': 424.5, 'od': 465.2, 'thk': 3.2},
        'Class 300': {'id': 424.5, 'od': 465.2, 'thk': 3.2},
        'Class 600': {'id': 420.4, 'od': 464.3, 'thk': 3.2},
      }
    },
    {
      'nps': '18"', 'dn': 450,
      'classes': {
        'Class 150': {'id': 476.5, 'od': 520.8, 'thk': 3.2},
        'Class 300': {'id': 476.5, 'od': 520.8, 'thk': 3.2},
        'Class 600': {'id': 471.9, 'od': 519.7, 'thk': 3.2},
      }
    },
    {
      'nps': '20"', 'dn': 500,
      'classes': {
        'Class 150': {'id': 528.6, 'od': 576.5, 'thk': 3.2},
        'Class 300': {'id': 528.6, 'od': 576.5, 'thk': 3.2},
        'Class 600': {'id': 523.5, 'od': 575.3, 'thk': 3.2},
      }
    },
    {
      'nps': '24"', 'dn': 600,
      'classes': {
        'Class 150': {'id': 632.7, 'od': 687.9, 'thk': 3.2},
        'Class 300': {'id': 632.7, 'od': 687.9, 'thk': 3.2},
        'Class 600': {'id': 626.6, 'od': 686.2, 'thk': 3.2},
      }
    },
  ];

  // ASME B16.10 Flanged Valve Face-to-Face, by valve type (Gate/Ball share the
  // short/long pattern per class; Globe and Swing Check share the B16.10 long pattern).
  static final List<Map<String, dynamic>> valves = [
    {
      'nps': '1/2"', 'dn': 15,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 108.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 140.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 165.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 108.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 140.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 165.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 108.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 140.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 165.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 108.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 140.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 165.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '3/4"', 'dn': 20,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 119.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 154.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 193.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 119.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 154.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 193.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 119.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 162.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 193.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 119.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 162.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 193.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '1"', 'dn': 25,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 127.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 165.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 216.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 127.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 165.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 216.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 127.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 216.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 216.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 127.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 216.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 216.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '1-1/2"', 'dn': 40,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 155.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 193.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 258.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 155.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 193.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 258.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 155.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 203.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 258.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 155.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 203.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 258.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '2"', 'dn': 50,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 178.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 216.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 292.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 178.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 216.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 292.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 178.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 267.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 292.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 178.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 267.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 292.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '3"', 'dn': 80,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 206.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 367.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 206.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 367.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 206.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 277.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 367.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 206.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 277.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 367.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '4"', 'dn': 100,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 229.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 305.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 432.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 229.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 305.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 432.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 229.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 432.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 229.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 432.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '5"', 'dn': 125,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 248.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 338.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 495.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 248.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 338.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 495.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 248.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 355.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 495.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 248.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 355.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 495.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '6"', 'dn': 150,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 367.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 554.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 367.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 554.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 385.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 554.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 264.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 385.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 554.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '8"', 'dn': 200,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 292.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 419.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 660.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 292.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 419.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 660.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 292.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 533.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 660.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 292.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 533.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 660.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '10"', 'dn': 250,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 326.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 463.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 753.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 326.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 463.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 753.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 326.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 486.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 753.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 326.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 486.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 753.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '12"', 'dn': 300,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 502.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 838.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 502.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 838.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 711.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 838.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 356.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 711.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 838.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '14"', 'dn': 350,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 384.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 538.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 918.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 384.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 538.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 918.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 384.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 565.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 918.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 384.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 565.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 918.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '16"', 'dn': 400,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 410.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 571.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 993.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 410.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 571.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 993.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 410.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 600.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 993.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 410.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 600.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 993.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '18"', 'dn': 450,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 434.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 601.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1064.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 434.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 601.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1064.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 434.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 631.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1064.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 434.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 631.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1064.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '20"', 'dn': 500,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 457.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 630.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1132.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 457.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 630.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1132.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 457.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 662.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1132.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 457.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 662.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1132.0, 'endConn': 'RF Flanged'},
        },
      }
    },
    {
      'nps': '24"', 'dn': 600,
      'types': {
        'Gate Valve': {
          'Class 150': {'ftf': 500.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 684.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1260.0, 'endConn': 'RF Flanged'},
        },
        'Ball Valve': {
          'Class 150': {'ftf': 500.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 684.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1260.0, 'endConn': 'RF Flanged'},
        },
        'Globe Valve': {
          'Class 150': {'ftf': 500.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 718.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1260.0, 'endConn': 'RF Flanged'},
        },
        'Swing Check Valve': {
          'Class 150': {'ftf': 500.0, 'endConn': 'RF Flanged'},
          'Class 300': {'ftf': 718.0, 'endConn': 'RF Flanged'},
          'Class 600': {'ftf': 1260.0, 'endConn': 'RF Flanged'},
        },
      }
    },
  ];

  // ASME B16.9 Equal Tees - Center-to-End (C)
  static final List<Map<String, dynamic>> tees = [
    {'nps': '1/2"', 'dn': 15, 'teeCtoE': 25.0},
    {'nps': '3/4"', 'dn': 20, 'teeCtoE': 29.0},
    {'nps': '1"', 'dn': 25, 'teeCtoE': 38.0},
    {'nps': '1-1/2"', 'dn': 40, 'teeCtoE': 48.0},
    {'nps': '2"', 'dn': 50, 'teeCtoE': 64.0},
    {'nps': '3"', 'dn': 80, 'teeCtoE': 86.0},
    {'nps': '4"', 'dn': 100, 'teeCtoE': 105.0},
    {'nps': '6"', 'dn': 150, 'teeCtoE': 143.0},
    {'nps': '8"', 'dn': 200, 'teeCtoE': 178.0},
    {'nps': '10"', 'dn': 250, 'teeCtoE': 216.0},
    {'nps': '12"', 'dn': 300, 'teeCtoE': 254.0},
    {'nps': '14"', 'dn': 350, 'teeCtoE': 292.0},
    {'nps': '16"', 'dn': 400, 'teeCtoE': 330.0},
    {'nps': '18"', 'dn': 450, 'teeCtoE': 368.0},
    {'nps': '20"', 'dn': 500, 'teeCtoE': 406.0},
    {'nps': '24"', 'dn': 600, 'teeCtoE': 482.0},
  ];

  // ASME B16.9 Butt-Weld Elbows - Center-to-End by pattern (90 LR / 90 SR / 45)
  static final List<Map<String, dynamic>> elbows = [
    {'nps': '1/2"', 'dn': 15, 'angles': {'90° Long Radius': 38.0, '90° Short Radius': 25.4, '45°': 16.0}},
    {'nps': '3/4"', 'dn': 20, 'angles': {'90° Long Radius': 38.0, '90° Short Radius': 25.4, '45°': 19.0}},
    {'nps': '1"', 'dn': 25, 'angles': {'90° Long Radius': 38.0, '90° Short Radius': 25.4, '45°': 22.0}},
    {'nps': '1-1/2"', 'dn': 40, 'angles': {'90° Long Radius': 57.0, '90° Short Radius': 38.0, '45°': 29.0}},
    {'nps': '2"', 'dn': 50, 'angles': {'90° Long Radius': 76.0, '90° Short Radius': 51.0, '45°': 35.0}},
    {'nps': '3"', 'dn': 80, 'angles': {'90° Long Radius': 114.0, '90° Short Radius': 76.0, '45°': 51.0}},
    {'nps': '4"', 'dn': 100, 'angles': {'90° Long Radius': 152.0, '90° Short Radius': 102.0, '45°': 64.0}},
    {'nps': '6"', 'dn': 150, 'angles': {'90° Long Radius': 229.0, '90° Short Radius': 152.0, '45°': 95.0}},
    {'nps': '8"', 'dn': 200, 'angles': {'90° Long Radius': 305.0, '90° Short Radius': 203.0, '45°': 127.0}},
    {'nps': '10"', 'dn': 250, 'angles': {'90° Long Radius': 381.0, '90° Short Radius': 254.0, '45°': 159.0}},
    {'nps': '12"', 'dn': 300, 'angles': {'90° Long Radius': 457.0, '90° Short Radius': 305.0, '45°': 190.0}},
    {'nps': '14"', 'dn': 350, 'angles': {'90° Long Radius': 533.0, '90° Short Radius': 356.0, '45°': 222.0}},
    {'nps': '16"', 'dn': 400, 'angles': {'90° Long Radius': 610.0, '90° Short Radius': 406.0, '45°': 254.0}},
    {'nps': '18"', 'dn': 450, 'angles': {'90° Long Radius': 686.0, '90° Short Radius': 457.0, '45°': 286.0}},
    {'nps': '20"', 'dn': 500, 'angles': {'90° Long Radius': 762.0, '90° Short Radius': 508.0, '45°': 318.0}},
    {'nps': '24"', 'dn': 600, 'angles': {'90° Long Radius': 914.0, '90° Short Radius': 610.0, '45°': 381.0}},
  ];

  // ASME B16.9 Butt-Weld Caps - Length (E)
  static final List<Map<String, dynamic>> caps = [
    {'nps': '1/2"', 'dn': 15, 'capLen': 25.0},
    {'nps': '3/4"', 'dn': 20, 'capLen': 25.0},
    {'nps': '1"', 'dn': 25, 'capLen': 38.0},
    {'nps': '1-1/2"', 'dn': 40, 'capLen': 38.0},
    {'nps': '2"', 'dn': 50, 'capLen': 38.0},
    {'nps': '3"', 'dn': 80, 'capLen': 51.0},
    {'nps': '4"', 'dn': 100, 'capLen': 64.0},
    {'nps': '6"', 'dn': 150, 'capLen': 89.0},
    {'nps': '8"', 'dn': 200, 'capLen': 102.0},
    {'nps': '10"', 'dn': 250, 'capLen': 127.0},
    {'nps': '12"', 'dn': 300, 'capLen': 152.0},
    {'nps': '14"', 'dn': 350, 'capLen': 177.0},
    {'nps': '16"', 'dn': 400, 'capLen': 202.0},
    {'nps': '18"', 'dn': 450, 'capLen': 227.0},
    {'nps': '20"', 'dn': 500, 'capLen': 252.0},
    {'nps': '24"', 'dn': 600, 'capLen': 302.0},
  ];

  // MSS SP-97 Weldolets, size-on-size, Standard Weight - Height (A, from run pipe OD to top face)
  static final List<Map<String, dynamic>> weldolets = [
    {'nps': '1/2"', 'dn': 15, 'height': 19.05},
    {'nps': '3/4"', 'dn': 20, 'height': 22.23},
    {'nps': '1"', 'dn': 25, 'height': 26.99},
    {'nps': '1-1/2"', 'dn': 40, 'height': 33.34},
    {'nps': '2"', 'dn': 50, 'height': 38.10},
    {'nps': '3"', 'dn': 80, 'height': 44.45},
    {'nps': '4"', 'dn': 100, 'height': 50.80},
    {'nps': '6"', 'dn': 150, 'height': 60.30},
    {'nps': '8"', 'dn': 200, 'height': 69.85},
    {'nps': '10"', 'dn': 250, 'height': 77.79},
    {'nps': '12"', 'dn': 300, 'height': 85.73},
    {'nps': '16"', 'dn': 400, 'height': 93.66},
    {'nps': '20"', 'dn': 500, 'height': 117.48},
    {'nps': '24"', 'dn': 600, 'height': 136.53},
    {'nps': '30"', 'dn': 750, 'height': 165.10},
    {'nps': '36"', 'dn': 900, 'height': 193.68},
  ];

  // MSS SP-97 Sockolets, size-on-size, Class 3000 - Height (A) and socket depth (E)
  static final List<Map<String, dynamic>> sockolets = [
    {'nps': '1/2"', 'dn': 15, 'height': 25.40, 'socketDepth': 14.28},
    {'nps': '3/4"', 'dn': 20, 'height': 26.98, 'socketDepth': 14.28},
    {'nps': '1"', 'dn': 25, 'height': 33.33, 'socketDepth': 19.84},
    {'nps': '1-1/2"', 'dn': 40, 'height': 34.92, 'socketDepth': 19.05},
    {'nps': '2"', 'dn': 50, 'height': 38.10, 'socketDepth': 20.63},
    {'nps': '3"', 'dn': 80, 'height': 44.45, 'socketDepth': 23.81},
    {'nps': '4"', 'dn': 100, 'height': 47.62, 'socketDepth': 26.98},
    {'nps': '6"', 'dn': 150, 'height': 69.85, 'socketDepth': 35.71},
  ];

  // MSS SP-97 Threadolets, size-on-size, Class 3000 - Height (A)
  static final List<Map<String, dynamic>> threadolets = [
    {'nps': '1/2"', 'dn': 15, 'height': 25.40},
    {'nps': '3/4"', 'dn': 20, 'height': 26.98},
    {'nps': '1"', 'dn': 25, 'height': 33.33},
    {'nps': '1-1/2"', 'dn': 40, 'height': 34.92},
    {'nps': '2"', 'dn': 50, 'height': 38.10},
    {'nps': '3"', 'dn': 80, 'height': 50.80},
    {'nps': '4"', 'dn': 100, 'height': 57.15},
    {'nps': '6"', 'dn': 150, 'height': 69.85},
  ];
}
