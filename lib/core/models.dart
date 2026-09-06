import 'dart:math' as math;

enum ComponentCategory { pipe, flange, buttWeld, socketWeld, threaded }

enum MaterialGrade { a106B, a312Tp316L }

class PipingEngine {
  // محاسبه فشار مجاز کارکرد لوله بر اساس ASME B31.3 (فرمول بند 304.1.2)
  // P = (2 * S * E * W * t_min) / (D - 2 * Y * t_min)
  static Map<String, double> calculatePipePressure({
    required double od, // mm
    required double nominalThk, // mm
    required MaterialGrade material,
    double designTempC = 38.0, // °C
    double corrosionAllowance = 1.5, // mm
  }) {
    // تنش مجاز S (MPa) در دمای محیط (ASME B31.3 Table A-1)
    double sMpa = (material == MaterialGrade.a106B) ? 138.0 : 115.0;
    if (designTempC > 100) sMpa *= 0.95;
    if (designTempC > 200) sMpa *= 0.88;
    if (designTempC > 300) sMpa *= 0.78;

    const double eFactor = 1.0; // لوله مانیسمان بدون درز
    const double wFactor = 1.0;
    const double yFactor = 0.4; // فریتیک/آستنیتیک زیر 482 درجه

    // احتساب تلورانس منفی 12.5% کارخانه و کاهش ناشی از خوردگی
    double tMin = (nominalThk * 0.875) - corrosionAllowance;
    if (tMin <= 0.1) tMin = 0.1;

    double pMpa = (2 * sMpa * eFactor * wFactor * tMin) / (od - (2 * yFactor * tMin));
    if (pMpa < 0) pMpa = 0;

    double pBar = pMpa * 10.0;
    double pPsi = pBar * 14.5038;
    double hydroTestBar = pBar * 1.5; // تست هیدرواستاتیک بند 345.4.2

    return {
      'mawpBar': double.parse(pBar.toStringAsFixed(1)),
      'mawpPsi': double.parse(pPsi.toStringAsFixed(0)),
      'hydroTestBar': double.parse(hydroTestBar.toStringAsFixed(1)),
      'tMin': double.parse(tMin.toStringAsFixed(2)),
    };
  }

  // داده‌های فشار-دما فلنج‌ها بر اساس ASME B16.5 Table 2-1.1 (Group 1.1 A105)
  static Map<String, dynamic> getFlangeRating(String ratingClass, MaterialGrade mat) {
    final Map<String, Map<String, double>> ratingsA105 = {
      'Class 150': {'ambient': 19.6, 't100': 17.7, 't200': 13.8, 't300': 10.2, 't400': 6.5, 'hydro': 29.5},
      'Class 300': {'ambient': 51.1, 't100': 46.6, 't200': 43.8, 't300': 39.8, 't400': 34.7, 'hydro': 77.0},
      'Class 600': {'ambient': 102.1, 't100': 93.2, 't200': 87.6, 't300': 79.7, 't400': 69.4, 'hydro': 153.5},
      'Class 900': {'ambient': 153.2, 't100': 139.8, 't200': 131.4, 't300': 119.5, 't400': 104.2, 'hydro': 230.0},
      'Class 1500': {'ambient': 255.3, 't100': 233.0, 't200': 219.0, 't300': 199.2, 't400': 173.6, 'hydro': 383.5},
      'Class 2500': {'ambient': 425.5, 't100': 388.3, 't200': 364.9, 't300': 331.9, 't400': 289.4, 'hydro': 638.5},
    };
    return ratingsA105[ratingClass] ?? ratingsA105['Class 150']!;
  }
}

class FullPipingDataset {
  // کاتالوگ جامع لوله‌ها (1/2" تا 24")
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
      'nps': '16"', 'dn': 400, 'od': 406.40,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 393.70, 'wt': 62.64},
        'Sch 40 (STD)': {'thk': 12.70, 'id': 381.00, 'wt': 123.30},
        'Sch 80 (XS)': {'thk': 21.44, 'id': 363.52, 'wt': 203.53},
        'Sch 160': {'thk': 40.49, 'id': 325.42, 'wt': 365.36},
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
      'nps': '24"', 'dn': 600, 'od': 609.60,
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 596.90, 'wt': 94.46},
        'Sch 40 (STD)': {'thk': 17.48, 'id': 574.64, 'wt': 255.41},
        'Sch 80 (XS)': {'thk': 30.96, 'id': 447.68, 'wt': 441.97},
      }
    },
  ];

  // کاتالوگ فلنج‌ها (ASME B16.5 WNRF) به همراه کلاس، PCD، بولتینگ و گشتاور بستن
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
      'nps': '8"', 'dn': 200,
      'classes': {
        'Class 150': {'od': 343.0, 'thk': 28.6, 'pcd': 298.5, 'bolts': 8, 'boltSize': '3/4"', 'studLen': 105, 'torqueNm': 240},
        'Class 300': {'od': 381.0, 'thk': 41.3, 'pcd': 330.2, 'bolts': 12, 'boltSize': '7/8"', 'studLen': 130, 'torqueNm': 380},
        'Class 600': {'od': 420.0, 'thk': 55.6, 'pcd': 349.3, 'bolts': 12, 'boltSize': '1-1/8"', 'studLen': 175, 'torqueNm': 720},
        'Class 900': {'od': 470.0, 'thk': 63.5, 'pcd': 393.7, 'bolts': 12, 'boltSize': '1-3/8"', 'studLen': 220, 'torqueNm': 1350},
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
  ];

  // اتصالات لب به لب جوشی (ASME B16.9 Butt-Weld Fittings)
  static final List<Map<String, dynamic>> buttWelds = [
    {'nps': '1/2"', 'dn': 15, 'lrElbow90': 38.0, 'srElbow90': 25.4, 'elbow45': 16.0, 'teeCtoE': 25.0, 'redLen': 38.0, 'capLen': 25.0},
    {'nps': '3/4"', 'dn': 20, 'lrElbow90': 38.0, 'srElbow90': 25.4, 'elbow45': 19.0, 'teeCtoE': 29.0, 'redLen': 38.0, 'capLen': 25.0},
    {'nps': '1"', 'dn': 25, 'lrElbow90': 38.0, 'srElbow90': 25.4, 'elbow45': 22.0, 'teeCtoE': 38.0, 'redLen': 51.0, 'capLen': 38.0},
    {'nps': '1-1/2"', 'dn': 40, 'lrElbow90': 57.0, 'srElbow90': 38.0, 'elbow45': 29.0, 'teeCtoE': 48.0, 'redLen': 64.0, 'capLen': 38.0},
    {'nps': '2"', 'dn': 50, 'lrElbow90': 76.0, 'srElbow90': 51.0, 'elbow45': 35.0, 'teeCtoE': 64.0, 'redLen': 76.0, 'capLen': 38.0},
    {'nps': '3"', 'dn': 80, 'lrElbow90': 114.0, 'srElbow90': 76.0, 'elbow45': 51.0, 'teeCtoE': 86.0, 'redLen': 89.0, 'capLen': 51.0},
    {'nps': '4"', 'dn': 100, 'lrElbow90': 152.0, 'srElbow90': 102.0, 'elbow45': 64.0, 'teeCtoE': 105.0, 'redLen': 102.0, 'capLen': 64.0},
    {'nps': '6"', 'dn': 150, 'lrElbow90': 229.0, 'srElbow90': 152.0, 'elbow45': 95.0, 'teeCtoE': 143.0, 'redLen': 140.0, 'capLen': 89.0},
    {'nps': '8"', 'dn': 200, 'lrElbow90': 305.0, 'srElbow90': 203.0, 'elbow45': 127.0, 'teeCtoE': 178.0, 'redLen': 152.0, 'capLen': 102.0},
    {'nps': '10"', 'dn': 250, 'lrElbow90': 381.0, 'srElbow90': 254.0, 'elbow45': 159.0, 'teeCtoE': 216.0, 'redLen': 178.0, 'capLen': 127.0},
    {'nps': '12"', 'dn': 300, 'lrElbow90': 457.0, 'srElbow90': 305.0, 'elbow45': 190.0, 'teeCtoE': 254.0, 'redLen': 203.0, 'capLen': 152.0},
  ];

  // اتصالات سوکت جوش فورج شده (ASME B16.11 Socket-Weld Class 3000 / 6000)
  static final List<Map<String, dynamic>> socketWelds = [
    {'nps': '1/2"', 'dn': 15, 'boreDia': 21.8, 'depth': 9.5, 'cToE': 24.5, 'minWall': 4.67, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
    {'nps': '3/4"', 'dn': 20, 'boreDia': 27.2, 'depth': 12.5, 'cToE': 28.5, 'minWall': 4.90, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
    {'nps': '1"', 'dn': 25, 'boreDia': 33.9, 'depth': 12.5, 'cToE': 34.0, 'minWall': 5.69, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
    {'nps': '1-1/2"', 'dn': 40, 'boreDia': 48.8, 'depth': 12.5, 'cToE': 43.5, 'minWall': 6.35, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
    {'nps': '2"', 'dn': 50, 'boreDia': 61.2, 'depth': 16.0, 'cToE': 47.5, 'minWall': 6.93, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
    {'nps': '3"', 'dn': 80, 'boreDia': 89.8, 'depth': 16.0, 'cToE': 78.0, 'minWall': 8.76, 'gap': 1.6, 'equivSch': 'Sch 80 / 160'},
  ];

  // اتصالات رزوه‌ای فورج شده (ASME B16.11 / B1.20.1 NPT Threaded Class 3000)
  static final List<Map<String, dynamic>> threadeds = [
    {'nps': '1/2"', 'dn': 15, 'cToE': 25.0, 'minThreadL2': 13.5, 'tpi': 14, 'pitch': 1.814, 'taper': '1 in 16 (0.75 in/ft)'},
    {'nps': '3/4"', 'dn': 20, 'cToE': 28.5, 'minThreadL2': 14.0, 'tpi': 14, 'pitch': 1.814, 'taper': '1 in 16 (0.75 in/ft)'},
    {'nps': '1"', 'dn': 25, 'cToE': 34.0, 'minThreadL2': 17.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1 in 16 (0.75 in/ft)'},
    {'nps': '1-1/2"', 'dn': 40, 'cToE': 43.5, 'minThreadL2': 18.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1 in 16 (0.75 in/ft)'},
    {'nps': '2"', 'dn': 50, 'cToE': 52.5, 'minThreadL2': 19.5, 'tpi': 11.5, 'pitch': 2.209, 'taper': '1 in 16 (0.75 in/ft)'},
    {'nps': '3"', 'dn': 80, 'cToE': 78.0, 'minThreadL2': 26.5, 'tpi': 8, 'pitch': 3.175, 'taper': '1 in 16 (0.75 in/ft)'},
  ];
}
