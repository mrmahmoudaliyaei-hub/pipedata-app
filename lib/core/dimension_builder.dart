import 'models.dart';
import 'units.dart';

/// Builds the ordered {label: value} rows for a category's "Dimensions" tab.
///
/// Extracted out of CategoryDetailScreen so CompareScreen can render the
/// exact same fields for two items side by side without a second,
/// drifting copy of this switch statement.
Map<String, String> buildDimensionRows({
  required ComponentCategory category,
  required Map<String, dynamic> item,
  required String subSelection,
  String valveType = 'Gate Valve',
}) {
  final Map<String, String> d = {};
  d['Nominal Pipe Size (NPS)'] = item['nps'] as String;
  if (item.containsKey('dn')) d['Diameter Nominal'] = 'DN ${item['dn']}';

  switch (category) {
    case ComponentCategory.pipe:
    case ComponentCategory.pipelineTransport:
      final schs = item['schedules'] as Map<String, dynamic>;
      final s = schs[subSelection] ?? schs.values.first;
      d['Outside Diameter (OD)'] = unitsController.format(item['od'] as num);
      d['Schedule / Wall Class'] = subSelection;
      d['Wall Thickness (t)'] = unitsController.format(s['thk'] as num);
      d['Inside Diameter (ID)'] = unitsController.format(s['id'] as num);
      d['Linear Weight'] = '${s['wt']} kg/m';
      break;
    case ComponentCategory.flange:
      final clss = item['classes'] as Map<String, dynamic>;
      final f = clss[subSelection] ?? clss.values.first;
      d['Pressure Rating'] = subSelection;
      d['Flange Outside Diameter (O)'] = unitsController.format(f['od'] as num);
      d['Minimum Flange Thickness (C)'] = unitsController.format(f['thk'] as num);
      d['Pitch Circle Diameter (PCD)'] = unitsController.format(f['pcd'] as num);
      break;
    case ComponentCategory.tee:
      d['Center-to-End (C)'] = unitsController.format(item['teeCtoE'] as num);
      d['Standard'] = 'ASME B16.9 Equal Tee';
      break;
    case ComponentCategory.elbow:
      final angles = item['angles'] as Map<String, dynamic>;
      final lenMm = (angles[subSelection] ?? angles.values.first) as num;
      d['Pattern'] = subSelection;
      d['Center-to-End (C)'] = unitsController.format(lenMm);
      d['Standard'] = 'ASME B16.9';
      break;
    case ComponentCategory.cap:
      d['Length (E)'] = unitsController.format(item['capLen'] as num);
      d['Standard'] = 'ASME B16.9 Domed Cap';
      break;
    case ComponentCategory.socketWeld:
      d['Socket Bore Diameter'] = unitsController.format(item['boreDia'] as num);
      d['Socket Minimum Depth'] = unitsController.format(item['depth'] as num);
      d['Center-to-End Distance'] = unitsController.format(item['cToE'] as num);
      d['Fitting Minimum Wall'] = unitsController.format(item['minWall'] as num);
      d['Thermal Fit-up Gap'] = '1.6 mm (1/16")';
      break;
    case ComponentCategory.threaded:
      d['Threads per Inch (TPI)'] = '${item['tpi']}';
      d['Thread Pitch (p)'] = unitsController.format(item['pitch'] as num, mmDecimals: 3);
      d['Effective Thread Length (L2)'] = unitsController.format(item['minThreadL2'] as num);
      d['Standard Taper Ratio'] = '${item['taper']}';
      break;
    case ComponentCategory.reducer:
      final lens = item['lengths'] as Map<String, dynamic>;
      final lenMm = (lens[subSelection] ?? lens.values.first) as num;
      d['Reduction Pattern'] = subSelection;
      d['Large End DN'] = 'DN ${item['largeDn']}';
      d['Small End DN'] = 'DN ${item['smallDn']}';
      d['Center-to-End Length (H)'] = unitsController.format(lenMm, mmDecimals: 0);
      d['Standard'] = 'ASME B16.9';
      break;
    case ComponentCategory.gasket:
      final clss = item['classes'] as Map<String, dynamic>;
      final g = clss[subSelection] ?? clss.values.first;
      d['Pressure Class'] = subSelection;
      d['Gasket Inside Diameter (ID)'] = unitsController.format(g['id'] as num);
      d['Gasket Outside Diameter (OD)'] = unitsController.format(g['od'] as num);
      d['Nominal Thickness'] = unitsController.format(g['thk'] as num);
      d['Style'] = 'Spiral-Wound, CG (316L windings / flexible graphite filler)';
      d['Standard'] = 'ASME B16.20';
      break;
    case ComponentCategory.valve:
      final types = item['types'] as Map<String, dynamic>;
      final classesForType = types[valveType] as Map<String, dynamic>;
      final v = classesForType[subSelection] ?? classesForType.values.first;
      d['Valve Type'] = valveType;
      d['Pressure Class'] = subSelection;
      d['Face-to-Face (FtF)'] = unitsController.format(v['ftf'] as num);
      d['End Connection'] = (v['endConn'] as String?) ?? 'Raised Face Flanged (RF)';
      if (valveType == 'Globe Valve' || valveType == 'Swing Check Valve') {
        d['Note'] = 'Globe & Swing Check share the ASME B16.10 long-pattern length at this size/class';
      }
      d['Standard'] = 'ASME B16.10';
      break;
    case ComponentCategory.weldolet:
      d['Outlet Height (A)'] = unitsController.format(item['height'] as num);
      d['End Connection'] = 'Butt-Weld Outlet';
      d['Standard'] = 'MSS SP-97 (size-on-size, STD)';
      break;
    case ComponentCategory.sockolet:
      d['Outlet Height (A)'] = unitsController.format(item['height'] as num);
      d['Socket Depth'] = unitsController.format(item['socketDepth'] as num);
      d['End Connection'] = 'Socket-Weld Outlet';
      d['Standard'] = 'MSS SP-97 (size-on-size, Class 3000)';
      break;
    case ComponentCategory.threadolet:
      d['Outlet Height (A)'] = unitsController.format(item['height'] as num);
      d['End Connection'] = 'NPT Threaded Outlet';
      d['Standard'] = 'MSS SP-97 (size-on-size, Class 3000)';
      break;
  }

  return d;
}
