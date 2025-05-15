import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImportProfileScreen extends StatefulWidget {
  const ImportProfileScreen({Key? key}) : super(key: key);

  @override
  State<ImportProfileScreen> createState() => _ImportProfileScreenState();
}

class _ImportProfileScreenState extends State<ImportProfileScreen> {
  final TextEditingController _profileCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int? _importedCount;
  int? _oldCount;

  static const _prefsKey = 'lastImportedSteamProfile';

  @override
  void initState() {
    super.initState();
    _loadLastProfile();
  }

  Future<void> _loadLastProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_prefsKey) ?? '';
    setState(() {
      _profileCtrl.text = last;
    });
  }

  Future<void> _import() async {
    setState(() { _loading = true; _error = null; });
    try {
      final input = _profileCtrl.text.trim();
      if (input.isEmpty) throw 'Введите vanity, URL или SteamID64';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, input);

      // Получаем старое количество игр (если есть)
      final oldGamesJson = prefs.getString('importedGames');
      _oldCount = oldGamesJson != null ? (jsonDecode(oldGamesJson) as List).length : 0;

      final url = input.contains('steamcommunity.com')
          ? input
          : (int.tryParse(input) != null
          ? 'https://steamcommunity.com/profiles/$input'
          : 'https://steamcommunity.com/id/$input');
      final profileUrl = Uri.parse(url.contains('?') ? '$url&xml=1' : '$url?xml=1');
      final pr = await http.get(profileUrl);
      if (pr.statusCode != 200) throw 'Профиль не найден';
      final docP = XmlDocument.parse(pr.body);
      final steamID = docP.findAllElements('steamID64').first.text;
      final gamesUrl = Uri.parse('https://steamcommunity.com/profiles/$steamID/games?xml=1');
      final gr = await http.get(gamesUrl);
      if (gr.statusCode != 200) throw 'Не удалось получить список игр';
      final docG = XmlDocument.parse(gr.body);
      final parsed = docG.findAllElements('game').map((g) => {
        'name': g.findElements('name').first.text,
        'appid': g.findElements('appID').first.text,
      }).toList();
      await prefs.setString('importedGames', jsonEncode(parsed));
      _importedCount = parsed.length;

      if (!mounted) return;

      // Показываем SnackBar с количеством импортированных игр
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Импорт завершён: $_importedCount игр (было $_oldCount)'),
        ),
      );
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
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _import,
                ),
              ),
              onSubmitted: (_) => _import(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _import,
              child: const Text('Импортировать'),
            ),
          ],
        ),
      ),
    );
  }
}
