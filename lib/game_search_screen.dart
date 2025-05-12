import 'package:flutter/material.dart';
import 'services/steamdb_service.dart';
import 'compatibility_details_by_game.dart';

class GameSearchScreen extends StatefulWidget {
  final String device;
  const GameSearchScreen({super.key, required this.device});
  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final _steamDb = SteamDbService();
  final _ctrl = TextEditingController();
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;
  String? _error;

  void _onChanged(String q) async {
    if (q.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _steamDb.searchGames(q);
      setState(() {
        _suggestions = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Игра на ${widget.device}')),
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Введите название игры',
            ),
            onChanged: _onChanged,
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text('Ошибка: $_error'),
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
                        builder: (_) =>
                            CompatibilityDetailsByGame(
                              device: widget.device,
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
