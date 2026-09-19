import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/core/units.dart';

void main() {
  group('UnitsController', () {
    test('defaults to mm and formats with the mm suffix', () {
      final c = UnitsController();
      expect(c.value, LengthUnit.mm);
      expect(c.format(25.4), '25.40 mm');
    });

    test('toggle switches to inch and converts correctly (25.4mm == 1.000")', () {
      final c = UnitsController();
      c.toggle();
      expect(c.value, LengthUnit.inch);
      expect(c.format(25.4), '1.000"');
    });

    test('toggle is reversible', () {
      final c = UnitsController();
      c.toggle();
      c.toggle();
      expect(c.value, LengthUnit.mm);
    });

    test('respects custom decimal places', () {
      final c = UnitsController()..toggle();
      expect(c.format(609.6, inchDecimals: 1), '24.0"');
    });
  });
}
