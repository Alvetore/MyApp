import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для поиска игр через Steam Store API
class SteamDbService {
  /// Поиск игр по части названия:
  /// https://store.steampowered.com/api/storesearch?term=<query>&l=en&cc=US
  Future<List<Map<String, String>>> searchGames(String query) async {
    // Экранируем пробелы и спецсимволы
    final encoded = Uri.encodeQueryComponent(query);
    final url = Uri.parse(
      'https://store.steampowered.com/api/storesearch'
          '?term=$encoded&l=en&cc=US',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Steam Store search failed: ${res.statusCode}');
    }

    final body = jsonDecode(res.body);
    // Ожидаем, что в ответе есть ключ "items" с массивом
    final items = (body['items'] as List<dynamic>?) ?? [];

    // Превращаем каждый элемент в { 'name': ..., 'id': ... }
    return items.map((e) {
      return {
        'name': e['name'].toString(),
        'id': e['id'].toString(),
      };
    }).toList();
  }
}
