// lib/services/steam_library_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'steam_models.dart';

class SteamLibraryCache {
  static const _key = 'importedGames';

  Future<void> saveGames(List<GameRecord> games) async {
    final prefs = await SharedPreferences.getInstance();
    final list = games.map((g) => g.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<GameRecord>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return [];
    final list = jsonDecode(str) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(GameRecord.fromJson)
        .toList();
  }
}
