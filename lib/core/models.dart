enum ComponentCategory { pipe, flange, buttWeld, socketWeld, threaded }

class ComponentMetric {
  final String nps;
  final int dn;
  final double od;
  final Map<String, dynamic> data;

  const ComponentMetric({
    required this.nps,
    required this.dn,
    required this.od,
    required this.data,
  });
}

class PipingDatabase {
  // ASME B36.10M / B36.19M: ابعاد کامل لوله‌ها از 1/2 اینچ تا 24 اینچ
  static const List<ComponentMetric> pipes = [
    ComponentMetric(nps: '1/2"', dn: 15, od: 21.3, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 2.11, 'id': 17.08, 'wt': 1.00},
        'Sch 40 (STD)': {'thk': 2.77, 'id': 15.76, 'wt': 1.27},
        'Sch 80 (XS)': {'thk': 3.73, 'id': 13.84, 'wt': 1.62},
        'Sch 160': {'thk': 4.78, 'id': 11.74, 'wt': 1.95},
        'XXS': {'thk': 7.47, 'id': 6.36, 'wt': 2.55},
      }
    }),
    ComponentMetric(nps: '3/4"', dn: 20, od: 26.7, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 2.11, 'id': 22.48, 'wt': 1.28},
        'Sch 40 (STD)': {'thk': 2.87, 'id': 20.96, 'wt': 1.69},
        'Sch 80 (XS)': {'thk': 3.91, 'id': 18.88, 'wt': 2.20},
        'Sch 160': {'thk': 5.56, 'id': 15.58, 'wt': 2.90},
        'XXS': {'thk': 7.82, 'id': 11.06, 'wt': 3.64},
      }
    }),
    ComponentMetric(nps: '1"', dn: 25, od: 33.4, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 27.86, 'wt': 2.09},
        'Sch 40 (STD)': {'thk': 3.38, 'id': 26.64, 'wt': 2.50},
        'Sch 80 (XS)': {'thk': 4.55, 'id': 24.30, 'wt': 3.24},
        'Sch 160': {'thk': 6.35, 'id': 20.70, 'wt': 4.24},
        'XXS': {'thk': 9.09, 'id': 15.22, 'wt': 5.46},
      }
    }),
    ComponentMetric(nps: '1-1/2"', dn: 40, od: 48.3, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 42.76, 'wt': 3.11},
        'Sch 40 (STD)': {'thk': 3.68, 'id': 40.94, 'wt': 4.05},
        'Sch 80 (XS)': {'thk': 5.08, 'id': 38.14, 'wt': 5.41},
        'Sch 160': {'thk': 7.14, 'id': 34.02, 'wt': 7.25},
        'XXS': {'thk': 10.15, 'id': 28.00, 'wt': 9.56},
      }
    }),
    ComponentMetric(nps: '2"', dn: 50, od: 60.3, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 2.77, 'id': 54.76, 'wt': 3.93},
        'Sch 40 (STD)': {'thk': 3.91, 'id': 52.48, 'wt': 5.44},
        'Sch 80 (XS)': {'thk': 5.54, 'id': 49.22, 'wt': 7.48},
        'Sch 160': {'thk': 8.74, 'id': 42.82, 'wt': 11.11},
        'XXS': {'thk': 11.07, 'id': 38.16, 'wt': 13.44},
      }
    }),
    ComponentMetric(nps: '3"', dn: 80, od: 88.9, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 3.05, 'id': 82.80, 'wt': 6.46},
        'Sch 40 (STD)': {'thk': 5.49, 'id': 77.92, 'wt': 11.29},
        'Sch 80 (XS)': {'thk': 7.62, 'id': 73.66, 'wt': 15.27},
        'Sch 160': {'thk': 11.13, 'id': 66.64, 'wt': 21.35},
        'XXS': {'thk': 15.24, 'id': 58.42, 'wt': 27.68},
      }
    }),
    ComponentMetric(nps: '4"', dn: 100, od: 114.3, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 3.05, 'id': 108.20, 'wt': 8.37},
        'Sch 40 (STD)': {'thk': 6.02, 'id': 102.26, 'wt': 16.07},
        'Sch 80 (XS)': {'thk': 8.56, 'id': 97.18, 'wt': 22.32},
        'Sch 120': {'thk': 11.13, 'id': 92.04, 'wt': 28.32},
        'Sch 160': {'thk': 13.49, 'id': 87.32, 'wt': 33.54},
        'XXS': {'thk': 17.12, 'id': 80.06, 'wt': 41.03},
      }
    }),
    ComponentMetric(nps: '6"', dn: 150, od: 168.3, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 3.40, 'id': 161.50, 'wt': 13.82},
        'Sch 40 (STD)': {'thk': 7.11, 'id': 154.08, 'wt': 28.26},
        'Sch 80 (XS)': {'thk': 10.97, 'id': 146.36, 'wt': 42.56},
        'Sch 160': {'thk': 18.26, 'id': 131.78, 'wt': 67.56},
        'XXS': {'thk': 21.95, 'id': 124.40, 'wt': 79.22},
      }
    }),
    ComponentMetric(nps: '8"', dn: 200, od: 219.1, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 10': {'thk': 3.76, 'id': 211.58, 'wt': 19.97},
        'Sch 20': {'thk': 6.35, 'id': 206.40, 'wt': 33.31},
        'Sch 40 (STD)': {'thk': 8.18, 'id': 202.74, 'wt': 42.55},
        'Sch 80 (XS)': {'thk': 12.70, 'id': 193.70, 'wt': 64.64},
        'Sch 160': {'thk': 23.01, 'id': 173.08, 'wt': 111.27},
        'XXS': {'thk': 22.23, 'id': 174.64, 'wt': 107.92},
      }
    }),
    ComponentMetric(nps: '10"', dn: 250, od: 273.0, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 260.30, 'wt': 41.77},
        'Sch 40 (STD)': {'thk': 9.27, 'id': 254.46, 'wt': 60.31},
        'Sch 80 (XS)': {'thk': 15.09, 'id': 242.82, 'wt': 95.97},
        'Sch 160': {'thk': 28.58, 'id': 215.84, 'wt': 172.26},
      }
    }),
    ComponentMetric(nps: '12"', dn: 300, od: 323.8, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 311.10, 'wt': 49.73},
        'Sch 40 (STD)': {'thk': 10.31, 'id': 303.18, 'wt': 79.73},
        'Sch 80 (XS)': {'thk': 17.48, 'id': 288.84, 'wt': 132.08},
        'Sch 160': {'thk': 33.32, 'id': 257.16, 'wt': 238.68},
      }
    }),
    ComponentMetric(nps: '16"', dn: 400, od: 406.4, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 393.70, 'wt': 62.64},
        'Sch 40 (STD)': {'thk': 12.70, 'id': 381.00, 'wt': 123.30},
        'Sch 80 (XS)': {'thk': 21.44, 'id': 363.52, 'wt': 203.53},
        'Sch 160': {'thk': 40.49, 'id': 325.42, 'wt': 365.36},
      }
    }),
    ComponentMetric(nps: '20"', dn: 500, od: 508.0, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 495.30, 'wt': 78.55},
        'Sch 40 (STD)': {'thk': 15.09, 'id': 477.82, 'wt': 183.42},
        'Sch 80 (XS)': {'thk': 26.19, 'id': 455.62, 'wt': 311.17},
      }
    }),
    ComponentMetric(nps: '24"', dn: 600, od: 610.0, data: {
      'std': 'ASME B36.10M',
      'schedules': {
        'Sch 20': {'thk': 6.35, 'id': 597.30, 'wt': 94.46},
        'Sch 40 (STD)': {'thk': 17.48, 'id': 575.04, 'wt': 255.41},
        'Sch 80 (XS)': {'thk': 30.96, 'id': 448.08, 'wt': 441.97},
      }
    }),
  ];

  // ASME B16.5: مشخصات فلنج‌ها در کلاس‌های 150 تا 2500
  static const List<ComponentMetric> flanges = [
    ComponentMetric(nps: '1/2"', dn: 15, od: 89.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 89.0, 'thk': 11.1, 'pcd': 60.3, 'bolts': 4, 'boltDia': '1/2"', 'len': 50.0},
        'Class 300': {'od': 95.0, 'thk': 14.3, 'pcd': 66.7, 'bolts': 4, 'boltDia': '1/2"', 'len': 55.0},
        'Class 600': {'od': 95.0, 'thk': 14.3, 'pcd': 66.7, 'bolts': 4, 'boltDia': '1/2"', 'len': 60.0},
        'Class 900': {'od': 120.0, 'thk': 22.2, 'pcd': 82.6, 'bolts': 4, 'boltDia': '3/4"', 'len': 70.0},
        'Class 1500': {'od': 120.0, 'thk': 22.2, 'pcd': 82.6, 'bolts': 4, 'boltDia': '3/4"', 'len': 70.0},
        'Class 2500': {'od': 135.0, 'thk': 30.2, 'pcd': 88.9, 'bolts': 4, 'boltDia': '3/4"', 'len': 85.0},
      }
    }),
    ComponentMetric(nps: '1"', dn: 25, od: 108.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 108.0, 'thk': 14.3, 'pcd': 79.4, 'bolts': 4, 'boltDia': '1/2"', 'len': 55.0},
        'Class 300': {'od': 125.0, 'thk': 17.5, 'pcd': 88.9, 'bolts': 4, 'boltDia': '5/8"', 'len': 65.0},
        'Class 600': {'od': 125.0, 'thk': 17.5, 'pcd': 88.9, 'bolts': 4, 'boltDia': '5/8"', 'len': 70.0},
        'Class 900': {'od': 150.0, 'thk': 28.6, 'pcd': 101.6, 'bolts': 4, 'boltDia': '7/8"', 'len': 80.0},
        'Class 1500': {'od': 150.0, 'thk': 28.6, 'pcd': 101.6, 'bolts': 4, 'boltDia': '7/8"', 'len': 80.0},
        'Class 2500': {'od': 160.0, 'thk': 35.0, 'pcd': 108.0, 'bolts': 4, 'boltDia': '7/8"', 'len': 95.0},
      }
    }),
    ComponentMetric(nps: '2"', dn: 50, od: 152.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 152.0, 'thk': 19.1, 'pcd': 120.7, 'bolts': 4, 'boltDia': '5/8"', 'len': 65.0},
        'Class 300': {'od': 165.0, 'thk': 22.2, 'pcd': 127.0, 'bolts': 8, 'boltDia': '5/8"', 'len': 70.0},
        'Class 600': {'od': 165.0, 'thk': 25.4, 'pcd': 127.0, 'bolts': 8, 'boltDia': '5/8"', 'len': 80.0},
        'Class 900': {'od': 215.0, 'thk': 38.1, 'pcd': 165.1, 'bolts': 8, 'boltDia': '7/8"', 'len': 100.0},
        'Class 1500': {'od': 215.0, 'thk': 38.1, 'pcd': 165.1, 'bolts': 8, 'boltDia': '7/8"', 'len': 100.0},
        'Class 2500': {'od': 235.0, 'thk': 50.8, 'pcd': 171.5, 'bolts': 8, 'boltDia': '1"', 'len': 130.0},
      }
    }),
    ComponentMetric(nps: '4"', dn: 100, od: 229.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 229.0, 'thk': 23.8, 'pcd': 190.5, 'bolts': 8, 'boltDia': '5/8"', 'len': 75.0},
        'Class 300': {'od': 254.0, 'thk': 31.8, 'pcd': 200.0, 'bolts': 8, 'boltDia': '3/4"', 'len': 85.0},
        'Class 600': {'od': 273.0, 'thk': 38.1, 'pcd': 215.9, 'bolts': 8, 'boltDia': '7/8"', 'len': 100.0},
        'Class 900': {'od': 292.0, 'thk': 44.5, 'pcd': 235.0, 'bolts': 8, 'boltDia': '1-1/8"', 'len': 115.0},
        'Class 1500': {'od': 310.0, 'thk': 53.9, 'pcd': 241.3, 'bolts': 8, 'boltDia': '1-1/4"', 'len': 125.0},
        'Class 2500': {'od': 355.0, 'thk': 76.2, 'pcd': 273.1, 'bolts': 8, 'boltDia': '1-1/2"', 'len': 165.0},
      }
    }),
    ComponentMetric(nps: '8"', dn: 200, od: 343.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 343.0, 'thk': 28.6, 'pcd': 298.5, 'bolts': 8, 'boltDia': '3/4"', 'len': 100.0},
        'Class 300': {'od': 381.0, 'thk': 41.3, 'pcd': 330.2, 'bolts': 12, 'boltDia': '7/8"', 'len': 110.0},
        'Class 600': {'od': 420.0, 'thk': 55.6, 'pcd': 349.3, 'bolts': 12, 'boltDia': '1-1/8"', 'len': 125.0},
        'Class 900': {'od': 470.0, 'thk': 63.5, 'pcd': 393.7, 'bolts': 12, 'boltDia': '1-3/8"', 'len': 140.0},
      }
    }),
    ComponentMetric(nps: '12"', dn: 300, od: 483.0, data: {
      'std': 'ASME B16.5',
      'classes': {
        'Class 150': {'od': 483.0, 'thk': 31.8, 'pcd': 431.8, 'bolts': 12, 'boltDia': '7/8"', 'len': 115.0},
        'Class 300': {'od': 521.0, 'thk': 50.8, 'pcd': 450.9, 'bolts': 16, 'boltDia': '1-1/8"', 'len': 130.0},
        'Class 600': {'od': 559.0, 'thk': 66.7, 'pcd': 489.0, 'bolts': 20, 'boltDia': '1-1/4"', 'len': 155.0},
      }
    }),
  ];

  // ASME B16.9: اتصالات جوشی Butt-Weld
  static const List<ComponentMetric> buttWelds = [
    ComponentMetric(nps: '1/2"', dn: 15, od: 21.3, data: {'std': 'ASME B16.9', 'elbow90LR': 38.0, 'elbow90SR': 25.4, 'elbow45': 16.0, 'teeCtoE': 25.0, 'reducerH': 38.0, 'capL': 25.0}),
    ComponentMetric(nps: '3/4"', dn: 20, od: 26.7, data: {'std': 'ASME B16.9', 'elbow90LR': 38.0, 'elbow90SR': 25.4, 'elbow45': 19.0, 'teeCtoE': 29.0, 'reducerH': 38.0, 'capL': 25.0}),
    ComponentMetric(nps: '1"', dn: 25, od: 33.4, data: {'std': 'ASME B16.9', 'elbow90LR': 38.0, 'elbow90SR': 25.4, 'elbow45': 22.0, 'teeCtoE': 38.0, 'reducerH': 51.0, 'capL': 38.0}),
    ComponentMetric(nps: '1-1/2"', dn: 40, od: 48.3, data: {'std': 'ASME B16.9', 'elbow90LR': 57.0, 'elbow90SR': 38.0, 'elbow45': 29.0, 'teeCtoE': 48.0, 'reducerH': 64.0, 'capL': 38.0}),
    ComponentMetric(nps: '2"', dn: 50, od: 60.3, data: {'std': 'ASME B16.9', 'elbow90LR': 76.0, 'elbow90SR': 51.0, 'elbow45': 35.0, 'teeCtoE': 64.0, 'reducerH': 76.0, 'capL': 38.0}),
    ComponentMetric(nps: '3"', dn: 80, od: 88.9, data: {'std': 'ASME B16.9', 'elbow90LR': 114.0, 'elbow90SR': 76.0, 'elbow45': 51.0, 'teeCtoE': 86.0, 'reducerH': 89.0, 'capL': 51.0}),
    ComponentMetric(nps: '4"', dn: 100, od: 114.3, data: {'std': 'ASME B16.9', 'elbow90LR': 152.0, 'elbow90SR': 102.0, 'elbow45': 64.0, 'teeCtoE': 105.0, 'reducerH': 102.0, 'capL': 64.0}),
    ComponentMetric(nps: '6"', dn: 150, od: 168.3, data: {'std': 'ASME B16.9', 'elbow90LR': 229.0, 'elbow90SR': 152.0, 'elbow45': 95.0, 'teeCtoE': 143.0, 'reducerH': 140.0, 'capL': 89.0}),
    ComponentMetric(nps: '8"', dn: 200, od: 219.1, data: {'std': 'ASME B16.9', 'elbow90LR': 305.0, 'elbow90SR': 203.0, 'elbow45': 127.0, 'teeCtoE': 178.0, 'reducerH': 152.0, 'capL': 102.0}),
    ComponentMetric(nps: '10"', dn: 250, od: 273.0, data: {'std': 'ASME B16.9', 'elbow90LR': 381.0, 'elbow90SR': 254.0, 'elbow45': 159.0, 'teeCtoE': 216.0, 'reducerH': 178.0, 'capL': 127.0}),
    ComponentMetric(nps: '12"', dn: 300, od: 323.8, data: {'std': 'ASME B16.9', 'elbow90LR': 457.0, 'elbow90SR': 305.0, 'elbow45': 190.0, 'teeCtoE': 254.0, 'reducerH': 203.0, 'capL': 152.0}),
  ];

  // ASME B16.11: اتصالات سوکت‌ولد Socket-Weld
  static const List<ComponentMetric> socketWelds = [
    ComponentMetric(nps: '1/2"', dn: 15, od: 33.0, data: {'std': 'ASME B16.11', 'bore': 21.8, 'depth': 9.5, 'cToE': 24.5, 'minWall': 4.67, 'gap': 1.6, 'class': 3000}),
    ComponentMetric(nps: '3/4"', dn: 20, od: 39.0, data: {'std': 'ASME B16.11', 'bore': 27.2, 'depth': 12.5, 'cToE': 28.5, 'minWall': 4.90, 'gap': 1.6, 'class': 3000}),
    ComponentMetric(nps: '1"', dn: 25, od: 46.5, data: {'std': 'ASME B16.11', 'bore': 33.9, 'depth': 12.5, 'cToE': 34.0, 'minWall': 5.69, 'gap': 1.6, 'class': 3000}),
    ComponentMetric(nps: '1-1/2"', dn: 40, od: 63.5, data: {'std': 'ASME B16.11', 'bore': 48.8, 'depth': 12.5, 'cToE': 43.5, 'minWall': 6.35, 'gap': 1.6, 'class': 3000}),
    ComponentMetric(nps: '2"', dn: 50, od: 76.0, data: {'std': 'ASME B16.11', 'bore': 61.2, 'depth': 16.0, 'cToE': 47.5, 'minWall': 6.93, 'gap': 1.6, 'class': 3000}),
    ComponentMetric(nps: '3"', dn: 80, od: 109.0, data: {'std': 'ASME B16.11', 'bore': 89.8, 'depth': 16.0, 'cToE': 78.0, 'minWall': 8.76, 'gap': 1.6, 'class': 3000}),
  ];

  // ASME B16.11 / NPT: اتصالات رزوه‌ای Threaded
  static const List<ComponentMetric> threadeds = [
    ComponentMetric(nps: '1/2"', dn: 15, od: 33.0, data: {'std': 'ASME B16.11 / NPT', 'cToE': 25.0, 'minThreadL2': 13.5, 'tpi': 14, 'taper': '1:16', 'class': 3000}),
    ComponentMetric(nps: '3/4"', dn: 20, od: 39.0, data: {'std': 'ASME B16.11 / NPT', 'cToE': 28.5, 'minThreadL2': 14.0, 'tpi': 14, 'taper': '1:16', 'class': 3000}),
    ComponentMetric(nps: '1"', dn: 25, od: 46.5, data: {'std': 'ASME B16.11 / NPT', 'cToE': 34.0, 'minThreadL2': 17.5, 'tpi': 11.5, 'taper': '1:16', 'class': 3000}),
    ComponentMetric(nps: '1-1/2"', dn: 40, od: 63.5, data: {'std': 'ASME B16.11 / NPT', 'cToE': 43.5, 'minThreadL2': 18.5, 'tpi': 11.5, 'taper': '1:16', 'class': 3000}),
    ComponentMetric(nps: '2"', dn: 50, od: 76.0, data: {'std': 'ASME B16.11 / NPT', 'cToE': 52.5, 'minThreadL2': 19.5, 'tpi': 11.5, 'taper': '1:16', 'class': 3000}),
    ComponentMetric(nps: '3"', dn: 80, od: 109.0, data: {'std': 'ASME B16.11 / NPT', 'cToE': 78.0, 'minThreadL2': 26.5, 'tpi': 8, 'taper': '1:16', 'class': 3000}),
  ];
}
