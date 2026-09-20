import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/core/component_icons.dart';
import 'package:pipedata_pro/core/models.dart';

void main() {
  group('categoryIconAssets', () {
    test('every ComponentCategory except valve has an asset entry', () {
      for (final category in ComponentCategory.values) {
        if (category == ComponentCategory.valve) continue; // handled by valveIconAssets instead
        expect(categoryIconAssets.containsKey(category), isTrue, reason: 'missing icon asset for $category');
        expect(categoryIconAssets[category], isNotEmpty);
      }
    });
  });

  group('valveIconAssets', () {
    test('every valve type used elsewhere in the app has a matching icon asset entry', () {
      // Kept in sync by hand with the _valveTypes lists in category_detail_screen.dart
      // and compare_screen.dart — if a new valve type is ever added there without an
      // icon here, resolveIconAsset() would throw a null-check at runtime instead of
      // failing a test.
      const usedValveTypes = ['Gate Valve', 'Globe Valve', 'Ball Valve', 'Swing Check Valve'];
      for (final type in usedValveTypes) {
        expect(valveIconAssets.containsKey(type), isTrue, reason: 'missing icon asset for $type');
        expect(valveIconAssets[type], isNotEmpty);
      }
    });
  });

  group('resolveIconAsset', () {
    test('returns the valve-type-specific asset for valve, ignoring category map', () {
      expect(resolveIconAsset(ComponentCategory.valve, valveType: 'Ball Valve'), valveIconAssets['Ball Valve']);
    });

    test('falls back to Gate Valve for an unrecognized valve type', () {
      expect(resolveIconAsset(ComponentCategory.valve, valveType: 'Nonexistent Valve'), valveIconAssets['Gate Valve']);
    });

    test('returns the category asset for every non-valve category', () {
      for (final category in ComponentCategory.values) {
        if (category == ComponentCategory.valve) continue;
        expect(resolveIconAsset(category), categoryIconAssets[category]);
      }
    });

    test('pipe and pipelineTransport share the same asset (same physical product)', () {
      expect(resolveIconAsset(ComponentCategory.pipe), resolveIconAsset(ComponentCategory.pipelineTransport));
    });
  });
}
