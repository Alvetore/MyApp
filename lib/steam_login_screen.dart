// lib/steam_login_screen.dart
import 'package:flutter/material.dart';
import 'services/steam_oauth_service.dart';
import 'services/steam_library_cache.dart';
import 'services/steam_models.dart';

/// Отдельный экран, если вы хотите просто сделать OAuth-вход
class SteamLoginScreen extends StatefulWidget {
  const SteamLoginScreen({Key? key}) : super(key: key);

  @override
  State<SteamLoginScreen> createState() => _SteamLoginScreenState();
}

class _SteamLoginScreenState extends State<SteamLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final steamId = await SteamOAuthService().signInWithSteam();
      final games = await SteamOAuthService().fetchOwnedGames(steamId);
      await SteamLibraryCache().saveGames(games);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Войти через Steam')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _doLogin,
              child: const Text('Steam Login'),
            ),
          ],
        ),
      ),
    );
  }
}
