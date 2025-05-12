// lib/import_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'services/steam_oauth_service.dart';
import 'services/steam_library_cache.dart';
import 'services/steam_models.dart';

/// Экран импорта библиотеки: либо по URL/XML, либо через OAuth
class ImportProfileScreen extends StatefulWidget {
  const ImportProfileScreen({Key? key}) : super(key: key);

  @override
  State<ImportProfileScreen> createState() => _ImportProfileScreenState();
}

class _ImportProfileScreenState extends State<ImportProfileScreen> {
  final _profileCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _importViaUrl() async {
    setState(() => _loading = true);
    _error = null;
    try {
      final input = _profileCtrl.text.trim();
      if (input.isEmpty) throw 'Введите vanity, URL или SteamID64';
      final base = input.contains('steamcommunity.com')
          ? input
          : (int.tryParse(input) != null
          ? 'https://steamcommunity.com/profiles/$input'
          : 'https://steamcommunity.com/id/$input');
      final profileUrl = Uri.parse(base.contains('?') ? '$base&xml=1' : '$base?xml=1');
      final pr = await http.get(profileUrl);
      if (pr.statusCode != 200) throw 'Профиль не найден';
      final doc = XmlDocument.parse(pr.body);
      final steamId = doc.findAllElements('steamID64').first.text;
      final gamesDoc = XmlDocument.parse(
        (await http.get(Uri.parse('https://steamcommunity.com/profiles/$steamId/games?xml=1'))).body,
      );
      final games = gamesDoc
          .findAllElements('game')
          .map((g) => GameRecord(
        appid: g.findElements('appID').first.text,
        name: g.findElements('name').first.text,
        playtime: int.tryParse(
            g.findElements('hoursOnRecord').first.text.split(' ').first) ??
            0,
      ))
          .toList();
      await SteamLibraryCache().saveGames(games);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importViaSteamLogin() async {
    setState(() => _loading = true);
    _error = null;
    try {
      final steamId = await SteamOAuthService().signInWithSteam();
      final games = await SteamOAuthService().fetchOwnedGames(steamId);
      await SteamLibraryCache().saveGames(games);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт библиотеки Steam')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _profileCtrl,
              decoration: InputDecoration(
                labelText: 'Vanity / URL / SteamID64',
                errorText: _error,
                suffixIcon: _loading
                    ? const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _importViaUrl,
                ),
              ),
              onSubmitted: (_) => _importViaUrl(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _importViaUrl,
              child: const Text('Импорт по ссылке'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Войти через Steam'),
              onPressed: _loading ? null : _importViaSteamLogin,
            ),
          ],
        ),
      ),
    );
  }
}
