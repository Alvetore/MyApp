// lib/services/steam_library_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'steam_models.dart';

/// Простой кеш библиотеки пользователя в SharedPreferences
class SteamLibraryCache {
  static const _key = 'cachedGames';

  /// Сохраняет список игр
  Future<void> saveGames(List<GameRecord> games) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Загружает из кеша (или возвращает пустой список)
  Future<List<GameRecord>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return [];
    final list = jsonDecode(str) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => GameRecord.fromJson(m))
        .toList();
  }

  /// Очистка кеша
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
