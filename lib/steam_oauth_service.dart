import 'package:openid_client/openid_client_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SteamOAuthService {
  // Ваш ключ, положите в config.dart
  final _apiKey = Config.STEAM_API_KEY;

  /// Запускает OpenID-процесс, возвращает steamId
  Future<String?> signInWithSteam() async {
    final issuer = await Issuer.discover(Uri.parse('https://steamcommunity.com/openid'));
    final client = Client(issuer, 'https://your-redirect-uri/');
    final authenticator = Authenticator(client,
      scopes: ['openid'], // Steam поддерживает только openid
      port: 4000,
      redirectUri: Uri.parse('https://your-redirect-uri/'),
    );
    final c = await authenticator.authorize();
    final token = await c.getTokenResponse();
    // Steam выдает Claim openid.claimed_id вида ".../id/7656119XXXXXXXXX"
    final claimed = token.idToken['openid.claimed_id'] as String;
    final steamId = claimed.split('/').last;
    return steamId;
  }

  /// Получает список игр через Web API
  Future<List<GameRecord>> fetchOwnedGames(String steamId) async {
    final url = Uri.https('api.steampowered.com', '/IPlayerService/GetOwnedGames/v1/', {
      'key': _apiKey,
      'steamid': steamId,
      'include_appinfo': 'true',
      'include_played_free_games': 'true',
    });
    final resp = await http.get(url);
    final data = jsonDecode(resp.body)['response'];
    return (data['games'] as List).map((g) => GameRecord.fromSteamApi(g)).toList();
  }
}
