import 'package:flutter/material.dart';
import '../models/favorite_entry.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final _service = FavoritesService();

  List<FavoriteEntry> _favorites = [];
  List<FavoriteEntry> get favorites => List.unmodifiable(_favorites);

  bool _loaded = false;

  Future<void> loadFavorites() async {
    if (_loaded) return;
    _favorites = await _service.fetchFavorites();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reloadFavorites() async {
    _favorites = await _service.fetchFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.any((f) => f.id == id);

  Future<void> addFavorite(FavoriteEntry entry) async {
    if (isFavorite(entry.id)) return;
    await _service.addFavorite(entry);
    _favorites = [entry, ..._favorites];
    notifyListeners();
  }

  Future<void> removeFavorite(String id) async {
    await _service.removeFavorite(id);
    _favorites = _favorites.where((f) => f.id != id).toList();
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    await _service.clearFavorites();
    _favorites = [];
    notifyListeners();
  }
}
