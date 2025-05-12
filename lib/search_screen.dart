import 'package:flutter/material.dart';
import 'services/steamdb_service.dart';
import 'compatibility_details_by_game.dart';

/// Экран поиска любой игры по Steam
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _steamDb = SteamDbService();
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;
  String? _error;

  void _onChanged(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _steamDb.searchGames(query);
      setState(() => _suggestions = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск игр')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Введите название игры',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onChanged,
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final item = _suggestions[i];
                  return ListTile(
                    title: Text(item['name']!),
                    subtitle: Text('SteamID: ${item['id']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompatibilityDetailsByGame(
                            steamId: item['id']!,
                            gameName: item['name']!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
