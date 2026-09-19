import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipedata_pro/core/favorites.dart';
import 'package:pipedata_pro/core/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoriteEntry', () {
    test('key round-trips through fromKey', () {
      const entry = FavoriteEntry(category: ComponentCategory.flange, index: 3, subSelection: 'Class 300');
      final parsed = FavoriteEntry.fromKey(entry.key);
      expect(parsed, isNotNull);
      expect(parsed!.category, ComponentCategory.flange);
      expect(parsed.index, 3);
      expect(parsed.subSelection, 'Class 300');
    });

    test('fromKey returns null for malformed or unknown-category keys', () {
      expect(FavoriteEntry.fromKey('not-enough-parts'), isNull);
      expect(FavoriteEntry.fromKey('bogusCategory|1|x|y'), isNull);
      expect(FavoriteEntry.fromKey('flange|not-an-int|x|y'), isNull);
    });
  });

  group('FavoritesController', () {
    test('toggle adds/removes and persists across a fresh controller instance', () async {
      SharedPreferences.setMockInitialValues({});
      final c1 = FavoritesController();
      await c1.init();
      const entry = FavoriteEntry(category: ComponentCategory.valve, index: 0, subSelection: 'Class 150', valveType: 'Gate Valve');

      expect(c1.isFavorite(entry), isFalse);
      await c1.toggle(entry);
      expect(c1.isFavorite(entry), isTrue);

      final c2 = FavoritesController();
      await c2.init();
      expect(c2.isFavorite(entry), isTrue, reason: 'a second controller instance should read what the first one persisted');

      await c2.toggle(entry);
      expect(c2.isFavorite(entry), isFalse);
    });
  });
}
