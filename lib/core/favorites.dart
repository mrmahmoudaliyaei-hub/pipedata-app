import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// One bookmarked (category, size, sub-option) combination — e.g.
/// "4" Flange, Class 300" or "6" Elbow, 90° Long Radius".
class FavoriteEntry {
  final ComponentCategory category;
  final int index;
  final String subSelection;
  final String valveType;

  const FavoriteEntry({
    required this.category,
    required this.index,
    required this.subSelection,
    this.valveType = 'Gate Valve',
  });

  String get key => '${category.name}|$index|$subSelection|$valveType';

  static FavoriteEntry? fromKey(String raw) {
    final parts = raw.split('|');
    if (parts.length != 4) return null;
    final matches = ComponentCategory.values.where((c) => c.name == parts[0]);
    if (matches.isEmpty) return null;
    final idx = int.tryParse(parts[1]);
    if (idx == null) return null;
    return FavoriteEntry(category: matches.first, index: idx, subSelection: parts[2], valveType: parts[3]);
  }

  @override
  bool operator ==(Object other) => other is FavoriteEntry && other.key == key;
  @override
  int get hashCode => key.hashCode;
}

/// App-wide favorites, backed by SharedPreferences.
///
/// Call [init] once in main() before runApp() so every later read
/// (isFavorite / entries) is synchronous — same "load once, then sync"
/// pattern as the rest of this app's global state (see UnitsController).
class FavoritesController extends ChangeNotifier {
  static const _prefsKey = 'favorite_entries_v1';
  SharedPreferences? _prefs;
  final List<String> _keys = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _keys
      ..clear()
      ..addAll(_prefs?.getStringList(_prefsKey) ?? const []);
  }

  bool isFavorite(FavoriteEntry entry) => _keys.contains(entry.key);

  Future<void> toggle(FavoriteEntry entry) async {
    if (_keys.contains(entry.key)) {
      _keys.remove(entry.key);
    } else {
      _keys.add(entry.key);
    }
    notifyListeners();
    await _prefs?.setStringList(_prefsKey, _keys);
  }

  List<FavoriteEntry> get entries =>
      _keys.map(FavoriteEntry.fromKey).whereType<FavoriteEntry>().toList().reversed.toList();
}

/// One instance shared across the whole app.
final FavoritesController favoritesController = FavoritesController();
