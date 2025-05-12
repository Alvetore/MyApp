// lib/steam_login_screen.dart
import 'package:flutter/material.dart';
import 'services/steam_oauth_service.dart';
import 'services/steam_models.dart';
import 'services/steam_library_cache.dart';

class SteamLoginScreen extends StatefulWidget {
  const SteamLoginScreen({Key? key}) : super(key: key);
  @override
  State<SteamLoginScreen> createState() => _SteamLoginScreenState();
}

class _SteamLoginScreenState extends State<SteamLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _loginAndImport() async {
    setState(() { _loading = true; _error = null; });
    try {
      final steamId = await SteamOAuthService().signInWithSteam();
      final games = await SteamOAuthService().fetchOwnedGames(steamId);
      await SteamLibraryCache().saveGames(games);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход через Steam')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text('Ошибка: $_error', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _loginAndImport,
              child: const Text('Авторизоваться и импортировать'),
            ),
          ],
        ),
      ),
    );
  }
}
