import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Экран импорта библиотеки Steam по профилю пользователя
class ImportProfileScreen extends StatefulWidget {
  const ImportProfileScreen({Key? key}) : super(key: key);

  @override
  State<ImportProfileScreen> createState() => _ImportProfileScreenState();
}

class _ImportProfileScreenState extends State<ImportProfileScreen> {
  String? _steamNick;
  final TextEditingController _profileCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = AppLocalizations.of(context)!;
      final input = _profileCtrl.text.trim();
      if (input.isEmpty) throw loc.steam_input_hint;
      final url = input.contains('steamcommunity.com')
          ? input
          : (int.tryParse(input) != null
          ? 'https://steamcommunity.com/profiles/$input'
          : 'https://steamcommunity.com/id/$input');
      final profileUrl = Uri.parse(url.contains('?') ? '$url&xml=1' : '$url?xml=1');
      final pr = await http.get(profileUrl);
      if (pr.statusCode != 200) throw loc.steam_profile_not_found;
      final docP = XmlDocument.parse(pr.body);
      final steamID = docP.findAllElements('steamID64').first.text;
      final gamesUrl = Uri.parse('https://steamcommunity.com/profiles/$steamID/games?xml=1');
      final gr = await http.get(gamesUrl);
      if (gr.statusCode != 200) throw loc.steam_games_error;
      final docG = XmlDocument.parse(gr.body);
      final parsed = docG.findAllElements('game').map((g) => {
        'name': g.findElements('name').first.text,
        'appid': g.findElements('appID').first.text,
      }).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('importedGames', jsonEncode(parsed));
      await prefs.setString('lastImportProfile', input); // Запомнили последний профиль
      await prefs.setString('lastImportTime', DateTime.now().toIso8601String());
      await prefs.setString('importedSteamNick', _steamNick ?? '');
      if (!mounted) return;
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
  void initState() {
    super.initState();
    _loadLastProfile();
  }

  Future<void> _loadLastProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('lastImportProfile') ?? '';
    if (last.isNotEmpty) {
      _profileCtrl.text = last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.import_steam)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _profileCtrl,
              decoration: InputDecoration(
                labelText: loc.steam_input_label,
                hintText: loc.steam_input_hint,
                errorText: _error,
                suffixIcon: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _import,
                ),
              ),
              onSubmitted: (_) => _import(),
              enabled: !_loading,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _import,
              child: _loading
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(loc.importing),
                ],
              )
                  : Text(loc.import),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: _lastImportTime(),
              builder: (context, snap) {
                if (snap.data == null || snap.data!.isEmpty) return const SizedBox();
                return Text(
                  '${loc.last_import_time}: ${snap.data}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _lastImportTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('lastImportTime');
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    return MaterialLocalizations.of(context).formatFullDate(dt);
  }
}
