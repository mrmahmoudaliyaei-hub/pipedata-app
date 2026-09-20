import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/core/valve_icons.dart';

void main() {
  test('every valve type used by the app has a matching icon asset entry', () {
    // Kept in sync by hand with the _valveTypes lists in category_detail_screen.dart
    // and compare_screen.dart — if a new valve type is ever added there without an
    // icon here, Image.asset(valveIconAssets[valveType]!) would throw a null-check
    // at runtime instead of failing a test.
    const usedValveTypes = ['Gate Valve', 'Globe Valve', 'Ball Valve', 'Swing Check Valve'];
    for (final type in usedValveTypes) {
      expect(valveIconAssets.containsKey(type), isTrue, reason: 'missing icon asset for $type');
      expect(valveIconAssets[type], isNotEmpty);
    }
  });
}
