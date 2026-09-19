import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/core/models.dart';

/// Structural sanity checks across PipingMasterCatalog datasets — these catch
/// the class of copy/paste and typo errors that a single hand-review can
/// miss (e.g. the NPS 24" Sch 80 (XS) pipe ID bug fixed in this same commit).
/// They check physically-necessary relationships, not exact reference
/// values, so they won't flag a merely-imprecise-but-plausible number.
void main() {
  group('Flanges', () {
    test('PCD is always smaller than flange OD, for every size/class', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.flanges) {
        final classes = row['classes'] as Map<String, dynamic>;
        classes.forEach((cls, c) {
          final od = (c['od'] as num).toDouble();
          final pcd = (c['pcd'] as num).toDouble();
          if (pcd >= od) failures.add('${row['nps']} $cls: pcd=$pcd od=$od');
        });
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });

    test('bolt count is a positive even number (flanges always have an even bolt pattern)', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.flanges) {
        final classes = row['classes'] as Map<String, dynamic>;
        classes.forEach((cls, c) {
          final bolts = c['bolts'] as int;
          if (bolts <= 0 || bolts.isOdd) failures.add('${row['nps']} $cls: bolts=$bolts');
        });
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });

  group('Gaskets', () {
    test('gasket ID is always smaller than gasket OD', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.gaskets) {
        final classes = row['classes'] as Map<String, dynamic>;
        classes.forEach((cls, g) {
          final id = (g['id'] as num).toDouble();
          final od = (g['od'] as num).toDouble();
          if (id >= od) failures.add('${row['nps']} $cls: id=$id od=$od');
        });
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });

  group('Valves', () {
    test('face-to-face length never decreases as pressure class increases, per type/size', () {
      const classOrder = ['Class 150', 'Class 300', 'Class 600', 'Class 900', 'Class 1500', 'Class 2500'];
      final failures = <String>[];
      for (final row in PipingMasterCatalog.valves) {
        final types = row['types'] as Map<String, dynamic>;
        types.forEach((valveType, classes) {
          final present = classOrder.where((c) => (classes as Map).containsKey(c)).toList();
          for (int i = 1; i < present.length; i++) {
            final prev = ((classes as Map)[present[i - 1]]['ftf'] as num).toDouble();
            final cur = (classes[present[i]]['ftf'] as num).toDouble();
            if (cur < prev) {
              failures.add('${row['nps']} $valveType: ${present[i - 1]}=$prev -> ${present[i]}=$cur');
            }
          }
        });
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });

  group('Reducers', () {
    test('large end DN is always greater than small end DN', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.reducers) {
        final largeDn = row['largeDn'] as int;
        final smallDn = row['smallDn'] as int;
        if (largeDn <= smallDn) failures.add('${row['nps']}: largeDn=$largeDn smallDn=$smallDn');
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });

  group('Elbows / Tees / Caps', () {
    test('all center-to-end / length values are positive', () {
      final failures = <String>[];
      for (final row in PipingMasterCatalog.elbows) {
        final angles = row['angles'] as Map<String, dynamic>;
        angles.forEach((angle, len) {
          if ((len as num) <= 0) failures.add('elbow ${row['nps']} $angle: $len');
        });
      }
      for (final row in PipingMasterCatalog.tees) {
        if ((row['teeCtoE'] as num) <= 0) failures.add('tee ${row['nps']}: ${row['teeCtoE']}');
      }
      for (final row in PipingMasterCatalog.caps) {
        if ((row['capLen'] as num) <= 0) failures.add('cap ${row['nps']}: ${row['capLen']}');
      }
      expect(failures, isEmpty, reason: failures.join('; '));
    });
  });
}
