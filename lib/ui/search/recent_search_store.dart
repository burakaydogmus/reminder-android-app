import 'package:shared_preferences/shared_preferences.dart';

import 'package:reminder/domain/text_search.dart';

/// Recent search queries (§3.3.8 "Son aramalar"), newest first.
///
/// Stored in SharedPreferences under [key] as a string list; at most
/// [maxEntries], duplicates (Turkish-insensitive) collapse to the newest
/// spelling.
class RecentSearchStore {
  const RecentSearchStore();

  static const String key = 'search_recent_v1';
  static const int maxEntries = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return List.unmodifiable(prefs.getStringList(key) ?? const <String>[]);
  }

  /// Adds [query] (trimmed) to the front and returns the new list.
  Future<List<String>> add(String query) async {
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(key) ?? const <String>[];
    if (q.isEmpty) return List.unmodifiable(current);
    final folded = TextSearch.fold(q);
    final next = [
      q,
      for (final e in current)
        if (TextSearch.fold(e) != folded) e,
    ].take(maxEntries).toList();
    await prefs.setStringList(key, next);
    return List.unmodifiable(next);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
