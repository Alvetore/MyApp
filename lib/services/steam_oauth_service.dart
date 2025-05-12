// lib/services/steam_oauth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class SteamOAuthService {
  final _apiKey   = STEAM_API_KEY;
  final _clientId = STEAM_CLIENT_ID;

  /// OpenID-логин в Steam, возвращает SteamID64
  Future<String> signInWithSteam() async {
    final issuer = await Issuer.discover(
        Uri.parse('https://steamcommunity.com/openid')
    );
    final client = Client(issuer, _clientId);

    final authenticator = Authenticator(
      client,
      port: 4000,
      urlLancher: (url) async {
        final uri = Uri.parse(url.toString());
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Не удалось открыть браузер';
        }
      },
      scopes: ['openid'],
      redirectUri: Uri.parse(_clientId),
    );

    // ждем перенаправления на localhost:4000
    final credential = await authenticator.authorize();
    final tokenResponse = await credential.getTokenResponse();
    final rawIdToken = tokenResponse.idToken?.raw;
    if (rawIdToken == null) {
      throw 'Не получили id_token';
    }
    return _extractSteamIdFromJwt(rawIdToken);
  }

  /// Получает «сырые» игры пользователя из Steam Web API
  Future<List<Map<String, dynamic>>> fetchOwnedGames(String steamId) async {
    final uri = Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/'
            '?key=$_apiKey'
            '&steamid=$steamId'
            '&include_appinfo=true'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw 'Ошибка при загрузке списка игр: ${res.statusCode}';
    }
    final data = json.decode(res.body)['response'] as Map<String, dynamic>;
    final games = (data['games'] as List)
        .map((g) => {
      'appid': g['appid'],
      'name':  g['name'],
    })
        .toList();
    return games;
  }

  String _extractSteamIdFromJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) throw 'Неверный JWT';
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(decoded) as Map<String, dynamic>;
    final claimed = map['openid.claimed_id'] as String?;
    if (claimed == null) throw 'openid.claimed_id не найден';
    return claimed.split('/').last;
  }
}
