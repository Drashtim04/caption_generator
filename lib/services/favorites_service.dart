import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_entry.dart';

class FavoritesService {
  static const _key = 'caption_favorites';

  Future<List<FavoriteEntry>> fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => FavoriteEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addFavorite(FavoriteEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readRawList(prefs);

    // Avoid duplicates by id
    if (list.any((e) => e['id'] == entry.id)) return;

    list.add(entry.toMap());
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readRawList(prefs);
    list.removeWhere((e) => e['id'] == id);
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<Map<String, dynamic>>> _readRawList(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
