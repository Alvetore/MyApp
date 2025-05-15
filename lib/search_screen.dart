import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'compatibility_details_by_game.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Экран поиска по библиотеке игр пользователя.
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, String>> _games = [];
  List<Map<String, String>> _filtered = [];
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('importedGames');
    if (saved != null && saved.isNotEmpty) {
      final list = List<dynamic>.from(jsonDecode(saved));
      _games = list.map((e) => Map<String, String>.from(e)).toList();
      _applyFilter();
    }
    setState(() {});
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    _filtered = _games
        .where((g) => g['name']!.toLowerCase().contains(q))
        .toList();
    _filtered.sort((a, b) {
      final cmp = a['name']!.compareTo(b['name']!);
      return _sortAsc ? cmp : -cmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.searchTitle)),
        body: Center(
          child: Text(loc.noGamesImported),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.searchTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Поиск по названию игры
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: loc.searchGame,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(_applyFilter),
            ),
            const SizedBox(height: 12),
            // Сортировка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.sorting),
                IconButton(
                  icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () => setState(() {
                    _sortAsc = !_sortAsc;
                    _applyFilter();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Список игр
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final game = _filtered[i];
                  final name = game['name']!;
                  final appid = game['appid']!;
                  final iconUrl =
                      'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appid/header.jpg';
                  return ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: iconUrl,
                      width: 50,
                      height: 50,
                      placeholder: (_, __) => const Icon(Icons.hourglass_empty),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                    title: Text(name),
                    subtitle: Text('${loc.steamId}: $appid'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompatibilityDetailsByGame(
                            steamId: appid,
                            gameName: name,
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
