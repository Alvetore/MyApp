// lib/services/steam_oauth_service.dart

import 'dart:convert';
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';

class SteamOAuthService {
  final String _apiKey = Config.STEAM_API_KEY;
  final String _clientId = Config.STEAM_CLIENT_ID; // http://localhost:4000

  /// Запускает OpenID-авторизацию через браузер и возвращает SteamID64
  Future<String> signInWithSteam() async {
    // 1) Открываем Discovery-URL для Steam OpenID
    final issuer = await Issuer.discover(Uri.parse('https://steamcommunity.com/openid'));
    final client = Client(issuer, _clientId);

    // 2) Настраиваем авторизатор и собираем URL
    final authenticator = Authenticator(
      client,
      port: 4000,               // порт для локального callback
      urlLancher: (url) async { // функция открытия браузера
        final uri = Uri.parse(url.toString());
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Не удалось открыть браузер: $uri';
        }
      },
      scopes: ['openid'],
      redirectUri: Uri.parse(_clientId),
    );

    // 3) Запускаем локальный HTTP-сервер, ждём редиректа и финализируем логин
    final credential = await authenticator.authorize();

    // 4) После успешного редиректа получаем токены
    final tokenResponse = await credential.getTokenResponse();
    final rawIdToken = tokenResponse.idToken;
    if (rawIdToken == null) {
      throw 'Не получили id_token от Steam';
    }

    // 5) Распаковываем JWT и вытаскиваем из него SteamID64
    return _extractSteamIdFromJwt(rawIdToken);
  }

  String _extractSteamIdFromJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) throw 'Неверный JWT';
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(decoded) as Map<String, dynamic>;
    // Steam кладёт вашу ссылку в claim 'openid.claimed_id'
    final claimedId = map['openid.claimed_id'] as String?;
    if (claimedId == null) throw 'openid.claimed_id не найден';
    // извлекаем 64-битный SteamID
    return claimedId.split('/').last;
  }
}
