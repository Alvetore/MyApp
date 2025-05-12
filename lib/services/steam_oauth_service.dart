// lib/services/steam_oauth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import 'steam_models.dart';

/// Сервис для логина через Steam OpenID и получения списка игр
class SteamOAuthService {
  final String _apiKey = Config.steamApiKey;
  final String _redirectUri = Config.steamRedirectUri;

  /// Запускает браузер для OpenID авторизации Steam и возвращает steamID64
  Future<String> signInWithSteam() async {
    final params = {
      'openid.ns': 'http://specs.openid.net/auth/2.0',
      'openid.mode': 'checkid_setup',
      'openid.return_to': _redirectUri,
      'openid.realm': _redirectUri,
      'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
      'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select',
    };
    final uri = Uri.https('steamcommunity.com', '/openid/login', params);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Не удалось открыть браузер для авторизации в Steam';
    }

    // *** ВАЖНО *** здесь нужно перехватить ваш deep link (redirect URI) и получить полный URL
    final fullUrl = await _listenForRedirect();
    final returned = Uri.parse(fullUrl);
    final claimedId = returned.queryParameters['openid.claimed_id'];
    if (claimedId == null) throw 'Не удалось получить SteamID';
    return claimedId.split('/').last;
  }

  /// Заглушка для примера — вы должны реализовать deep link handler
  Future<String> _listenForRedirect() async {
    // TODO: используйте uni_links или аналог, чтобы получить URL, на который вернулся пользователь
    throw 'Deep link listener не настроен';
  }

  /// Через Web API Steam возвращает список игр
  Future<List<GameRecord>> fetchOwnedGames(String steamId) async {
    final uri = Uri.https(
      'api.steampowered.com',
      '/IPlayerService/GetOwnedGames/v1/',
      {
        'key': _apiKey,
        'steamid': steamId,
        'include_appinfo': 'true',
        'include_played_free_games': 'true',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw 'Ошибка при запросе owned games: ${res.statusCode}';
    }
    final body = jsonDecode(res.body)['response'] as Map<String, dynamic>;
    final rawGames = body['games'] as List<dynamic>? ?? [];
    return rawGames
        .cast<Map<String, dynamic>>()
        .map((g) => GameRecord.fromSteamApi(g))
        .toList();
  }
}
